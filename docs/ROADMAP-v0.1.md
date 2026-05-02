# Neighborly v2 — Roadmap v0.1

> **Status:** Draft — aligned with PRD v0.1 and Product Workshop  
> **Date:** 2026-05-02  
> **Author:** Spark (Product Lead)  
> **Language:** English

---

## Overview

This roadmap covers Phase 0 (Product Workshop) through Phase 4 (Post-MVP Growth). Each phase has clear deliverables, owners, and exit criteria.

**Timeline:**
- Phase 0: Week 1–2 (May 2026)
- Phase 1: Week 3–6 (May–June 2026)
- Phase 2: Week 7–10 (June–July 2026)
- Phase 3: Week 11–14 (July–August 2026)
- Phase 4: Month 4+ (September 2026+)

---

## Phase 0: Product Discovery ✅ (Current)

**Duration:** 2 weeks  
**Goal:** Define what we’re building, for whom, and why.

### Deliverables

| Deliverable | Owner | Status |
|-------------|-------|--------|
| Product Workshop document | Spark | ✅ Done |
| PRD v0.1 | Spark | ✅ Done |
| Roadmap v0.1 | Spark | ✅ Done |
| Competitive analysis deep-dive | Bounds | ⏳ Pending |
| Madrid neighborhood taxonomy | Bounds | ⏳ Pending |
| User interview plan (5–10 interviews) | Bounds + Тимур | ⏳ Pending |

### Exit Criteria
- [ ] PRD reviewed and approved by Atlas + Тимур
- [ ] Open questions answered (see PRD Section 8)
- [ ] Team aligned on MVP scope (MUST vs SHOULD vs COULD)
- [ ] Madrid neighborhood list finalized

---

## Phase 1: Design & Architecture

**Duration:** 4 weeks  
**Goal:** Design the system before writing code.

### Week 1: Design System & UX

| Task | Owner | Output |
|------|-------|--------|
| Design system (colors, typography, spacing, components) | Muse | Figma library |
| User flow diagrams (all 7 steps of core loop) | Muse | Figma flows |
| Wireframes: Home, Listing Detail, Profile, Chat | Muse | Figma wireframes |
| Mobile breakpoints spec (375px / 768px / 1024px / 1440px) | Muse | Design doc |
| Dark mode spec | Muse | Figma variants |

### Week 2: High-Fidelity Design

| Task | Owner | Output |
|------|-------|--------|
| Hi-fi mockups: Home (map + list) | Muse | Figma |
| Hi-fi mockups: Listing Detail | Muse | Figma |
| Hi-fi mockups: Profile (self + other) | Muse | Figma |
| Hi-fi mockups: Chat / Messages | Muse | Figma |
| Hi-fi mockups: Create Listing | Muse | Figma |
| Hi-fi mockups: Borrow Flow (modal) | Muse | Figma |
| Hi-fi mockups: Notifications | Muse | Figma |
| Hi-fi mockups: Onboarding | Muse | Figma |
| Icon set (custom or Lucide) | Muse | Asset package |

### Week 3: Technical Architecture

| Task | Owner | Output |
|------|-------|--------|
| Database schema (ERD) | Forge | `docs/ARCHITECTURE.md` |
| API contract (REST / RPC spec) | Forge | `docs/API.md` |
| RLS policies design | Forge | Schema + policies |
| Realtime subscriptions spec | Forge | `docs/REALTIME.md` |
| Storage bucket design (avatars, listing photos) | Forge | `docs/STORAGE.md` |
| Auth flow diagram (signup → confirm → profile) | Forge | `docs/AUTH.md` |
| Tech stack finalization | Atlas | Decision record |
| Component architecture (Server vs Client) | Atlas | `docs/FRONTEND.md` |
| State management strategy | Atlas | Decision record |
| Caching strategy (ISR, SWR, etc.) | Atlas | Decision record |

### Week 4: Infrastructure Setup

