# Neighborly v2 — Product Requirements Document v0.1

> **Status:** Draft — pending review by Atlas + Тимур  
> **Date:** 2026-05-02  
> **Author:** Spark (Product Lead)  
> **Based on:** Phase 0 Product Workshop  
> **Language:** English

---

## 1. Document Info

| Field | Value |
|-------|-------|
| **Product Name** | Neighborly |
| **Version** | 2.0 (from-scratch rebuild) |
| **Document Version** | 0.1-draft |
| **Target Launch** | MVP — Month 3 (September 2026) |
| **Geography** | Madrid, Spain (MVP) |
| **Platform** | Web-first (PWA), mobile responsive |
| **Language** | English + Español |

---

## 2. Product Overview

### 2.1 Elevator Pitch

Neighborly is a trust-first hyperlocal platform where neighbors borrow, lend, and give away everyday items within walking distance. No money changes hands for items — just a symbolic platform fee per exchange and a community-built reputation system.

### 2.2 Vision Statement

"Every neighborhood has everything its residents need — they just don't know it yet."

### 2.3 Mission Statement

Make borrowing from a neighbor as easy as buying online. Build trust at the speed of a handshake. Reduce waste, one drill at a time.

### 2.4 Key Differentiators

1. **Trust-first by design** — Not a marketplace with trust bolted on. Trust is the product.
2. **Borrowing, not buying** — Purpose-built for temporary use, not transactions.
3. **Hyperlocal density** — 1km radius default. Your neighbor, not your city.
4. **Reputation at neighborhood scale** — Reviews + exchanges = local social capital.

---

## 3. Target Users

### 3.1 Primary: Clara (The Conscious Urbanite)

- Age 28–38, urban professional
- Lives in Madrid centro/barrio (rented apartment)
- Values: sustainability, minimalism, community
- Tech-savvy, uses Wallapop/Vinted/Too Good To Go
- Pain point: Buys items she uses once, then stores forever
- Goal: Access without ownership

### 3.2 Secondary: Miguel (The Practical Father)

- Age 35–50, family with kids
- Lives in family-oriented barrio (Salamanca, Retiro)
- Values: frugality, practicality, reliability
- Uses Facebook Marketplace, Nextdoor
- Pain point: Kids outgrow gear fast. Garage full of perfectly good stuff.
- Goal: Clear clutter while helping another family

### 3.3 Tertiary: Sofia (The Newcomer)

- Age 22–30, student / digital nomad / expat
- Short-term Madrid resident (6–24 months)
- Values: connection, low commitment, exploration
- Pain point: Needs items for temporary stay, won't invest in buying
- Goal: Low-stakes way to meet neighbors and access what she needs

---

## 4. Functional Requirements

### 4.1 Authentication & Onboarding

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| AUTH-01 | Email + password signup | P0 | With email verification |
| AUTH-02 | Login with email/password | P0 | |
| AUTH-03 | Password reset flow | P0 | |
| AUTH-04 | Profile creation on first login | P0 | Name, photo, neighborhood selection |
| AUTH-05 | Neighborhood selection from predefined list | P0 | Madrid barrios only for MVP |
| AUTH-06 | Onboarding: "Complete profile → Browse → Post first item" | P1 | 3-step guided flow |
| AUTH-07 | Social login (Google) | P2 | Deferred — email-first for MVP |

### 4.2 User Profile

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| PROF-01 | View profile (name, photo, neighborhood, bio) | P0 | Public profile |
| PROF-02 | Edit own profile | P0 | |
| PROF-03 | Upload avatar photo | P0 | Max 2MB, JPEG/PNG/WebP |
| PROF-04 | Display trust score (rating + exchanges) | P0 | Calculated from reviews |
| PROF-05 | Display "Verified" badge | P1 | Manual for MVP, automated future |
| PROF-06 | View user's listings on profile | P0 | |
| PROF-07 | View user's reviews on profile | P0 | |
| PROF-08 | Report / block user | P1 | |

