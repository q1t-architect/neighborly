# Neighborly v2 — Product Workshop

> **Status:** Phase 0 — Product Discovery  
> **Date:** 2026-05-02  
> **Author:** Spark (Product Lead / Strategist)  
> **Audience:** Atlas, Тимур, team  
> **Language:** English (documents) / Russian (team comms)

---

## 1. Problem Statement

### The Real Problem

**Urban households own hundreds of items they use <5 times per year.** Drills, ladders, camping gear, party supplies, specialty kitchen tools, sports equipment. These items sit in closets, garages, and storage units — depreciating, gathering dust, consuming space.

**Simultaneously, neighbors 200 meters away are buying the exact same item new** — spending money, creating packaging waste, and adding carbon to the supply chain — because they don't know someone nearby has it available.

**The friction is social, not logistical.** People don't borrow from strangers because:
1. They don't know who has what
2. They don't trust strangers with their belongings
3. There's no easy way to coordinate handoff
4. No reputation system exists at neighborhood scale
5. "Asking feels awkward" — no cultural norm for neighborly borrowing

### The Opportunity

- **Spain:** 47M people, 80% urban, high apartment density in Madrid/Barcelona/Valencia
- **Madrid alone:** 3.3M residents, dense barrio culture (Malasaña, Chamberí, La Latina)
- **Climate angle:** Spain is increasingly sustainability-conscious. EU Green Deal awareness.
- **Economic angle:** Post-pandemic cost-of-living pressures make "why buy when you can borrow" resonant.

### Problem Framing (Jobs-to-be-Done)

| Job | Current solution | Pain point |
|-----|-----------------|------------|
| "I need a drill for 20 minutes" | Buy one €40 at Leroy Merlin | Overpaying, storing, underusing |
| "I have a ladder I never use" | Store it / throw it away | Wasted space, guilt, waste |
| "I want to meet my neighbors" | Attend random events | Low frequency, high effort |
| "I need a projector for movie night" | Ask in WhatsApp group | No catalog, awkward, low response |

---

## 2. Target Audience

### Primary Persona: "Clara — The Conscious Urbanite"

- **Demographics:** 28–38, urban professional, lives in apartment (rented or owned), no car or occasional car use
- **Location:** Madrid centro, Malasaña, or Chamberí
- **Values:** Sustainability, community, minimalism, experiences > possessions
- **Behavior:** Uses Too Good To Go, buys secondhand on Vinted, brings own bag, composts
- **Tech:** iPhone, Instagram, WhatsApp groups, Wallapop (for selling), Notion for planning
- **Income:** €25k–45k, cost-conscious but not price-obsessed
- **Frustration:** "I bought a €60 tent for one camping trip. Now it lives in my 8m² storage room."
- **Motivation:** "I want my neighborhood to feel like a village. I want to know Maria from 3B."

### Secondary Persona: "Miguel — The Practical Father"

- **Demographics:** 35–50, family with kids, lives in suburbs or family barrio (Salamanca, Retiro)
- **Values:** Frugality, practicality, safety, reliability
- **Behavior:** Facebook Marketplace for kids' gear, Nextdoor for recommendations
- **Frustration:** "My kids outgrow everything in 6 months. I have €500 in perfectly good stuff and no idea who needs it."
- **Motivation:** "If I can help another family AND clear my garage, that's a win."

### Tertiary Persona: "Sofia — The Newcomer"

- **Demographics:** 22–30, recent transplant to Madrid (student, digital nomad, expat)
- **Values:** Connection, low commitment, exploration
- **Behavior:** Uses Bumble BFF, attends meetups, follows local Instagram accounts
- **Frustration:** "I don't know anyone here. I need a hammer but I'm not buying one for a 6-month stay."
- **Motivation:** "Borrowing is a low-stakes way to meet people and feel like I belong."

### Anti-Persona: "The Reseller"

- Someone who wants to acquire free items and resell them
- Someone who treats the platform as a source of inventory
- **Why we exclude them:** They erode trust, damage community perception, create disputes.
- **How we filter:** Verified profiles, review system, "report" mechanism, community moderation.

