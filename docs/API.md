# Neighborly v2 — API Contract

> **Version:** v2.0  
> **Date:** 2026-05-02  
> **Author:** Proof (QA / Schema Audit)  
> **Stack:** Supabase PostgreSQL RPC (PostgREST) — no custom backend  
> **Base URL:** `https://<project>.supabase.co/rest/v1/rpc/<function_name>`

---

## Conventions

All functions are invoked via **Supabase client** (TypeScript SDK or direct REST `POST /rpc/<name>`).

```typescript
const { data, error } = await supabase.rpc('function_name', { param: value })
```

### Auth
All RPC functions run as `SECURITY DEFINER`. The auth context is obtained via `auth.uid()` inside the function.

| Requirement | Meaning |
|-------------|---------|
| `public` | No auth token required |
| `authenticated` | Valid JWT required in `Authorization: Bearer <token>` header |
| `owner` | Authenticated user must be the owner of the relevant resource |
| `borrower` | Authenticated user must be the borrower of the relevant resource |
| `participant` | Authenticated user must be a participant of the relevant resource |

### Error format
Supabase RPC errors are raised via `RAISE EXCEPTION 'message'` and returned as:
```json
{ "code": "P0001", "message": "error message", "details": null }
```

### Timestamps
All timestamps are ISO 8601 UTC. Example: `"2026-05-02T14:30:00.000Z"`

---

## 1. `nearby_listings`

Fetch listings within a geo radius. Returns listings with owner data joined. Filtered by `status = 'available'`, `expires_at > NOW()`, soft-delete, and optionally by category. Blocked owners are excluded when authenticated.

**Auth:** `public`

### Input

| Parameter | Type | Required | Default | Constraints |
|-----------|------|----------|---------|-------------|
| `lat` | `float8` | ✅ | — | Latitude WGS84 |
| `lng` | `float8` | ✅ | — | Longitude WGS84 |
| `radius_km` | `float8` | ❌ | `1.0` | 0.1–50.0 |
| `category` | `text` | ❌ | `null` | null = all categories |
| `p_limit` | `int4` | ❌ | `50` | Max 200 |

### Output

Returns `SETOF record` (array of objects):

```typescript
type NearbyListing = {
  id: string              // UUID
  owner_id: string        // UUID
  title: string
  description: string | null
  category: string
  condition: 'excellent' | 'good' | 'fair' | null
  images: string[]        // array of Storage URLs
  neighborhood: string | null
  status: 'available'     // always 'available' from this function
  price_type: 'free' | 'symbolic'
  price_euro: number | null
  expires_at: string      // ISO timestamp
  distance_km: number     // rounded to 2 decimal places
  created_at: string
  // owner fields
  owner_name: string
  owner_avatar: string | null
  owner_rating: number    // 0.00 – 5.00
  owner_exchanges: number
  owner_verified: boolean
  owner_neighborhood: string | null
}
```

### RLS
No table-level RLS check needed — function filters within the query (`deleted_at IS NULL`, `status = 'available'`, `is_blocked` check).

### Example
```typescript
const { data, error } = await supabase.rpc('nearby_listings', {
  lat: 40.4168,
  lng: -3.7038,
  radius_km: 1.0,
  category: 'Tools',
  p_limit: 50
})
```

---

## 2. `get_listing_with_owner`

Fetch a single listing with owner profile. Respects soft-delete.

**Auth:** `public`

### Input

| Parameter | Type | Required |
|-----------|------|----------|
| `p_id` | `uuid` | ✅ |

### Output

Returns a single `record` (or empty if not found):

```typescript
type ListingWithOwner = {
  id: string
  owner_id: string
  title: string
  description: string | null
  category: string
  condition: 'excellent' | 'good' | 'fair' | null
  images: string[]
  location_x: number | null  // longitude (ST_X)
  location_y: number | null  // latitude (ST_Y)
  neighborhood: string | null
  status: ListingStatus
  price_type: 'free' | 'symbolic'
  price_euro: number | null
  expires_at: string
  created_at: string
  updated_at: string
  // owner
  owner_name: string
  owner_avatar: string | null
  owner_rating: number
  owner_exchanges: number
  owner_verified: boolean
  owner_neighborhood: string | null
  owner_bio: string | null
}
```

Returns empty array if listing not found or soft-deleted. Use `data?.[0]` to get the record.

