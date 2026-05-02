# SECURITY.md — RLS Policy Design

> **Project:** Neighborly v2  
> **Author:** Kinetic  
> **Date:** 2026-05-02  
> **Status:** Draft — Phase 1 Design  
> **Scope:** Row Level Security (RLS) for all database tables

---

## Overview

All tables have RLS enabled by default. No policy = no access (deny-all baseline). Policies follow the principle of least privilege: users access only what belongs to them or is explicitly public.

**Admin role** is stored in `profiles.role` column (`'user'` | `'admin'`). Admin checks use a subquery to avoid JWT dependency:

```sql
(SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
```

---

## Table: `profiles`

**Purpose:** Public user identity. Created automatically on signup via trigger.

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read any profile (public)
CREATE POLICY "profiles_select"
  ON profiles FOR SELECT
  USING (true);

-- Users can only update their own profile
CREATE POLICY "profiles_update"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- INSERT handled by SECURITY DEFINER trigger only
-- No direct INSERT policy for authenticated users
```

**Notes:**
- `role` column is NOT updatable via RLS (no UPDATE policy covers it). Admin promotion is a manual DB operation only.
- Avatar URL is stored here but the file itself is governed by Storage RLS (see STORAGE.md).

---

## Table: `listings`

**Purpose:** Item postings. Public when active, private otherwise.

```sql
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- Public: see active listings only
-- Owners: see all their own listings (any status)
-- Admins: see everything
CREATE POLICY "listings_select"
  ON listings FOR SELECT
  USING (
    status = 'available'
    OR auth.uid() = owner_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

-- Owners create their own listings
CREATE POLICY "listings_insert"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Owners edit their own; admins can moderate (e.g., force-archive)
CREATE POLICY "listings_update"
  ON listings FOR UPDATE
  USING (
    auth.uid() = owner_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    auth.uid() = owner_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

-- Owners delete their own; admins can remove
CREATE POLICY "listings_delete"
  ON listings FOR DELETE
  USING (
    auth.uid() = owner_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );
```

**State transitions enforced at application layer** (not via RLS):
- `available` → `reserved` (triggered by reservation confirmation)
- `reserved` → `available` (return confirmed) or `given` (owner archives)
- `available` → `archived` (owner action or 30-day auto-expiry via cron)

---

## Table: `reservations`

**Purpose:** Borrow requests and their lifecycle.

```sql
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- Borrower and owner can see their reservations
CREATE POLICY "reservations_select"
  ON reservations FOR SELECT
  USING (
    auth.uid() = borrower_id
    OR auth.uid() = owner_id
  );

-- Only authenticated users can create; borrower_id must match self
CREATE POLICY "reservations_insert"
  ON reservations FOR INSERT
  WITH CHECK (auth.uid() = borrower_id);

-- Both parties can trigger updates, but state machine enforced server-side
-- (owner: confirm/decline; borrower: cancel before pickup)
CREATE POLICY "reservations_update"
  ON reservations FOR UPDATE
  USING (
    auth.uid() = borrower_id
    OR auth.uid() = owner_id
  )
  WITH CHECK (
    auth.uid() = borrower_id
    OR auth.uid() = owner_id
  );
```

**State machine (enforced in SECURITY DEFINER function `update_reservation_status`):**

| Current Status | Actor     | Allowed Transitions     |
|----------------|-----------|-------------------------|
| `pending`      | owner     | → `confirmed`, `declined` |
| `pending`      | borrower  | → `cancelled`           |
| `confirmed`    | borrower  | → `cancelled` (before pickup) |
| `confirmed`    | owner     | → `cancelled` (before pickup) |
| `confirmed`    | system    | → `completed` (after return confirmed) |

Direct `UPDATE reservations SET status = ...` bypasses the state machine. Use the server function:

```sql
-- Example server function for owner confirmation
CREATE OR REPLACE FUNCTION confirm_reservation(p_reservation_id uuid)
RETURNS void SECURITY DEFINER AS $$
BEGIN
  UPDATE reservations
  SET status = 'confirmed', updated_at = now()
  WHERE id = p_reservation_id
    AND owner_id = auth.uid()
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cannot confirm: not owner or wrong status';
  END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## Table: `conversations`

**Purpose:** Chat threads between two participants.

```sql
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Participants can see their own conversations
CREATE POLICY "conversations_select"
  ON conversations FOR SELECT
  USING (
    participant_1 = auth.uid()
    OR participant_2 = auth.uid()
  );

-- Either participant can initiate (but typically triggered by borrow request)
CREATE POLICY "conversations_insert"
  ON conversations FOR INSERT
  WITH CHECK (
    participant_1 = auth.uid()
    OR participant_2 = auth.uid()
  );
```

**Notes:**
- Schema uses `participant_1` / `participant_2` (not an array) for FK-friendly joins.
- Uniqueness: `UNIQUE(LEAST(participant_1, participant_2), GREATEST(participant_1, participant_2))` prevents duplicate conversations.

---

## Table: `messages`

**Purpose:** Messages within a conversation.

```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Only conversation participants can read messages
CREATE POLICY "messages_select"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = messages.conversation_id
        AND (participant_1 = auth.uid() OR participant_2 = auth.uid())
    )
  );

-- Only participants can send; sender_id must match self
CREATE POLICY "messages_insert"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE id = messages.conversation_id
        AND (participant_1 = auth.uid() OR participant_2 = auth.uid())
    )
  );

-- Messages are immutable — no UPDATE or DELETE policies
```

---

## Table: `reviews`

**Purpose:** Post-exchange ratings. Public read, write-once, write-protected.

```sql
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- All reviews are publicly visible
CREATE POLICY "reviews_select"
  ON reviews FOR SELECT
  USING (true);

-- Can only review a completed reservation where you were a party
CREATE POLICY "reviews_insert"
  ON reviews FOR INSERT
  WITH CHECK (
    auth.uid() = reviewer_id
    AND EXISTS (
      SELECT 1 FROM reservations
      WHERE listing_id = reviews.listing_id
        AND status = 'completed'
        AND (borrower_id = auth.uid() OR owner_id = auth.uid())
    )
  );

-- Reviews are immutable — no UPDATE or DELETE policies
-- UNIQUE(listing_id, reviewer_id) constraint prevents double-review
```

---

## Table: `reports`

**Purpose:** User abuse/listing reports.

```sql
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Reporter can see their own reports; admins see all
CREATE POLICY "reports_select"
  ON reports FOR SELECT
  USING (
    auth.uid() = reporter_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

-- Any authenticated user can submit a report
CREATE POLICY "reports_insert"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- Admins can update report status (reviewed/resolved)
CREATE POLICY "reports_update"
  ON reports FOR UPDATE
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );
```

---

## Table: `notifications`

**Purpose:** In-app alerts. Write-protected for users (system-generated only).

```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users see only their own notifications
CREATE POLICY "notifications_select"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can mark their own notifications as read
CREATE POLICY "notifications_update"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- No INSERT policy for regular users
-- Notifications are created ONLY via SECURITY DEFINER functions
-- triggered by reservation state changes, new messages, etc.
```

**Example notification trigger:**

```sql
CREATE OR REPLACE FUNCTION notify_on_reservation()
RETURNS TRIGGER SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
    INSERT INTO notifications (user_id, type, title, body)
    VALUES (
      NEW.borrower_id,
      'reservation_confirmed',
      'Your request was confirmed!',
      'Pick up code: ' || NEW.pickup_code
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notify_reservation
  AFTER UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION notify_on_reservation();
```

---

## RLS Verification Checklist

Before deploying each table's RLS:

- [ ] `ENABLE ROW LEVEL SECURITY` applied
- [ ] Test as anonymous user (no session) — must get 0 rows on private data
- [ ] Test as authenticated user — must see own data, not others'
- [ ] Test admin role — must see all rows
- [ ] Test INSERT with wrong `user_id` — must fail
- [ ] Verify Supabase Realtime respects RLS for private channels (see REALTIME.md)

---

*Next: REALTIME.md (channel design), STORAGE.md (buckets + auth flow)*