---

## 3. Core User Loop

### The Full Loop: Discovery → Interest → Request → Pickup → Use → Return → Review

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  DISCOVERY  │───>│   INTEREST  │───>│   REQUEST   │───>│   PICKUP    │
│  (Browse)   │    │ (View item) │    │(Borrow ask) │    │  (Meet up)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                        │
┌─────────────┐    ┌─────────────┐    ┌─────────────┘
│   REVIEW    │<───│   RETURN    │<───│     USE     │
│  (Rate +    │    │  (Hand back)│    │  (Enjoy)    │
│   Review)   │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Loop Detail — Step by Step

#### 1. Discovery
- **Trigger:** User opens app or gets push notification
- **Action:** Browse map or list of available items within walking distance
- **Key feature:** Map-first view with item pins, category filters, "near me" sorting
- **Emotion:** Curiosity — "What do my neighbors have?"
- **Friction to eliminate:** Empty states, slow loading, no items in area

#### 2. Interest
- **Trigger:** User taps an item pin or card
- **Action:** View listing detail — photos, description, owner profile, reviews, availability
- **Key feature:** Rich listing page with owner trust score, past exchanges, item condition
- **Emotion:** Desire — "I want this. Can I trust this person?"
- **Friction to eliminate:** No owner info, no reviews, unclear availability

#### 3. Request
- **Trigger:** User taps "Request to borrow"
- **Action:** Send borrow request with proposed dates/times. Owner receives notification.
- **Key feature:** Calendar picker for proposed pickup window, optional message to owner
- **Emotion:** Anticipation — "Will they say yes?"
- **Friction to eliminate:** No response from owner, unclear pickup logistics, fear of rejection

#### 4. Pickup
- **Trigger:** Owner confirms request + agrees on time/place
- **Action:** Both parties meet at agreed public location. Exchange item. Pickup code verification.
- **Key feature:** Chat for coordination, safety guidelines, pickup code for both parties, location sharing (optional)
- **Emotion:** Excitement + slight nervousness — "Meeting a stranger."
- **Friction to eliminate:** No-shows, unsafe locations, miscommunication on time/place

#### 5. Use
- **Trigger:** User has the item
- **Action:** Use the item for agreed period
- **Key feature:** In-app reminder "Return due in 2 days", ability to message owner with questions
- **Emotion:** Gratitude, utility — "This is exactly what I needed."
- **Friction to eliminate:** Broken/damaged item, item not as described, no way to contact owner during use

#### 6. Return
- **Trigger:** Borrow period ending
- **Action:** User returns item to owner (or drops at agreed location). Owner confirms receipt.
- **Key feature:** Return confirmation flow, condition check, "returned on time" badge
- **Emotion:** Satisfaction — "I did the right thing."
- **Friction to eliminate:** Owner not available for return, disputes over condition, late returns

#### 7. Review
- **Trigger:** Return confirmed
- **Action:** Both parties leave review (rating 1-5 + text). Reviews feed into trust score.
- **Key feature:** Quick 3-tap rating + optional text, reviews visible on profile, impact on trust score
- **Emotion:** Closure, community — "I helped someone / Someone helped me."
- **Friction to eliminate:** No reminder to review, fear of retaliation, review not visible

### Loop Completion = Trust Building

Each completed loop:
- Increases both users' exchange count
- Updates rating based on reviews
- Reinforces "this platform works" belief
- Creates social connection ("I know someone who has a drill")
- Builds neighborhood inventory awareness

---

## 4. Competitive Landscape

### Direct Competitors (Borrow/Lend Focused)

| Competitor | What they do | Strengths | Weaknesses | Neighborly Differentiation |
|-----------|-------------|-----------|-----------|---------------------------|
| **Olio** | Free food + household item sharing | 9M+ users, strong brand, food focus | Food-first (not item-first), UK-centric, weak trust layer | Item-first, Madrid-native, trust-first profiles |
| **Bunz** | Barter/trade network | Cash-free, community vibes, Canada-based | Trading is complex ("what do you want?"), not borrowing | Borrowing is simpler than trading — just ask and return |
| **BuddyAvenue** | Borrow/lend platform | Purpose-built for borrowing | Unknown scale, unclear geographic focus | Hyperlocal density + Madrid specificity |
| **Buy Nothing Project** | Giving away items for free | Massive grassroots movement, no app needed | Facebook Groups only, no structured exchange, no trust system | App-native, structured pickup, trust scores, reviews |