### 4.3 Listings (Inventory)

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| LIST-01 | Create listing with title, description, category | P0 | |
| LIST-02 | Upload up to 5 photos per listing | P0 | Max 5MB each |
| LIST-03 | Select category from predefined list | P0 | Tools, Sports, Outdoors, Home, Kids, Electronics |
| LIST-04 | Set location (map pin or neighborhood) | P0 | Stored as PostGIS POINT |
| LIST-05 | Set price type: "Free" or "Symbolic" | P0 | Symbolic = €0.05–€0.50 fee |
| LIST-06 | Set item condition (excellent/good/fair) | P1 | |
| LIST-07 | Edit own listing | P0 | |
| LIST-08 | Delete own listing | P0 | |
| LIST-09 | Pause / unpause listing | P1 | Temporary unavailability |
| LIST-10 | Mark listing as "given away" (archive) | P1 | Post-borrow, for history |
| LIST-11 | Max 5 active listings for free users | P2 | Subscription removes limit |
| LIST-12 | Listing expiry (auto-archive after 30 days inactive) | P2 | With reminder to renew |

### 4.4 Discovery & Browse

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| DISC-01 | Map view with item pins | P0 | Default view, Mapbox GL |
| DISC-02 | List view with cards | P0 | Toggle map/list |
| DISC-03 | Filter by category | P0 | |
| DISC-04 | Filter by radius (0.5km / 1km / 2km / 3km) | P0 | Default 1km |
| DISC-05 | Filter by availability (available / reserved / all) | P1 | |
| DISC-06 | Filter by price type (free / symbolic / all) | P1 | |
| DISC-07 | Sort by distance (nearest first) | P0 | Default |
| DISC-08 | Sort by newest | P1 | |
| DISC-09 | Sort by owner rating | P2 | |
| DISC-10 | Text search (title, description, neighborhood) | P1 | Server-side search |
| DISC-11 | Empty state with CTA when no results | P1 | "Be the first to post in [neighborhood]" |

### 4.5 Listing Detail

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| DET-01 | Photo gallery (swipe/click through) | P0 | |
| DET-02 | Title, description, category, condition | P0 | |
| DET-03 | Owner card (name, photo, rating, exchanges, verified) | P0 | Link to profile |
| DET-04 | Location (neighborhood + map preview) | P0 | |
| DET-05 | Price type + symbolic fee display | P0 | |
| DET-06 | "Request to borrow" button | P0 | Disabled if reserved or own listing |
| DET-07 | "Message owner" button | P0 | Opens chat |
| DET-08 | "Add to favorites" button | P1 | |
| DET-09 | "Report listing" button | P1 | |
| DET-10 | "Share listing" (copy link) | P2 | |

### 4.6 Borrow / Reservation Flow

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| BOR-01 | Borrower sends request with proposed dates | P0 | 3-day pickup window suggested |
| BOR-02 | Owner receives notification + in-app alert | P0 | |
| BOR-03 | Owner can confirm or decline with message | P0 | |
| BOR-04 | Borrower receives confirmation notification | P0 | |
| BOR-05 | Both parties see pickup code upon confirmation | P0 | Format: NLB-XXXX |
| BOR-06 | Chat opens between borrower and owner | P0 | For coordination |
| BOR-07 | Listing status changes to "reserved" | P0 | |
| BOR-08 | Due date is set (default: 7 days from pickup) | P1 | Adjustable by owner |
| BOR-09 | Borrower can cancel before pickup | P1 | |
| BOR-10 | Owner can cancel before pickup | P1 | |
| BOR-11 | Overdue reminder (1 day before due) | P1 | Push + email |

### 4.7 Chat / Messaging

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| CHAT-01 | Real-time messaging between borrower and owner | P0 | Supabase Realtime |
| CHAT-02 | Message history persists | P0 | |
| CHAT-03 | Unread message counter | P0 | In header + on conversation |
| CHAT-04 | Conversation list (inbox) | P0 | Sorted by last message |
| CHAT-05 | System messages in chat ("Request confirmed", "Pickup code: XYZ") | P1 | |
| CHAT-06 | Block user from messaging | P2 | |

