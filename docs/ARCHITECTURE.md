# Neighborly v2 — Architecture Decision Records

> **Status:** Draft  
> **Date:** 2026-05-02  
> **Author:** Flux (Visual Coordinator / Architecture Review)  
> **Based on:** PRD v0.1, ROADMAP v0.1, v1 MVP post-mortem  
> **Language:** English

---

## Preface: Lessons from v1

The v1 MVP shipped but accumulated three structural problems that must not repeat:

| Problem | Root Cause | v2 Fix |
|---------|-----------|--------|
| Circular imports (`listings.server.ts` imported in client components) | No enforced module boundary | File-suffix convention + lint rule |
| Auth waterfall (loading flash, owner check delay) | `useAuth()` context resolved client-side only | Server passes `currentUserId` as prop; context is supplemental |
| Radius filter was silently broken for months | `distanceKm` always `0` (RPC never called), no test | Server always calls PostGIS RPC; filter tested against real values |

These aren't architecture astronautics — they are specific bugs that emerged from vague conventions. The decisions below establish clear rules, not clever abstractions.

---

## ADR-01: Tech Stack

### Decision

**Next.js 15 (App Router) + React 19 + TypeScript + Tailwind CSS + Framer Motion**

### Context

Neighborly needs:
- Server-rendered listing pages for SEO (map + card grid)
- Real-time messaging (chat must feel instant)
- Geographic queries (PostGIS)
- 3-month MVP timeline with a small team
- Mobile-first responsive UI

### Evaluation

| Framework | Verdict | Reason |
|-----------|---------|--------|
| **Next.js 15** | ✅ Chosen | App Router + Server Components eliminates the need for a separate BFF. `generateMetadata()` handles SEO. Vercel deploys in one command. The team already knows it. |
| Remix | ❌ Not chosen | Better for form-heavy apps with nested loaders. Next.js Server Components + Server Actions cover the same ground with broader ecosystem support. |
| Vue 3 / Nuxt | ❌ Not chosen | Excellent framework, wrong team context. TypeScript integration in Vue requires more ceremony. Ecosystem (auth adapters, Supabase SSR) is Next.js-first. |
| SvelteKit | ❌ Not chosen | Best-in-class DX but smallest ecosystem. Supabase SSR library is Next.js-first. Framer Motion doesn't support Svelte. Hire risk for future contributors. |
| Vite + SPA | ❌ Not chosen | No SSR = no SEO for listing pages. Map-pin landing pages need to be crawlable for organic discovery. |

### TypeScript

Strict mode (`"strict": true`). No `any` casts except as escape hatches explicitly annotated with `// eslint-disable-next-line @typescript-eslint/no-explicit-any` + reason comment.

### Tailwind CSS

Utility-first. No CSS-in-JS (runtime overhead on every render). Tailwind v3 with `tailwind-merge` for conditional class composition. No separate component library — design system lives in Figma → implemented directly.

### Framer Motion

For page transitions and micro-interactions only. Not used for layout shifts or data loading (those use CSS + Tailwind skeleton classes). Bundle impact: ~40KB gzipped — acceptable.

---

## ADR-02: State Management

### Decision

**Three-tier model: Server Components (primary) → React Context (auth only) → Local useState (UI)**  
No Zustand, no Redux.

### Context

The App Router has fundamentally changed state management requirements. Most state in a traditional SPA is server data cached client-side. Server Components eliminate that category.

### Evaluation

| Tool | Verdict | Reason |
|------|---------|--------|
| **Server Components** | ✅ Primary | Data fetched once on the server, rendered, sent as HTML. No client hydration, no cache management, no loading states for initial render. |
| **React Context** | ✅ Auth only | Auth state is truly global and must be accessible without prop-drilling everywhere. Acceptable for a single slow-changing value (`user`, `profile`). |
| **useState** | ✅ UI only | Filter state, modal open/close, form fields — ephemeral, component-local. |
| Zustand | ❌ Not chosen | Excellent library. Not needed. Server Components handle server data. Context handles auth. Adding Zustand for client UI state is an over-engineering. Revisit when: (a) multiple unrelated client components need shared state, or (b) performance profiling shows Context re-renders causing measurable jank. |
| Redux Toolkit | ❌ Not chosen | Too much boilerplate for an MVP. Designed for complex global state that Neighborly doesn't yet have. Redux + Server Components is an awkward pairing — you'd need to hydrate the store server-side and the ergonomics are poor. |
| Jotai / Recoil | ❌ Not chosen | Atomic state managers are powerful for fine-grained subscriptions. Overkill. |