### Indirect Competitors (Buy/Sell/General)

| Competitor | What they do | Relevance to Neighborly |
|-----------|-------------|------------------------|
| **Wallapop** | Buy/sell secondhand in Spain | Dominant in Spain but transactional (money changes hands). Not about trust or community. No borrowing. |
| **Facebook Marketplace** | Buy/sell/give away locally | Free section exists but buried. No borrowing flow. No trust system. Toxic UX. |
| **Nextdoor** | Neighborhood social network | Has "For Sale & Free" but it's a side feature. Not purpose-built for borrowing. Verification by address (slow). |
| **Vinted** | Clothing buy/sell | Vertical-specific. Not relevant for tools, electronics, sports gear. |

### Competitive Moat Analysis

**What none of them do well:**
1. **Purpose-built borrow/lend flow** — Most are buy/sell with "free" as an afterthought
2. **Trust-first at neighborhood scale** — Reviews + exchanges + verification = local reputation
3. **Pickup coordination** — No one optimizes the "when/where do we meet?" problem
4. **Cultural fit for Spain** — Wallapop dominates buy/sell but borrowing is culturally undeveloped

**Neighborly's positioning:**
- Not a marketplace (no money for items)
- Not a social network (not about posting)
- **It's a "neighbor utility"** — like a shared toolbox for your building/block

---

## 5. Trust & Safety Model

### The Core Tension

**We are asking strangers to exchange physical goods in person.** This is inherently risky. Our entire product depends on making this feel safe.

### Trust Layers (Onion Model)

```
Layer 1: Identity (Who are you?)
  └── Email verification → Phone number → Optional ID document (future)

Layer 2: Reputation (Can I trust you?)
  └── Exchange count → Rating average → Written reviews → Verified badge

Layer 3: Social Proof (Do others vouch for you?)
  └── Neighborhood tag → Mutual connections (future) → "Trusted by X neighbors"

Layer 4: Transaction Safety (Will this go well?)
  └── Pickup code → Chat on-platform → Safety guidelines → Public pickup locations

Layer 5: Dispute Resolution (What if something goes wrong?)
  └── Report button → Community moderation → Block user → Support escalation
```

### Safety Guidelines (Built into Product)

1. **Public meetups only** — Default to café, metro station, plaza. Never home addresses.
2. **Pickup code** — Both parties confirm with matching code at handoff. Prevents "wrong person" scenarios.
3. **Chat stays on-platform** — Evidence trail if dispute arises. No "let's move to WhatsApp" nudge.
4. **Share location with friend** (future) — One-tap share pickup location + time with trusted contact.
5. **Emergency contact** — In-app "I feel unsafe" button with quick access to local emergency number.

### Content Moderation

- **Auto-flag:** New listings scanned for prohibited items (weapons, chemicals, illegal goods)
- **Community reports:** Users can report listings or users. N reports = automatic pause pending review.
- **No pre-moderation for MVP:** Post goes live immediately. Trust + report system handles edge cases.

---

## 6. Monetization

### Decision: **Freemium with Symbolic Fee for MVP**

**Rationale:** We need revenue proof-of-concept early, but we can't put a paywall on core borrowing (that would kill adoption).

### Revenue Model

| Tier | Price | What you get |
|------|-------|-------------|
| **Free** | €0 | Browse, borrow, lend, chat, basic profile, 5 active listings |
| **Neighbor** | €2.99/mo or €24.99/yr | Unlimited listings, priority search ranking, "verified neighbor" badge, early access to new features |

### Symbolic Fee (Per Transaction)

