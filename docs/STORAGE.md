# STORAGE.md — Storage Buckets + Auth Flow Design

> **Project:** Neighborly v2  
> **Author:** Kinetic  
> **Date:** 2026-05-02  
> **Status:** Draft — Phase 1 Design  
> **Scope:** Supabase Storage configuration + Authentication flow

---

## Part 1: Storage Buckets

---

### Bucket: `avatars`

**Purpose:** User profile photos.

| Setting | Value |
|---------|-------|
| Visibility | Public (CDN-served, no auth required for GET) |
| Max file size | 2 MB (2,097,152 bytes) |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |
| CDN Cache | Yes (Supabase default: `Cache-Control: max-age=3600`) |

**Path convention:**

```
avatars/{user_id}/avatar.{ext}
```

Naming is deterministic: uploading a new avatar overwrites the previous one (upsert). No versioning needed.

**Storage RLS Policies:**

```sql
-- Public read: anyone can view avatars
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Authenticated upload: user can only write to their own folder
CREATE POLICY "avatars_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- User can update (upsert) their own avatar
CREATE POLICY "avatars_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- User can delete their own avatar
CREATE POLICY "avatars_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

**Upload pattern (client):**

```typescript
async function uploadAvatar(file: File, userId: string): Promise<string> {
  const ext = file.type.split('/')[1]; // jpeg | png | webp
  const path = `${userId}/avatar.${ext}`;

  const { error } = await supabase.storage
    .from('avatars')
    .upload(path, file, {
      upsert: true,
      contentType: file.type, // required for MIME validation
    });

  if (error) throw error;

  const { data: { publicUrl } } = supabase.storage
    .from('avatars')
    .getPublicUrl(path);

  // Update profile with new avatar URL
  await supabase
    .from('profiles')
    .update({ avatar_url: publicUrl })
    .eq('id', userId);

  return publicUrl;
}
```

**Client-side validation (before upload):**

```typescript
const MAX_AVATAR_SIZE = 2 * 1024 * 1024; // 2MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

function validateAvatarFile(file: File): string | null {
  if (!ALLOWED_TYPES.includes(file.type)) return 'Only JPEG, PNG, and WebP allowed';
  if (file.size > MAX_AVATAR_SIZE) return 'File must be under 2MB';
  return null; // valid
}
```

---

### Bucket: `listing-photos`

**Purpose:** Item listing photos. Up to 5 per listing.

| Setting | Value |
|---------|-------|
| Visibility | Public (CDN-served) |
| Max file size | 5 MB (5,242,880 bytes) |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |
| Max photos per listing | 5 (enforced at application layer) |
| CDN Cache | Yes |

**Path convention:**

```
listing-photos/{user_id}/{listing_id}/{index}.{ext}
```

`{index}` is 0–4, matching the `images[]` array position in the `listings` table. Using index makes deletion of specific photos deterministic.

**Architectural note — deferred upload:**

Listing photos can only be uploaded after the listing ID exists. The flow is:

1. User fills form, selects photos (stored as `File` objects client-side)
2. User submits → `createListing({ ...data, images: [] })` → returns `listing.id`
3. Upload each photo to `{userId}/{listing.id}/{index}.{ext}`
4. Collect public URLs → `updateListing({ id: listing.id, images: urls })`

This prevents orphaned files in storage (no temp-path + move pattern needed).

**Storage RLS Policies:**

```sql
-- Public read: anyone can view listing photos
CREATE POLICY "listing_photos_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'listing-photos');

-- Owner upload: user can only write to their own user_id folder
CREATE POLICY "listing_photos_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'listing-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Owner update (replace a photo)
CREATE POLICY "listing_photos_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'listing-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Owner delete
CREATE POLICY "listing_photos_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'listing-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

**Upload pattern (client):**

```typescript
type PhotoEntry =
  | { type: 'url'; url: string }       // existing photo (edit mode)
  | { type: 'file'; file: File; preview: string }; // new upload

async function uploadListingPhotos(
  entries: PhotoEntry[],
  userId: string,
  listingId: string
): Promise<string[]> {
  const urls: string[] = [];

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];

    if (entry.type === 'url') {
      urls.push(entry.url);
      continue;
    }

    const ext = entry.file.type.split('/')[1];
    const path = `${userId}/${listingId}/${i}.${ext}`;

    const { error } = await supabase.storage
      .from('listing-photos')
      .upload(path, entry.file, {
        upsert: true,
        contentType: entry.file.type,
      });

    if (!error) {
      const { data: { publicUrl } } = supabase.storage
        .from('listing-photos')
        .getPublicUrl(path);
      urls.push(publicUrl);
      URL.revokeObjectURL(entry.preview); // free memory
    }
  }

  return urls;
}
```

**Client-side validation:**

```typescript
const MAX_PHOTO_SIZE = 5 * 1024 * 1024; // 5MB
const MAX_PHOTOS = 5;

function validateListingPhotos(files: File[]): string | null {
  if (files.length > MAX_PHOTOS) return `Maximum ${MAX_PHOTOS} photos allowed`;
  for (const file of files) {
    if (!ALLOWED_TYPES.includes(file.type)) return `Only JPEG, PNG, WebP allowed`;
    if (file.size > MAX_PHOTO_SIZE) return `Each photo must be under 5MB`;
  }
  return null;
}
```

**Cleanup on listing delete:**

When a listing is deleted, photos must be cleaned up. Handled by a server-side function:

```sql
CREATE OR REPLACE FUNCTION cleanup_listing_photos()
RETURNS TRIGGER SECURITY DEFINER AS $$
BEGIN
  -- Enqueue storage deletion (handled by application layer via edge function)
  -- Direct storage deletion from SQL is not possible in Supabase
  -- Use a webhook or edge function triggered on listing deletion
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
```