### Example
```typescript
const { data, error } = await supabase.rpc('get_listing_with_owner', {
  p_id: '550e8400-e29b-41d4-a716-446655440000'
})
const listing = data?.[0] ?? null
if (!listing) notFound()
```

---

## 3. `create_reservation`

Create a borrow/reserve request. Atomically:
1. Validates listing is available and caller is not the owner
2. Checks no active reservation already exists for this borrower+listing
3. Inserts `reservation` with `status = 'pending'`
4. Updates `listing.status = 'reserved'`
5. Opens (or reuses) `conversation` between borrower ↔ owner
6. Creates `notification` for owner

**Auth:** `authenticated`

### Input

| Parameter | Type | Required | Constraints |
|-----------|------|----------|-------------|
| `p_listing_id` | `uuid` | ✅ | Must be available, not own listing |
| `p_mode` | `text` | ❌ | `'borrow'` (default) or `'reserve'` |
| `p_pickup_window_start` | `date` | ❌ | Suggested pickup date |
| `p_pickup_window_end` | `date` | ❌ | Must be ≥ start |

### Output

```typescript
type CreateReservationResult = {
  reservation_id: string   // UUID of new reservation
  conversation_id: string  // UUID of conversation (new or existing)
  status: 'pending'
}
```

### Errors

| Code | Message |
|------|---------|
| P0001 | `Authentication required` |
| P0001 | `Listing not found or not available` |
| P0001 | `Cannot borrow your own item` |
| P0001 | `Active reservation already exists for this item` |

### Example
```typescript
const { data, error } = await supabase.rpc('create_reservation', {
  p_listing_id: listingId,
  p_mode: 'borrow',
  p_pickup_window_start: '2026-05-10',
  p_pickup_window_end: '2026-05-12'
})
if (error) throw error
// data.reservation_id, data.conversation_id
```

---

## 4. `confirm_reservation`

Owner confirms a pending reservation. Generates pickup code server-side.

**Auth:** `owner` (of the reservation)

### Input

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `p_reservation_id` | `uuid` | ✅ | Must be in `pending` status |
| `p_due_date` | `date` | ❌ | Default: `CURRENT_DATE + 7 days` |

### Output

```typescript
type ConfirmReservationResult = {
  status: 'confirmed'
  pickup_code: string   // 'NLB-XXXX' format
  due_date: string      // ISO date
}
```

### Side effects
- `reservation.status` → `'confirmed'`
- `reservation.pickup_code` set (server-generated, unique)
- `reservation.confirmed_at` set to NOW()
- Notification inserted for borrower (type: `reservation_confirmed`)
- System message sent in conversation with pickup code

### Errors

| Code | Message |
|------|---------|
| P0001 | `Reservation not found or you are not the owner` |

### Example
```typescript
const { data, error } = await supabase.rpc('confirm_reservation', {
  p_reservation_id: reservationId,
  p_due_date: '2026-05-17'
})
// data.pickup_code === 'NLB-A7B3'
```

---

## 5. `decline_reservation`

Owner declines a pending reservation. Releases listing back to `available`.

**Auth:** `owner`

### Input

| Parameter | Type | Required |
|-----------|------|----------|
| `p_reservation_id` | `uuid` | ✅ |
| `p_reason` | `text` | ❌ |

### Output

```typescript
{ status: 'declined' }
```

### Side effects
- `reservation.status` → `'declined'`
- `listing.status` → `'available'`
- Notification for borrower (type: `reservation_declined`)

---

## 6. `pickup_verify`

Records pickup confirmation for one party. When both borrower and owner confirm, status advances to `active`.

**Auth:** `participant` (borrower or owner of the reservation)

### Input

| Parameter | Type | Required | Values |
|-----------|------|----------|--------|
| `p_reservation_id` | `uuid` | ✅ | Must be in `confirmed` status |
| `p_role` | `text` | ✅ | `'borrower'` or `'owner'` |

### Output

```typescript
type PickupVerifyResult = {
  status: 'confirmed' | 'active'  // 'active' when both have confirmed
}
```

### State machine

```
confirmed
  → borrower_pickup_at set (one party)  → still 'confirmed'
  → owner_pickup_at set (other party)   → status = 'active'
```

Both `borrower_pickup_at` AND `owner_pickup_at` must be set for `active` transition.