- **€0.05–€0.50** per completed borrow — "like a stamp on a postcard"
- **Rationale:** Covers platform costs (hosting, Supabase, support). Low enough to be invisible. High enough to matter at scale.
- **Free alternative:** Watch a 15-sec sponsor message or complete a micro-task (future)
- **Payment:** Integrated via Stripe. User tops up wallet (€5 min) or auto-debits.

### Why NOT These Models (for MVP)

| Model | Why deferred |
|-------|-------------|
| Deposit/escrow | Too complex, adds friction, legal complexity |
| Insurance | Requires partnerships, legal entity, claims process |
| Ads | Dilutes trust-first brand. Community hates ads. |
| B2B (business lending) | Different problem, different sales cycle. Post-MVP. |
| Commission on late fees | Requires enforcement mechanism. Post-MVP. |

### Revenue Projections (MVP, conservative)

- **Month 6:** 500 active users, 100 exchanges/month → €20-50 symbolic fees + 20 subscribers = ~€80/mo
- **Month 12:** 2,000 active users, 500 exchanges/month → €100-250 fees + 80 subscribers = ~€350/mo
- **Month 24:** 10,000 active users, 3,000 exchanges/month → €600-1,500 fees + 400 subscribers = ~€2,000/mo

**Note:** MVP revenue is symbolic. The real goal is proving unit economics and user willingness to pay.

---

## 7. Geography Strategy

### Phase 1: Madrid (Months 1–6)

**Why Madrid:**
- Тимур is there — product intuition, local network, language
- 3.3M people, dense urban core ( Centro = 130k people/km²)
- Strong barrio identity — people identify as "from Malasaña" not "from Madrid"
- High apartment living = low storage = need to borrow
- Wallapop is huge here = proof of local marketplace appetite
- Climate: mild weather = year-round outdoor item usage (bikes, sports gear)

**Launch strategy:**
- Start with 3–5 barrios: Malasaña, Chueca, La Latina, Chamberí, Centro
- Seed with 100+ listings before public launch
- Partner with 2–3 local sustainability influencers/communities
- "Madrid only — other cities coming soon" messaging

### Phase 2: Barcelona (Months 6–12)

**Why Barcelona:**
- 1.6M people, similar density and barrio culture (Gràcia, Eixample, Born)
- Similar sustainability consciousness
- Different language dynamic (Catalan + Spanish) — tests i18n
- Wallapop penetration = similar marketplace maturity

**Launch strategy:**
- Clone Madrid playbook
- Local ambassador program
- Barcelona-specific neighborhoods

### Phase 3: Valencia + Seville (Months 12–18)

- Smaller cities (800k + 700k)
- Test "medium city" density — is there enough inventory?
- Prove model works outside Spain's two biggest metros

### Phase 4: EU Expansion (Months 18–36)

- Lisbon, Porto (Portuguese-speaking — tests localization depth)
- Paris, Berlin, Amsterdam (major metros, high sustainability awareness)
- Each city requires: local seed data, neighborhood taxonomy, language, payment method

### Geography in Product

- **Neighborhood as first-class entity:** User selects/verifies neighborhood on signup
- **Distance-based discovery:** Default radius = 1km walking. Adjustable to 3km.
- **Neighborhood feed:** "What's available in Malasaña this week?" (future)
- **City gate:** Unsupported cities see "Coming to [city] soon — join waitlist"

---

## 8. MVP Scope

### MUST (Launch without these = no product)

| Feature | Why critical | Complexity |
|---------|-------------|------------|
| **Auth (signup/login)** | Can't borrow without identity | Medium |
| **Profile (name, photo, neighborhood, bio)** | Trust requires identity | Low |
| **Create listing (photos, title, category, location)** | No inventory = empty marketplace | Medium |
| **Browse listings (map + list, filters)** | Core discovery | Medium |
| **Listing detail (photos, owner, reviews)** | Decision to borrow | Low |
| **Borrow request flow** | Core transaction | Medium |
| **Owner confirmation/rejection** | Completes the loop | Low |
| **In-app chat** | Coordination | Medium |
| **Pickup + return confirmation** | Transaction closure | Medium |
| **Reviews (rating + text)** | Trust building | Low |
| **Trust score display** | Safety signal | Low |
| **Report user/listing** | Minimum safety | Low |