### Rules by Feature

| Feature | State Location | Rationale |
|---------|---------------|-----------|
| Listing data | Server Component prop | Fetched once, static per request |
| Auth (user, profile) | React Context (`AuthProvider`) | Globally needed, changes once per session |
| Chat messages | Supabase Realtime → local `useState` | Realtime subscription updates local array |
| Filter bar state | `useState` in parent client component | Ephemeral, single-page scope |
| Notification badge | Custom hook `useUnreadCount()` | Encapsulates subscription + count, reusable |
| Modal open/close | `useState` local to parent | No sharing needed |
| Form fields | `useState` or uncontrolled | Prefer uncontrolled with ref for perf |

### AuthProvider Rules

- Bootstrap: call `supabase.auth.getUser()` on mount (not `getSession()` — tokens can be forged)
- Subscribe: `onAuthStateChange` for tab-lifetime updates
- **Do not** gate initial page render on `loading === true`. Server already validated session in middleware. Client context is supplemental.
- Server Components that need `user.id` call `supabase.auth.getUser()` directly (server client). They pass `currentUserId` as a prop to avoid auth waterfall in Client Components.

---

## ADR-03: Caching Strategy

### Decision

**ISR for public listing pages + SWR for user-specific data + Supabase tag-based invalidation**

### Context

v1 had zero caching. Every request was a fresh Supabase round-trip. At 1,000 MAU this is fine. At 10,000 MAU the homepage (most popular page) would hammer the DB unnecessarily.

### Strategy by Data Type

#### 1. Homepage listing grid — Next.js `unstable_cache` (ISR-equivalent)

```
Data: getNearbyListings() — public, changes when listings are created/updated/deleted
TTL: 60 seconds
Invalidation: revalidateTag("listings") on create, update, delete, status change
```

The homepage shows publicly available listings. A 60-second stale window is imperceptible to users and eliminates repeated DB hits during traffic spikes.

#### 2. Individual listing page — Next.js `generateStaticParams` + ISR

```
Data: getListing(id) — public, changes when listing is edited or status changes
Strategy: On-demand ISR via revalidatePath("/listing/[id]")
Invalidation: Server Action triggers revalidatePath on edit/delete
```

Listing detail pages are good ISR candidates — they're fetched as landing pages from external links and need to be crawlable/fast.

#### 3. User profile page — No ISR (personal + auth-gated logic)

```
Data: profile + own listings — semi-public but contains personalization
Strategy: Fresh fetch per request (no cache)
Rationale: Profile pages aren't SEO-critical. TTI is acceptable with Server Components.
```

#### 4. Chat messages — No cache (Supabase Realtime)

```
Data: messages — must be fresh, sub-second
Strategy: Realtime subscription. No caching. SWR initial fetch for conversation list.
```

#### 5. Notification count badge — SWR + Realtime

```
Data: unread count — per-user, changes frequently
Strategy: Initial fetch via getUnreadCount(), then Supabase Realtime subscription for live updates
TTL: Not applicable — subscription-driven
```

#### 6. User's own listings (profile edit view) — SWR

```
Data: user's active listings — changes after create/edit/delete
Strategy: SWR with revalidation on focus
```

### Cache Invalidation Rules

All invalidations happen in **Server Actions** (not client-side):

```
create listing  → revalidateTag("listings")
edit listing    → revalidateTag("listings") + revalidatePath("/listing/[id]")
delete listing  → revalidateTag("listings") + revalidatePath("/listing/[id]")
status change   → revalidatePath("/listing/[id]")
```

### What We Do NOT Cache

- Auth session (handled by Supabase + @supabase/ssr, cookies)
- Reservation state (must be live — stale reservation state is a trust failure)
- Review submission (must be immediate)

---

## ADR-04: Component Architecture

### Decision