| Task | Owner | Output |
|------|-------|--------|
| New repo setup (`q1t-architect/neighborly`) | Atlas | Repo initialized |
| Vercel project + env vars | Atlas | Deployed hello-world |
| Supabase project setup | Forge | Project ready |
| Database migrations (profiles, listings, reservations, reviews, conversations, messages, notifications) | Forge | `supabase/migrations/` |
| Storage buckets (avatars, listing-photos) | Forge | Buckets + RLS |
| Auth configuration (email confirmation, password reset) | Forge | Working auth |
| CI/CD pipeline (GitHub Actions → Vercel) | Atlas | Auto-deploy on push |
| Linting + formatting config (ESLint, Prettier) | Atlas | Config files |

### Exit Criteria
- [ ] All Figma designs reviewed by Тимур
- [ ] Database schema approved by Forge + Atlas
- [ ] Hello-world deploys successfully to Vercel
- [ ] Auth works end-to-end (signup → confirm → login)
- [ ] Team ready to start feature development

---

## Phase 2: Core Feature Development

**Duration:** 4 weeks  
**Goal:** Build the MVP — everything in PRD "MUST" column.

### Sprint 1 (Week 1): Auth & Profile

| Feature | Owner | PRD Ref |
|---------|-------|---------|
| Signup page (email + password + name) | Spark | AUTH-01, AUTH-04 |
| Login page | Spark | AUTH-02 |
| Password reset | Spark | AUTH-03 |
| Email confirmation flow | Spark | AUTH-01 |
| Profile page (view own) | Spark | PROF-01 |
| Profile edit page | Spark | PROF-02 |
| Avatar upload | Spark | PROF-03 |
| Profile page (view other) | Spark | PROF-01 |
| Trust score display | Spark | PROF-04 |
| "Post item" button in navigation | Spark | NAV-01 |

**Exit:** User can sign up, verify email, complete profile, view others.

### Sprint 2 (Week 2): Listings

| Feature | Owner | PRD Ref |
|---------|-------|---------|
| Create listing form (title, desc, category, photos) | Spark | LIST-01–05 |
| Listing photo upload (up to 5, validation) | Spark | LIST-02 |
| Location picker (map pin) | Spark | LIST-04 |
| Edit listing | Spark | LIST-07 |
| Delete listing | Spark | LIST-08 |
| Home page: map view with pins | Spark | DISC-01 |
| Home page: list view with cards | Spark | DISC-02 |
| Filter bar (category, radius, availability) | Spark | DISC-03–06 |
| Sort (distance, newest) | Spark | DISC-07–08 |
| Listing detail page | Spark | DET-01–07 |

**Exit:** User can create, browse, view listings. Marketplace has inventory.

### Sprint 3 (Week 3): Borrow Flow & Chat

| Feature | Owner | PRD Ref |
|---------|-------|---------|
| Borrow request modal (dates, message) | Spark | BOR-01 |
| Owner notification (in-app) | Spark | BOR-02 |
| Owner confirm/decline UI | Spark | BOR-03 |
| Borrower notification | Spark | BOR-04 |
| Pickup code display | Spark | BOR-05 |
| Chat system (conversations list + thread) | Spark | CHAT-01–04 |
| Real-time messaging | Spark | CHAT-01 |
| Unread counter | Spark | CHAT-03 |
| Listing status: reserved | Spark | BOR-07 |
| Notifications center | Spark | NOT-01–06 |

**Exit:** User can borrow, chat, coordinate pickup. Core loop works.

### Sprint 4 (Week 4): Pickup, Return & Reviews