### SHOULD (Strongly improve conversion/retention)

| Feature | Impact | Complexity |
|---------|--------|------------|
| **Favorites/bookmarks** | Users return for saved items | Low |
| **Search (full-text)** | Discovery at scale | Medium |
| **Push notifications** | Re-engagement, response speed | Medium |
| **Email notifications** | Off-platform awareness | Low |
| **Listing status management** | Owner control (pause, re-list) | Low |
| **Due date reminders** | Return reliability | Low |
| **Onboarding flow** | New user activation | Medium |
| **Empty state CTAs** | Convert browsers to creators | Low |

### COULD (Nice to have, post-launch)

| Feature | Impact | Complexity |
|---------|--------|------------|
| **Wishlist + alerts** | Demand signaling, retention | Medium |
| **Gamification badges** | Engagement, community feel | Low |
| **Neighborhood feed / community posts** | Social layer, differentiation | High |
| **Identity verification (ID/phone)** | Trust boost, but friction | Medium |
| **Pickup scheduling (calendar integration)** | Convenience | Medium |
| **Referral program** | Organic growth | Low |
| **Multi-language (ES/EN)** | Madrid expat community | Medium |

### WON'T (MVP — explicit deferral)

| Feature | Why deferred |
|---------|-------------|
| **Shipping / delivery** | Against hyperlocal positioning |
| **Mobile native app** | PWA sufficient, app store complexity |
| **Deposit / escrow** | Too complex for MVP trust building |
| **Insurance / damage claims** | Legal complexity, low frequency |
| **B2B / business lending** | Different customer, different sales cycle |
| **AI-powered recommendations** | Insufficient data for ML |
| **In-app payments for items** | Not a marketplace — borrowing is free |
| **Moderation before publish** | Slows supply growth, report system sufficient |

---

## 9. Success Metrics

### North Star Metric

**Monthly Completed Exchanges (MCE)** — A borrow request that was confirmed, picked up, used, returned, and reviewed.

This captures:
- Supply (listings created)
- Demand (browse → request)
- Trust (owner confirms)
- Execution (pickup + return)
- Satisfaction (review left)

### KPI Dashboard

| Metric | Target (Month 6) | Target (Month 12) | Measurement |
|--------|-----------------|-------------------|-------------|
| **MAU** | 500 | 2,000 | Unique users with session |
| **MCE** | 100 | 500 | Completed borrow cycles |
| **Listing creation rate** | 30% of MAU | 25% of MAU | % users who create ≥1 listing |
| **Request → Confirm rate** | 60% | 70% | Borrow requests accepted |
| **Pickup completion rate** | 80% | 85% | Confirmed requests → actual pickup |
| **Return on-time rate** | 90% | 92% | Returns within agreed window |
| **Review rate** | 70% | 75% | Completed exchanges with review |
| **Avg rating** | ≥4.2 | ≥4.3 | Star average across all reviews |
| **NPS** | +20 | +35 | "Would you recommend Neighborly?" |
| **Churn (30-day)** | <40% | <30% | Users who don't return |
| **CAC** | €2 | €1.5 | Cost per new user (organic + paid) |
| **LTV (projected)** | €15 | €25 | Symbolic fees + subscription revenue |

### Proxy Metrics (Leading Indicators)

| Metric | Why it matters |
|--------|---------------|
| Time to first borrow | Speed of value delivery |
| Messages per exchange | Engagement + coordination quality |
| Listings per user (supply depth) | Marketplace liquidity |
| Daily active neighborhoods | Geographic density |
| Repeat borrowers | Product-market fit signal |
| % users with ≥3 exchanges | Habit formation |

### Vanity Metrics (Track but don't optimize)

- Total downloads / signups (without activation = meaningless)
- Total listings (without borrow requests = dead inventory)
- Social media followers (without conversion = noise)

---

*End of Product Workshop document. Next: PRD-v0.1.md and ROADMAP-v0.1.md.*