### 4.8 Pickup & Return

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| PICK-01 | Borrower marks "picked up" in app | P0 | At handoff, after showing code |
| PICK-02 | Owner marks "handed over" in app | P0 | Confirms pickup code match |
| PICK-03 | Pickup code verification (both enter) | P0 | Prevents fraud |
| PICK-04 | Borrower marks "returned" | P0 | |
| PICK-05 | Owner marks "received back" | P0 | |
| PICK-06 | Listing returns to "available" after return | P0 | Or auto-archived if owner chooses |
| PICK-07 | Optional: condition check on return | P1 | "Same condition? Yes / Issue" |
| PICK-08 | Late return flag if past due date | P1 | Impacts trust score |

### 4.9 Reviews & Trust

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| REV-01 | Both parties can leave review after confirmed return | P0 | |
| REV-02 | Rating: 1–5 stars | P0 | |
| REV-03 | Optional text review (max 500 chars) | P0 | |
| REV-04 | Reviews displayed on profile | P0 | |
| REV-05 | Reviews feed into trust score | P0 | Avg rating + exchange count |
| REV-06 | Cannot review same exchange twice | P0 | UNIQUE constraint |
| REV-07 | Review reminder notification (24h after return) | P1 | |
| REV-08 | Owner can respond to review | P2 | |

### 4.10 Notifications

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| NOT-01 | In-app notification center | P0 | |
| NOT-02 | Real-time notification badge | P0 | Header icon |
| NOT-03 | New borrow request notification | P0 | |
| NOT-04 | Request confirmed/declined notification | P0 | |
| NOT-05 | New message notification | P0 | |
| NOT-06 | Due date reminder | P1 | |
| NOT-07 | Review reminder | P1 | |
| NOT-08 | Email notifications (digest style) | P1 | Daily digest if unread |
| NOT-09 | Push notifications (browser) | P2 | Deferred |

### 4.11 Payments (Symbolic Fee)

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| PAY-01 | Wallet system (user tops up min €5) | P2 | Stripe integration |
| PAY-02 | Auto-debit symbolic fee per completed exchange | P2 | €0.05 for free items, €0.50 for symbolic |
| PAY-03 | "Neighbor" subscription (€2.99/mo) | P2 | Unlimited listings, verified badge, priority |
| PAY-04 | Fee displayed transparently before confirmation | P2 | |
| PAY-05 | Payment history | P2 | |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| Metric | Target |
|--------|--------|
| Time to Interactive (TTI) | < 2s on 4G |
| First Contentful Paint (FCP) | < 1s |
| Map load time | < 3s |
| Chat message delivery | < 500ms (realtime) |
| Page transition (client-side) | < 200ms |

### 5.2 Accessibility

- WCAG 2.1 AA compliance
- Keyboard navigation for all flows
- Screen reader support for listings, chat, forms
- Color contrast ratios ≥ 4.5:1
- Focus management in modals

### 5.3 Security

- Row Level Security (RLS) on all database tables
- Input sanitization on all text fields
- File upload validation (MIME type, size)
- Rate limiting on auth endpoints
- No sensitive data in URL params

### 5.4 Scalability (MVP assumptions)

- 1,000 concurrent users
- 10,000 listings
- 1,000 messages/day
- Supabase free tier sufficient for 6 months

---

## 6. User Stories

### Story 1: Clara needs a drill

> As a user who needs a drill for one DIY project,  
> I want to find someone within 1km who has a drill available,  
> So that I can borrow it for the weekend instead of buying one.

**Acceptance criteria:**
- [ ] I can open the app and see a map with item pins near me
- [ ] I can filter by "Tools" category
- [ ] I can tap a drill listing and see owner profile with 4.5★ rating
- [ ] I can tap "Request to borrow" and propose Saturday pickup
- [ ] Owner confirms within 2 hours
- [ ] I receive a pickup code (NLB-A7B3)
- [ ] We meet at the café on the corner. I show the code. I get the drill.
- [ ] I return it Sunday evening. Owner confirms. I leave a 5★ review.

### Story 2: Miguel clears his garage

> As a father whose kids have outgrown their bike,  
> I want to give it away to a neighbor who needs it,  
> So that I free up space and help another family.