**Server Components by default. Client Components at the leaf edge only.**

### The Boundary Rule

```
Server Component   →   Client Component
(page.tsx, layout)     (*Client.tsx, interactivity)

Server: data fetch, auth check, passes props
Client: event handlers, useState, useEffect, animations, realtime
```

### File Naming Convention (enforced)

| Suffix | Rule |
|--------|------|
| `page.tsx` | Always Server Component unless `"use client"` at top |
| `*Client.tsx` | Always Client Component (`"use client"` at top) |
| `*Server.ts` / `*Server.tsx` | Server-only. Never imported from Client Components |
| `*.client.ts` | Client-only mutation helpers. Never imported in Server Components |
| `lib/supabase/server.ts` | Server only |
| `lib/supabase/client.ts` | Client only |

**Lint rule to enforce this:** ESLint `no-restricted-imports` prevents importing `*.server.ts` from `*.client.tsx` and vice versa. This prevents the v1 circular import problem.

### Props Pattern

Server Components pass data down to Client Components as props. Client Components do NOT re-fetch data that was already fetched server-side.

```tsx
// ✅ Correct
// page.tsx (Server)
const listing = await getListing(id);
const { data: { user } } = await supabase.auth.getUser();
return <ListingDetailClient listing={listing} currentUserId={user?.id} />;

// ❌ Wrong  
// ListingDetailClient.tsx (Client)
const { data: listing } = useSWR(`/listing/${id}`, fetcher); // redundant fetch
```

### When to Use Client Components

Use `"use client"` when the component needs:
- `useState` / `useReducer`
- `useEffect`
- Browser APIs (`navigator`, `window`, `document`)
- Event handlers (onClick, onChange, onSubmit)
- Framer Motion animations
- Supabase Realtime subscriptions
- Maps (Mapbox GL requires browser)

**Never** use `"use client"` just because you want to. Every Client Component adds to the JS bundle.

### Colocation Rule

Client Components live next to their Server Component parents:

```
src/app/listing/[id]/
  page.tsx                    ← Server Component (fetch, auth)
  ListingDetailClient.tsx     ← Client Component (UI, interactions)
```

Not in a global `/components` folder unless genuinely shared across 3+ pages.

### Shared Components (`/components`)

Only components that are:
1. Used on 3+ distinct pages
2. Purely presentational (no data fetch)
3. Either pure Server Components or clearly marked Client Components

Examples: `ListingCard`, `Avatar`, `FilterBar`, `InteractiveMap`, `AppShell`.

---

## ADR-05: Data Fetching

### Decision

**Reads: Server Components + `lib/listings.server.ts`  
Writes: Server Actions  
Realtime: Supabase subscriptions in Client Components**

No Route Handlers for standard CRUD. No direct Supabase calls from Client Components for writes (exception: chat messages for latency).

### Evaluation

| Pattern | Verdict | Use Case |
|---------|---------|----------|
| **Server Components** | ✅ Primary reads | Page data, listing details, profile data |
| **Server Actions** | ✅ All writes | Create/update/delete listing, submit review, send borrow request |
| **Route Handlers** (`/api/`)| ⚠️ Limited | Webhooks (Stripe, email), external service callbacks, sitemap.xml |
| **Direct client Supabase** | ⚠️ Chat messages only | Real-time message sends for <500ms perceived latency |

### The Write Pattern (Server Actions)

All mutations go through Server Actions. This gives us:
- Server-side validation (Zod) before hitting the DB
- Automatic CSRF protection (Next.js Server Action mechanism)
- `revalidateTag` / `revalidatePath` in the same call
- No API endpoint to maintain

```
User submits form
  → Server Action called
    → Zod validation
    → supabase.from(...).insert(...)
    → revalidateTag / revalidatePath
    → return { success: true } or { error: "..." }
  → Client shows toast based on result
```

### The Read Pattern (Server Components)

```
Request arrives
  → middleware validates session (updateSession)
  → page.tsx (Server Component)
    → createClient() [server]
    → getListing(id) [listings.server.ts]
    → supabase.auth.getUser() if ownership check needed
    → render <Client listing={listing} currentUserId={user?.id} />
```

### Realtime Pattern (Client Components)