### Side effects (on full confirmation)
- `reservation.status` → `'active'`
- `listing.status` → `'active'`

### Errors

| Code | Message |
|------|---------|
| P0001 | `Reservation not found or not in confirmed state` |
| P0001 | `Not the borrower` / `Not the owner` |
| P0001 | `Invalid role: must be borrower or owner` |

---

## 7. `confirm_return`

Records return confirmation. Borrower marks returned, then owner confirms receipt → `completed`.

**Auth:** `participant`

### Input

| Parameter | Type | Required | Values |
|-----------|------|----------|--------|
| `p_reservation_id` | `uuid` | ✅ | Must be in `active` or `return_pending` |
| `p_role` | `text` | ✅ | `'borrower'` or `'owner'` |

### Output

```typescript
type ConfirmReturnResult = {
  status: 'return_pending' | 'completed'
}
```

### State machine

```
active
  → borrower calls (role='borrower')  → 'return_pending' + notify owner
  → owner calls (role='owner')        → 'completed' + listing available + review notifications
```

### Side effects (on completion)
- `reservation.status` → `'completed'`
- `listing.status` → `'available'`
- Review reminder notifications for both parties

---

## 8. `send_message`

Insert a message into a conversation and notify the other participant.

**Auth:** `authenticated` (must be conversation participant)

### Input

| Parameter | Type | Required | Constraints |
|-----------|------|----------|-------------|
| `p_conversation_id` | `uuid` | ✅ | Caller must be participant |
| `p_content` | `text` | ✅ | 1–4000 chars |

### Output

```typescript
{ message_id: string }  // UUID of new message
```

### Side effects
- `messages` row inserted
- `notifications` row inserted for other participant (type: `new_message`)

### Note
For real-time chat, the client should **also** subscribe to the `messages` channel with `conversation_id` filter. The `send_message` RPC ensures the notification is created even if the recipient is not online. Direct Supabase inserts on `messages` table are also acceptable for authenticated clients (RLS allows it), but won't create the notification — prefer the RPC.

### Errors

| Code | Message |
|------|---------|
| P0001 | `Authentication required` |
| P0001 | `Message content cannot be empty` |
| P0001 | `Conversation not found or access denied` |

---

## 9. `mark_notification_read`

Mark a single notification as read.

**Auth:** `authenticated` (owner of notification)

### Input

| Parameter | Type | Required |
|-----------|------|----------|
| `p_notification_id` | `uuid` | ✅ |

### Output

`void` (no return value — check for error)

### Behavior
Sets `read = TRUE`, `read_at = NOW()` only if `user_id = auth.uid()` and `read = FALSE`. Silently no-ops if already read or not owned.

---

## 10. `mark_all_notifications_read`

Mark all unread notifications as read for the current user.

**Auth:** `authenticated`

### Input
None

### Output

```typescript
number  // count of notifications marked read
```

---

## Direct Table Access (non-RPC)

Some operations use Supabase client directly (not RPC). All require auth tokens and respect RLS:

### Favorites

```typescript
// Add favorite
await supabase.from('favorites').insert({ user_id: uid, listing_id: lid })

// Remove favorite
await supabase.from('favorites').delete()
  .eq('user_id', uid).eq('listing_id', lid)

// Check if favorited
const { data } = await supabase.from('favorites')
  .select('id').eq('user_id', uid).eq('listing_id', lid).maybeSingle()
const isFav = !!data
```

### Blocks

```typescript
// Block user
await supabase.from('blocks').insert({ blocker_id: uid, blocked_id: targetId })

// Unblock
await supabase.from('blocks').delete()
  .eq('blocker_id', uid).eq('blocked_id', targetId)
```

### Reports

```typescript
await supabase.from('reports').insert({
  reporter_id: uid,
  target_type: 'listing',   // 'profile' | 'listing' | 'message'
  target_id: listingId,
  reason: 'spam',
  description: 'Optional description'
})
```

### Reviews

```typescript
// Auth: reviewer must be a participant of a completed reservation
await supabase.from('reviews').insert({
  reservation_id: reservationId,
  listing_id: listingId,
  reviewer_id: uid,
  reviewee_id: revieweeId,
  rating: 5,
  text: 'Great exchange!'
})
```

### Profile Update