**Acceptance criteria:**
- [ ] I tap "Post item" and upload 3 photos of the bike
- [ ] I select category "Kids", neighborhood "Retiro", price "Free"
- [ ] The listing appears on the map within seconds
- [ ] Within a day, I get a borrow request from a mom in my barrio
- [ ] I confirm and we arrange pickup at the park
- [ ] I hand over the bike, she shows the code, I tap "handed over"
- [ ] I receive a thank-you review. My exchange count goes to 12.

### Story 3: Sofia moves to Madrid

> As a newcomer who needs a ladder for hanging curtains,  > I want to borrow one without buying,  > So that I can settle in and maybe meet a neighbor.

**Acceptance criteria:**
- [ ] I sign up, select "Chamberí" as my neighborhood
- [ ] I see 3 ladders available within 1km
- [ ] I pick one from a user with 8 exchanges and 4.8★
- [ ] I message: "Hi! Just moved here. Need a ladder for 2 hours."
- [ ] Owner responds: "Sure! Come by tomorrow at 6."
- [ ] I pick it up, hang curtains, return it same evening
- [ ] We both leave reviews. I now have my first exchange.

---

## 7. Data Model (High-Level)

### 7.1 Core Entities

```
users (Supabase Auth)
  └── profiles
        └── listings
        └── reviews (as reviewee)
        └── reviews (as reviewer)
        └── reservations (as borrower)
        └── reservations (as owner)
        └── conversations (as participant)
              └── messages
        └── notifications
```

### 7.2 Key Fields per Entity

**profiles:** id, name, avatar_url, neighborhood, bio, rating, exchanges, verified, created_at

**listings:** id, owner_id, title, description, category, condition, images[], location (PostGIS POINT), neighborhood, status (available/reserved/given/archived), price_type, price_euro, created_at, updated_at

**reservations:** id, listing_id, borrower_id, owner_id, status (pending/confirmed/completed/cancelled), mode (borrow/reserve), pickup_code, due_date, created_at, updated_at

**reviews:** id, listing_id, reviewer_id, reviewee_id, rating (1-5), text, created_at

**conversations:** id, participant_ids[], created_at

**messages:** id, conversation_id, sender_id, content, created_at

**notifications:** id, user_id, type, title, body, read, created_at

---

## 8. Open Questions

| # | Question | Owner | Due Date |
|---|----------|-------|----------|
| 1 | Do we need phone number verification for MVP, or is email sufficient? | Atlas / Тимур | Week 1 |
| 2 | Should symbolic fee be charged to borrower, owner, or split? | Тимур | Week 1 |
| 3 | What's the exact Madrid neighborhood taxonomy? | Bounds | Week 1 |
| 4 | Do we allow "lending for money" (rental), or strictly free/symbolic? | Тимур | Week 1 |
| 5 | Should we integrate with existing Madrid sustainability communities for launch? | Bounds | Week 2 |
| 6 | PWA push notifications — what fallback for iOS (no Safari push)? | Forge | Week 2 |
| 7 | Do we need GDPR compliance documentation for launch? | Atlas | Week 2 |

---

## 9. Assumptions & Risks

### Assumptions

1. Madrid residents are willing to meet strangers for item exchange
2. The "borrow" behavior can be taught (it's not culturally ingrained like buy/sell)
3. Supabase free tier handles MVP scale
4. Users will leave reviews consistently (70%+ rate)
5. Items won't be damaged/stolen at a rate that destroys trust (<2% incidents)

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Low adoption — "why not just buy?" | High | High | Strong onboarding, seed inventory, influencer launch |
| Safety incidents (theft, harassment) | Low | Critical | Safety guidelines, public pickup, report system, pickup codes |
| Supply << Demand (empty marketplace) | Medium | High | Seed 100+ listings, encourage "give away" behavior |
| Users treat it as free marketplace (reselling) | Medium | Medium | Reviews, reports, community moderation, no-shipping policy |
| Technical: Mapbox costs at scale | Medium | Medium | Monitor usage, consider Leaflet fallback |
| Competitor (Wallapop) adds borrow feature | Low | High | Speed to market, community moat, trust depth |

---

*End of PRD v0.1. Next: ROADMAP-v0.1.md.*
