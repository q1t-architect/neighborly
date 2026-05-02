# AUTH-SETUP.md — Auth Configuration & Verification

> **Project:** Neighborly v2  
> **Author:** Kinetic  
> **Date:** 2026-05-02  
> **Status:** Phase 1.5 — Ready for Atlas implementation

---

## 1. Environment Variables

Create `.env.local` in the project root (never commit this file):

```bash
# Public — safe to expose in browser
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>

# Private — server-only, bypasses RLS
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

For Vercel: add all three in **Project Settings → Environment Variables**. Set for all environments (Production, Preview, Development).

---

## 2. Supabase Auth Configuration

In Supabase Dashboard → **Authentication → Settings**:

### Email Provider

| Setting | Value |
|---------|-------|
| Enable Email | ✅ ON |
| Confirm email | ✅ ON (`mailer_autoconfirm = false`) |
| Secure email change | ✅ ON |
| Minimum password length | `8` |
| Password strength check | ✅ ON |

### Site URL

```
https://neighborly.vercel.app
```

(Replace with actual production domain once confirmed.)

### Redirect URLs (Allowlist)

Add the following patterns to allow Vercel preview deployments:

```
https://neighborly.vercel.app/**
https://neighborly-*.vercel.app/**
http://localhost:3000/**
```

The `**` wildcard matches all paths, allowing `/auth/confirm` to work on any preview URL.

### Email Templates

Supabase Dashboard → **Authentication → Email Templates**

**Confirm signup** — update the confirmation URL to point to our route handler:

```
{{ .SiteURL }}/auth/confirm?code={{ .TokenHash }}&type=signup&next=/
```

**Reset password** — update to:

```
{{ .SiteURL }}/auth/confirm?code={{ .TokenHash }}&type=recovery
```

---

## 3. File Structure Produced

```
src/
├── lib/
│   └── supabase/
│       ├── types.ts          ← Database types (all tables, enums, RPCs)
│       ├── client.ts         ← Browser client (Client Components)
│       ├── server.ts         ← Server client (Server Components, Actions)
│       └── admin.ts          ← service_role client (server-only)
├── middleware.ts              ← Route protection
└── app/
    ├── login/
    │   ├── page.tsx          ← Server Component shell
    │   └── LoginForm.tsx     ← "use client" form
    ├── signup/
    │   ├── page.tsx          ← Server Component shell
    │   └── SignupForm.tsx    ← "use client" form + check-inbox state
    ├── forgot-password/
    │   ├── page.tsx          ← Server Component shell
    │   └── ForgotPasswordForm.tsx ← "use client" form + sent state
    └── auth/
        └── confirm/
            └── route.ts      ← PKCE code exchange Route Handler
```

---

## 4. Protected Routes

Middleware enforces:

| Route Pattern | Protection |
|--------------|-----------|
| `/profile` | Auth required |
| `/listing/new` | Auth required |
| `/listing/[id]/edit` | Auth required |
| `/messages` | Auth required |
| `/notifications` | Auth required |
| `/login` | Redirect to `/` if already logged in |
| `/signup` | Redirect to `/` if already logged in |
| `/forgot-password` | Redirect to `/` if already logged in |

`/auth/confirm` is intentionally **not** in either list — it must be accessible without a session (it creates the session).

---

## 5. Auth Flow Summary

### Signup

```
1. User fills /signup → SignupForm calls supabase.auth.signUp()
2. Supabase creates auth.users entry (email_confirmed = false)
3. Confirmation email sent → user sees "Check inbox" screen
4. User clicks email link → redirects to /auth/confirm?code=...&type=signup
5. Route handler: exchangeCodeForSession(code) → session cookie set
6. Check profiles.neighborhood: NULL → redirect /onboarding
7. User completes onboarding → redirect /
```

### Login

```
1. User fills /login → LoginForm calls supabase.auth.signInWithPassword()
2. On success: router.push(redirectTo) + router.refresh()
3. Middleware now sees valid session → allows access to protected routes
```

### Password Reset

```
1. User fills /forgot-password → resetPasswordForEmail()
   Always shows "sent" UI regardless of error (prevents email enumeration)
2. User clicks email link → /auth/confirm?code=...&type=recovery
3. Route handler: exchangeCodeForSession → redirect /auth/update-password
4. User enters new password → supabase.auth.updateUser({ password })
```

### Session Refresh

`@supabase/ssr` handles automatic token refresh via middleware. The `setAll` cookie handler in middleware ensures refreshed tokens are propagated back to the browser on every request.

---

## 6. Client Selection Guide

| Context | Import |
|---------|--------|
| Server Component | `import { createClient } from '@/lib/supabase/server'` |
| Server Action | `import { createClient } from '@/lib/supabase/server'` |
| Route Handler | `import { createClient } from '@/lib/supabase/server'` |
| Client Component | `import { createClient } from '@/lib/supabase/client'` |
| Admin operation | `import { createAdminClient } from '@/lib/supabase/admin'` |

**Never** use `admin.ts` in Client Components or pass the service role key to the browser.

---

## 7. Verification Checklist

After connecting a Supabase project:

### Environment
- [ ] `.env.local` created with all 3 vars
- [ ] Vercel env vars set for all environments

### Supabase Dashboard
- [ ] Email provider: ON, Confirm email: ON
- [ ] Minimum password length: 8
- [ ] Site URL set to production domain
- [ ] Redirect URLs allowlist includes production + Vercel previews + localhost
- [ ] Email templates updated to use `/auth/confirm?code={{ .TokenHash }}&type=...`

### Functional tests
- [ ] Sign up with a new email → receive confirmation email
- [ ] Click confirmation link → redirected to `/onboarding`
- [ ] Sign up with already-registered email → sees helpful error (not 500)
- [ ] Sign in with wrong password → sees "Invalid email or password"
- [ ] Sign in with unconfirmed email → sees "Please confirm your email"
- [ ] Sign in successfully → redirected to `/` or `?redirectTo` destination
- [ ] Request password reset → sees "sent" screen regardless of email existence
- [ ] Click reset link → redirected to `/auth/update-password`
- [ ] Access `/profile` without session → redirected to `/login?redirectTo=/profile`
- [ ] Access `/login` while logged in → redirected to `/`
- [ ] Sign out → session cleared, protected routes redirect to login

### Security
- [ ] `SUPABASE_SERVICE_ROLE_KEY` never appears in browser Network tab
- [ ] No Supabase errors in Vercel logs on first load
- [ ] Test with DevTools cookies cleared — auth state resets correctly

---

## 8. What's NOT included (next tasks)

| Feature | Owner |
|---------|-------|
| Onboarding page (`/onboarding`) | Atlas |
| Password update page (`/auth/update-password`) | Atlas |
| `AuthProvider` context (client-side session) | Atlas |
| Logout action | Atlas |
| Profile page auth (reads `currentUserId` from server) | Atlas |
| Social login (Google) — PRD P2, deferred | — |

---

*See SECURITY.md for RLS policies. See REALTIME.md for subscription patterns.*