```typescript
await supabase.from('profiles').update({
  name: 'Clara',
  bio: 'I love sustainable living.',
  neighborhood: 'Malasaña',
  avatar_url: newAvatarUrl
}).eq('id', uid)
```

### Listing CRUD

```typescript
// Create
const { data } = await supabase.from('listings').insert({
  owner_id: uid, title, description, category, condition,
  neighborhood, price_type, price_euro,
  location: `POINT(${lng} ${lat})`,  // WKT string — Supabase parses to GEOGRAPHY
  images: []
}).select('id').single()

// Soft-delete
await supabase.from('listings').update({
  deleted_at: new Date().toISOString(),
  status: 'archived'
}).eq('id', listingId)

// Pause / unpause
await supabase.from('listings').update({ status: 'paused' }).eq('id', listingId)
await supabase.from('listings').update({ status: 'available' }).eq('id', listingId)
```

---

## Realtime Subscriptions

### Chat messages (per conversation)

```typescript
const channel = supabase
  .channel(`chat:${conversationId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'messages',
    filter: `conversation_id=eq.${conversationId}`
  }, (payload) => {
    const msg = payload.new as Message
    setMessages(prev => [...prev, msg])
  })
  .subscribe()

// Cleanup
return () => supabase.removeChannel(channel)
```

### Notifications (per user)

```typescript
const channel = supabase
  .channel(`notifications:${userId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    incrementUnreadCount()
  })
  .subscribe()
```

**Important:** Always remove channels on component unmount to prevent memory leaks.

---

## RLS Policy Matrix

| Table | Operation | Condition |
|-------|-----------|-----------|
| profiles | SELECT | `deleted_at IS NULL` |
| profiles | UPDATE | `auth.uid() = id AND deleted_at IS NULL` |
| listings | SELECT | `deleted_at IS NULL` |
| listings | INSERT | `auth.uid() = owner_id` |
| listings | UPDATE | `auth.uid() = owner_id AND deleted_at IS NULL` |
| listings | DELETE | **denied** (use soft-delete) |
| reservations | SELECT | `auth.uid() IN (borrower_id, owner_id)` |
| reservations | INSERT | `auth.uid() = borrower_id` |
| reservations | UPDATE | `auth.uid() IN (borrower_id, owner_id)` |
| reviews | SELECT | public |
| reviews | INSERT | `auth.uid() = reviewer_id` |
| conversations | SELECT | `auth.uid() IN (participant_1, participant_2)` |
| conversations | INSERT | `auth.uid() IN (participant_1, participant_2)` |
| messages | SELECT | auth user is conversation participant |
| messages | INSERT | `auth.uid() = sender_id AND NOT is_system` + participant check |
| notifications | ALL | `auth.uid() = user_id` |
| favorites | ALL | `auth.uid() = user_id` |
| reports | INSERT | `auth.uid() = reporter_id` |
| reports | SELECT | `auth.uid() = reporter_id` |
| blocks | ALL | `auth.uid() = blocker_id` |

---

## Error Codes Reference

| Supabase Code | Meaning |
|---------------|---------|
| `PGRST116` | No rows found (`.single()` returned 0 rows) |
| `23505` | Unique constraint violation (e.g. duplicate favorite, duplicate review) |
| `23503` | FK constraint violation |
| `P0001` | Custom exception raised by RPC function |
| `42501` | RLS policy violation — insufficient permissions |

---

## TypeScript Types

```typescript
type ListingStatus = 'available' | 'reserved' | 'active' | 'paused' | 'archived' | 'given'
type PriceType     = 'free' | 'symbolic'
type ItemCondition = 'excellent' | 'good' | 'fair'
type ReservationStatus =
  | 'pending' | 'confirmed' | 'active'
  | 'return_pending' | 'completed'
  | 'declined' | 'cancelled'
type NotificationType =
  | 'reservation_request' | 'reservation_confirmed' | 'reservation_declined'
  | 'reservation_cancelled' | 'new_message' | 'pickup_reminder'
  | 'return_due' | 'review_reminder' | 'listing_expiring' | 'system'

// Supabase generated types should be used instead of manual types above.
// Run: supabase gen types typescript --project-id <id> > src/types/supabase.ts
```

**Recommendation:** Use Supabase CLI type generation:
```bash
supabase gen types typescript --project-id <project-id> > src/types/database.ts
```
This eliminates `as unknown as Type` casts throughout the codebase.