Used only for chat and notification count. Never for listing data (overkill for a borrows app).

```
Client Component mounts
  → initial data fetch (SWR or prop from server)
  → subscribe to Supabase channel
  → on event: update local state
  → on unmount: unsubscribe (cleanup in useEffect return)
```

**Subscription naming:** Always use specific channel names with user context to avoid cross-user bleed:
```ts
supabase.channel(`messages:${conversationId}`)
supabase.channel(`notifications:${userId}`)
```

### `lib/` Module Map

```
lib/
  supabase/
    server.ts     ← createServerClient (Server Components, Server Actions)
    client.ts     ← createBrowserClient (Client Components)
    middleware.ts ← updateSession (middleware.ts only)

  listings.server.ts  ← getListing, getNearbyListings, getListingsByOwner
  listings.client.ts  ← (legacy — migrate to Server Actions)

  actions/
    listings.ts   ← createListing, updateListing, deleteListing (Server Actions)
    reservations.ts ← createReservation, confirmReservation, cancelReservation
    reviews.ts    ← createReview
    profile.ts    ← updateProfile, uploadAvatar

  hooks/
    useUnreadCount.ts  ← Realtime notification count
    useMessages.ts     ← Realtime chat messages for a conversation
```

### Validation

All Server Actions validate input with **Zod** before touching the DB. Client-side validation with the same Zod schema for instant feedback (schema shared between client and server).

```ts
// Shared schema (no server imports, safe to import from client)
// lib/schemas/listing.ts
export const CreateListingSchema = z.object({
  title: z.string().min(3).max(100),
  category: z.enum(CATEGORIES),
  ...
});
```

---

## ADR-06: Database & Supabase Patterns

### PostGIS Queries

Always use `nearby_listings()` RPC for homepage and proximity queries — never a plain `SELECT` on the listings table when distance matters. The GIST index exists on `listings.location` and is only used by the RPC. Plain queries ignore it.

### The Two-Step Fetch Pattern

The `nearby_listings()` RPC doesn't return owner data (JOIN not in RPC). The correct pattern:

```
1. RPC → listing IDs + distance_km (uses PostGIS index)
2. FROM listings JOIN profiles → full rows for those IDs (uses primary key)
Merge: distance_km injected into full rows, preserve distance ordering
```

This gives map-renderable `location.x/y` + filterable `distance_km` + owner data in 2 queries.

### Pagination

**All list queries have explicit `LIMIT`.** No exceptions.

| Query | Limit | Cursor Strategy |
|-------|-------|----------------|
| `getNearbyListings()` | 50 | Future: cursor by `distance_km` |
| `getListingsByOwner()` | 20 | Future: cursor by `created_at` |
| `getMessages()` | 50 | Cursor by `created_at` DESC |
| `getNotifications()` | 30 | Cursor by `created_at` DESC |

### RLS is the Security Layer

Server Actions don't need manual `owner_id === user.id` checks for reads — RLS enforces this. Server Actions DO validate ownership for writes (belt-and-suspenders: Zod validates shape, Server Action verifies `auth.uid()` matches, RLS is the final gate).

---

## Summary Table

| Decision | Choice | Don't Use |
|----------|--------|-----------|
| Framework | Next.js 15 App Router | Remix, Vite SPA |
| Language | TypeScript strict | JS, `any` casts |
| Styling | Tailwind CSS | CSS-in-JS, Styled Components |
| State: server data | Server Components | SWR/React Query for initial load |
| State: auth | React Context (AuthProvider) | Zustand, Redux |
| State: UI | local useState | Global state stores |
| Writes | Server Actions + Zod | Client-side fetch, Route Handlers |
| Realtime | Supabase subscriptions in hooks | Polling |
| Caching | `unstable_cache` + ISR | No cache (v1 mistake) |
| Geo queries | `nearby_listings()` RPC | Plain SELECT without PostGIS |
| Pagination | Explicit LIMIT on all queries | Unbounded queries |
| Module boundary | File suffix convention + ESLint | Ad-hoc imports across boundaries |

---

*This document governs architectural decisions for Neighborly v2. Deviations require team discussion and an update to this file — not silent one-offs.*