In practice: call `supabase.storage.from('listing-photos').remove([...paths])` from the listing delete server action.

---

## Part 2: Auth Flow

---

### Flow 1: Signup

```
User fills email + password
        │
        ▼
supabase.auth.signUp({ email, password })
        │
        ├── Supabase creates auth.users entry (email_confirmed = false)
        ├── Confirmation email sent automatically
        │
        ▼
UI: "Check your email to confirm your account"
        │
        ▼
User clicks email link → email_confirmed = true
        │
        ▼
Database trigger fires: handle_new_user()
        │
        ├── INSERT INTO profiles (id, name, neighborhood)
        │   VALUES (user.id, email_prefix, NULL)
        │
        ▼
User redirected to app (session established)
        │
        ▼
Middleware checks: profile.neighborhood IS NULL?
        │
        ├── YES → redirect to /onboarding
        └── NO  → redirect to / (browse)
```

**`handle_new_user` trigger:**

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id, name, neighborhood)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    NULL -- populated during onboarding
  )
  ON CONFLICT (id) DO NOTHING; -- idempotent

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

**Onboarding steps (after email confirmation):**

1. Enter display name (pre-filled from email prefix)
2. Upload avatar (optional, skippable)
3. Select neighborhood (required — from predefined Madrid barrios list)

After step 3 → profile marked complete (`neighborhood IS NOT NULL`) → redirect to browse.

**Email confirmation requirement:**

```typescript
// On signUp response:
const { data, error } = await supabase.auth.signUp({ email, password });

if (data.user && !data.session) {
  // email_confirmed = false — session not yet issued
  // Show "Check your email" screen
}
if (data.session) {
  // email_confirmed = true (e.g., Supabase config: "Confirm email" = ON)
  // This case only occurs if "Confirm email" is disabled — should not happen
}
```

---

### Flow 2: Login

```
User enters email + password
        │
        ▼
supabase.auth.signInWithPassword({ email, password })
        │
        ├── ERROR: "Email not confirmed" → show "resend confirmation" CTA
        ├── ERROR: "Invalid credentials" → show error message
        │
        ▼ (success)
Session established (access_token + refresh_token in cookies)
        │
        ▼
Middleware: supabase.auth.getUser() validates session
        │
        ▼
Redirect to original destination or /
```

---

### Flow 3: Password Reset

```
User clicks "Forgot password?" → enters email
        │
        ▼
supabase.auth.resetPasswordForEmail(email, {
  redirectTo: `${origin}/auth/reset-password`
})
        │
        ▼
Email sent with magic link
        │
        ▼
User clicks link → redirected to /auth/reset-password
URL hash contains: #access_token=...&type=recovery
        │
        ▼
App detects recovery event:
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'PASSWORD_RECOVERY') {
    router.push('/auth/update-password');
  }
})
        │
        ▼
User enters new password
        │
        ▼
supabase.auth.updateUser({ password: newPassword })
        │
        ▼
Session refreshed → redirect to /
```

---

### Flow 4: Session Management (Middleware)

Every request passes through Next.js middleware for server-side session validation.

**Pattern: `middleware.ts`**

```typescript
import { createServerClient } from '@supabase/ssr';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookies) => {
          cookies.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  // Refresh session if expired — must be called before getUser()
  const { data: { user } } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;

  // Protected routes
  const protectedRoutes = ['/messages', '/profile', '/listing/new', '/notifications'];
  const isProtected = protectedRoutes.some((r) => pathname.startsWith(r));

  // Auth-only routes (redirect away if already logged in)
  const authRoutes = ['/auth/sign-in', '/auth/sign-up'];
  const isAuthRoute = authRoutes.some((r) => pathname.startsWith(r));

  if (!user && isProtected) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = '/auth/sign-in';
    redirectUrl.searchParams.set('redirectTo', pathname);
    return NextResponse.redirect(redirectUrl);
  }

  if (user && isAuthRoute) {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
```

**Why `getUser()` and not `getSession()`:**

`getSession()` reads from cookie without server-side validation — can be spoofed. `getUser()` validates the JWT with Supabase Auth server on every call. Use `getUser()` in middleware for security.

---

### Onboarding Completeness Check

A helper function used in middleware and server components:

```typescript
async function getProfileCompleteness(supabase: SupabaseClient, userId: string) {
  const { data } = await supabase
    .from('profiles')
    .select('name, neighborhood')
    .eq('id', userId)
    .single();

  return {
    hasName: !!data?.name,
    hasNeighborhood: !!data?.neighborhood,
    isComplete: !!(data?.name && data?.neighborhood),
  };
}

// In middleware, after auth check:
if (user && pathname !== '/onboarding') {
  const completeness = await getProfileCompleteness(supabase, user.id);
  if (!completeness.isComplete) {
    return NextResponse.redirect(new URL('/onboarding', request.url));
  }
}
```

---

## Security Summary

| Concern | Mitigation |
|---------|-----------|
| Unauthenticated storage upload | RLS: path[0] must match auth.uid() |
| MIME type bypass | Supabase bucket `allowed_mime_types` enforced server-side |
| Oversized uploads | Supabase bucket `file_size_limit` enforced server-side |
| Session spoofing in middleware | `getUser()` (server-validated) not `getSession()` (cookie-only) |
| Profile injection on signup | Trigger runs SECURITY DEFINER; no INSERT policy for users |
| Email confirmation bypass | Supabase "Confirm email" setting: ON; session only issued after confirmation |
| Orphaned storage files on listing delete | Server action deletes files explicitly before or after DB delete |
| Notification injection | No INSERT policy on notifications table; system-only via SECURITY DEFINER triggers |

---

*See SECURITY.md for RLS policies on database tables.*  
*See REALTIME.md for Supabase Realtime channel design.*