| Feature | Owner | PRD Ref |
|---------|-------|---------|
| Pickup confirmation (borrower + owner) | Spark | PICK-01–03 |
| Return confirmation (borrower + owner) | Spark | PICK-04–06 |
| Listing returns to available | Spark | PICK-06 |
| Review form (rating + text) | Spark | REV-01–03 |
| Reviews displayed on profile | Spark | REV-04 |
| Trust score calculation | Spark | REV-05 |
| Review reminder notification | Spark | REV-07 |
| Report listing button | Spark | DET-09 |
| Report user button | Spark | PROF-08 |
| Onboarding flow (3-step) | Spark | AUTH-06 |

**Exit:** Full loop: borrow → pickup → use → return → review. Trust system alive.

### Phase 2 Exit Criteria
- [ ] All PRD "MUST" features implemented
- [ ] `tsc --noEmit` passes with 0 errors
- [ ] All pages responsive (375px → 1440px)
- [ ] Auth flow works end-to-end
- [ ] Core loop works: create listing → browse → request → confirm → chat → pickup → return → review
- [ ] No mock data — everything from Supabase
- [ ] QA pass by Proof (no critical bugs)

---

## Phase 3: Polish, Seed & Launch Prep

**Duration:** 4 weeks  
**Goal:** Make it delightful, fill it with data, prepare for launch.

### Week 1: Polish & Performance

| Task | Owner |
|------|-------|
| Loading states (skeletons) | Spark |
| Error states (friendly messages) | Spark |
| Empty states with CTAs | Spark |
| Toast notifications | Spark |
| Page transitions (Framer Motion) | Spark |
| Accessibility audit (keyboard, screen reader) | Spark |
| Performance audit (Lighthouse > 80) | Spark |
| SEO meta tags, Open Graph | Spark |
| PWA manifest + service worker | Spark |
| Favicon + app icons | Muse |

### Week 2: Seed Data & Content

| Task | Owner |
|------|-------|
| Create 50+ seed listings across 5 barrios | Bounds + Тимур |
| Create 10+ seed profiles with photos | Bounds + Тимур |
| Seed exchanges + reviews (demonstrate trust) | Bounds |
| Safety guidelines page content | Bounds |
| Community standards content | Bounds |
| FAQ content | Bounds |
| Terms of Service (basic) | Bounds |
| Privacy Policy (GDPR basic) | Bounds |

### Week 3: SHOULD Features

| Feature | Owner | PRD Ref |
|---------|-------|---------|
| Favorites / bookmarks | Spark | DET-08 |
| Search (server-side full-text) | Spark | DISC-10 |
| Listing status management (pause, re-list) | Spark | LIST-09–10 |
| Email notifications (digest) | Spark | NOT-08 |
| Push notifications (browser) | Spark | NOT-09 |
| Pickup scheduling (calendar picker) | Spark | BOR-08 |
| Due date reminders | Spark | BOR-11 |
| Wishlist tags | Spark | COULD |

### Week 4: Launch Prep

| Task | Owner |
|------|-------|
| Beta testing with 10–20 friends | Тимур + team |
| Bug fixes from beta feedback | Spark |
| Analytics setup (PostHog or Plausible) | Forge |
| Monitoring (Sentry for errors) | Forge |
| Launch announcement copy | Bounds |
| Social media assets | Muse |
| Influencer outreach list (Madrid sustainability) | Bounds |
| Press kit | Bounds |
| Launch date set | Atlas + Тимур |

### Exit Criteria
- [ ] 50+ real listings in 5 barrios
- [ ] Lighthouse score ≥ 80 on all pages
- [ ] 0 critical bugs, ≤ 5 minor bugs
- [ ] Beta feedback incorporated
- [ ] Analytics dashboard live
- [ ] Launch plan approved by Тимур

---

## Phase 4: Post-Launch Growth

**Duration:** Ongoing (Month 4+)  
**Goal:** Learn from users, iterate, grow.

### Month 4: Stabilize & Learn

| Task | Owner |
|------|-------|
| Daily monitoring of metrics (MAU, MCE, NPS) | Atlas |
| Weekly bug triage | Atlas |
| User feedback collection (in-app survey) | Bounds |
| Analyze drop-off points in funnel | Bounds |
| A/B test: map-first vs list-first default | Bounds |
| Fix top 10 user-reported issues | Spark |

### Month 5–6: Growth Features

| Feature | Owner | Rationale |
|---------|-------|-----------|
| Referral program ("invite a neighbor") | Spark | Organic growth |
| Gamification badges (First Exchange, Super Neighbor) | Spark | Engagement |
| Neighborhood feed / community posts | Spark | Differentiation from pure marketplace |
| "Verified neighbor" subscription launch | Spark | Monetization test |
| Symbolic fee collection (Stripe) | Spark | Revenue proof |
| Identity verification (phone/ID) | Forge | Trust boost |
| Multi-language (ES + EN) | Spark | Madrid expat market |

### Month 7–12: Expansion

| Milestone | Target |
|-----------|--------|
| Barcelona launch | Month 7 |
| Valencia + Seville launch | Month 9 |
| 5,000 MAU | Month 9 |
| 1,000 MCE/month | Month 9 |
| Seed funding / angel conversations | Month 10–12 |
| Lisbon pilot (EU expansion test) | Month 12 |

---

## Team Allocation by Phase

| Phase | Atlas | Spark | Muse | Forge | Bounds | Proof | Kinetic |
|-------|-------|-------|------|-------|--------|-------|---------|
| 0: Discovery | Review | Lead | — | Consult | Research | — | — |
| 1: Design/Arch | Lead | — | Lead | Lead | Support | — | — |
| 2: Core Dev | Review | Lead | Support | Support | — | Test | — |
| 3: Polish | Review | Lead | Support | Support | Content | Test | — |
| 4: Growth | Lead | Lead | Support | Support | Research | Test | — |

**Note:** Kinetic is not allocated to Neighborly. Reserved for ATH Technologies scroll-animation projects.

---

## Dependencies & Blockers

| Dependency | Blocks | Mitigation |
|------------|--------|------------|
| Тимур approves PRD | Phase 1 start | Target: Week 1 |
| Muse delivers Figma designs | Phase 2 start | Target: Week 4 |
| Forge sets up Supabase | Phase 2 start | Target: Week 4 |
| Vercel project configured | Phase 2 deploy | Target: Week 4 |
| 50 seed listings | Phase 3 launch | Target: Week 10 |
| Stripe account (for symbolic fee) | Phase 4 monetization | Target: Month 4 |

---

## Key Milestones Summary

| Date | Milestone | Success Criteria |
|------|-----------|-----------------|
| **Week 2** | PRD approved | Atlas + Тимур sign-off |
| **Week 4** | Design + Architecture complete | Figma ready, DB schema approved, hello-world deployed |
| **Week 8** | Core features complete | All MUST features implemented, QA passed |
| **Week 12** | MVP polished | 50+ listings, Lighthouse ≥ 80, beta complete |
| **Week 14** | **LAUNCH** 🚀 | Public announcement, Madrid only |
| **Month 6** | 500 MAU, 100 MCE | Metrics dashboard confirms |
| **Month 12** | 2,000 MAU, 500 MCE, Barcelona live | Metrics dashboard confirms |

---

## Budget / Cost Projections

| Item | Monthly Cost (MVP) | Notes |
|------|-------------------|-------|
| Vercel Pro | €20 | Hosting |
| Supabase Pro | €25 | DB + Auth + Storage + Realtime |
| Mapbox | €0–50 | Depends on MAU |
| Stripe | €0 + transaction fees | No monthly fee |
| PostHog / Plausible | €0–20 | Analytics |
| Sentry | €0–26 | Error tracking |
| **Total infrastructure** | **~€65–140/mo** | |
| Design (Muse) | One-time | Figma = free |
| **Total monthly burn** | **~€100/mo** | Excluding team time |

---

*End of Roadmap v0.1. Ready for review by Atlas + Тимур.*
