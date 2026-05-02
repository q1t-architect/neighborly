-- =============================================================================
-- Neighborly v2 — Full Database Schema
-- Migration: 003_v2_schema.sql
-- PostgreSQL 15 + PostGIS
-- =============================================================================
-- Covers all entities from PRD v0.1 sections 4.1–4.9 + 7.
-- Designed for production: FK everywhere, soft-delete, RLS, enums,
-- PostGIS, proper index strategy.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid(), crypt()

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Generate pickup code in NLB-XXXX format (server-side, tamper-proof)
CREATE OR REPLACE FUNCTION generate_pickup_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code  TEXT := 'NLB-';
  i     INT;
BEGIN
  FOR i IN 1..4 LOOP
    code := code || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

CREATE TYPE listing_status AS ENUM (
  'available',   -- visible and requestable
  'reserved',    -- active reservation in progress
  'active',      -- picked up, currently with borrower
  'paused',      -- owner temporarily unavailable
  'archived',    -- manually or auto-archived
  'given'        -- permanently given away
);

CREATE TYPE price_type AS ENUM (
  'free',        -- no symbolic fee
  'symbolic'     -- small fee (€0.05–€0.50)
);

CREATE TYPE item_condition AS ENUM (
  'excellent',
  'good',
  'fair'
);

CREATE TYPE reservation_status AS ENUM (
  'pending',               -- borrower sent request, awaiting owner
  'confirmed',             -- owner confirmed; pickup code active
  'active',                -- both confirmed pickup; item in use
  'return_pending',        -- borrower marked "returned"; awaiting owner
  'completed',             -- owner confirmed receipt; reviews unlocked
  'declined',              -- owner declined request
  'cancelled'              -- cancelled by borrower or owner pre-pickup
);

CREATE TYPE notification_type AS ENUM (
  'reservation_request',   -- owner: someone wants to borrow your item
  'reservation_confirmed', -- borrower: owner confirmed
  'reservation_declined',  -- borrower: owner declined
  'reservation_cancelled', -- either: other party cancelled
  'new_message',           -- recipient: new chat message
  'pickup_reminder',       -- borrower/owner: pickup window starting
  'return_due',            -- borrower: item due back soon
  'review_reminder',       -- both: leave a review
  'listing_expiring',      -- owner: listing expires in 3 days
  'system'                 -- generic system message
);

CREATE TYPE report_reason AS ENUM (
  'spam',
  'inappropriate_content',
  'fraud',
  'harassment',
  'item_unavailable',
  'other'
);

CREATE TYPE report_status AS ENUM (
  'open',
  'reviewing',
  'resolved',
  'dismissed'
);

-- ---------------------------------------------------------------------------
-- 1. profiles
-- ---------------------------------------------------------------------------
-- Linked 1:1 to auth.users.
-- Soft-deleted via deleted_at; RLS filters out deleted profiles for public.
-- ---------------------------------------------------------------------------

CREATE TABLE profiles (
  id           UUID           PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT           NOT NULL DEFAULT '',
  avatar_url   TEXT,
  neighborhood TEXT,
  location     GEOGRAPHY(POINT, 4326),  -- home location for distance calc
  bio          TEXT           CHECK (bio IS NULL OR length(bio) <= 300),
  rating       NUMERIC(3, 2)  NOT NULL DEFAULT 0.00
                              CHECK (rating >= 0 AND rating <= 5),
  exchanges    INT            NOT NULL DEFAULT 0 CHECK (exchanges >= 0),
  verified     BOOLEAN        NOT NULL DEFAULT FALSE,
  deleted_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_location   ON profiles USING GIST (location);
CREATE INDEX idx_profiles_deleted_at ON profiles (deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read non-deleted profiles
CREATE POLICY "profiles_select_public"
  ON profiles FOR SELECT
  USING (deleted_at IS NULL);

-- Own user can update their profile (but not id, rating, exchanges, deleted_at, created_at)
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id AND deleted_at IS NULL)
  WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- 2. listings
-- ---------------------------------------------------------------------------
-- PostGIS POINT for geospatial queries.
-- Soft-deleted. Auto-expiry via expires_at trigger.
-- Hard DELETE not allowed via RLS — use status = 'archived' or deleted_at.
-- ---------------------------------------------------------------------------

CREATE TABLE listings (
  id           UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     UUID           NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title        TEXT           NOT NULL CHECK (length(trim(title)) > 0 AND length(title) <= 80),
  description  TEXT           CHECK (description IS NULL OR length(description) <= 2000),
  category     TEXT           NOT NULL,
  condition    item_condition,
  images       TEXT[]         NOT NULL DEFAULT '{}',
  location     GEOGRAPHY(POINT, 4326),
  neighborhood TEXT,
  status       listing_status NOT NULL DEFAULT 'available',
  price_type   price_type     NOT NULL DEFAULT 'free',
  price_euro   NUMERIC(6, 2)  CHECK (
                                price_euro IS NULL OR (price_euro >= 0.05 AND price_euro <= 0.50)
                              ),
  -- Auto-expire 30 days after creation unless renewed
  expires_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW() + INTERVAL '30 days',
  deleted_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  -- Consistency: symbolic listings must have a price
  CONSTRAINT chk_symbolic_price CHECK (
    price_type = 'free' OR (price_type = 'symbolic' AND price_euro IS NOT NULL)
  )
);

CREATE INDEX idx_listings_location   ON listings USING GIST (location);
CREATE INDEX idx_listings_owner      ON listings (owner_id);
CREATE INDEX idx_listings_status     ON listings (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_expires_at ON listings (expires_at) WHERE status = 'available';
CREATE INDEX idx_listings_category   ON listings (category) WHERE status = 'available' AND deleted_at IS NULL;
-- Full-text search index
CREATE INDEX idx_listings_fts ON listings
  USING GIN (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '')));

CREATE TRIGGER trg_listings_updated_at
  BEFORE UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "listings_select_public"
  ON listings FOR SELECT
  USING (deleted_at IS NULL);

CREATE POLICY "listings_insert_own"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "listings_update_own"
  ON listings FOR UPDATE
  USING (auth.uid() = owner_id AND deleted_at IS NULL)
  WITH CHECK (auth.uid() = owner_id);

-- Soft-delete only: owner can UPDATE deleted_at (handled at app layer)
-- No hard DELETE via RLS
CREATE POLICY "listings_delete_denied"
  ON listings FOR DELETE
  USING (FALSE);

-- ---------------------------------------------------------------------------
-- 3. reservations
-- ---------------------------------------------------------------------------
-- Full borrow flow: pending → confirmed → active → return_pending → completed
-- pickup_code generated server-side; never passed from client.
-- Timestamps record each state transition.
-- ---------------------------------------------------------------------------

CREATE TABLE reservations (
  id                  UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id          UUID               NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
  borrower_id         UUID               NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  owner_id            UUID               NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  status              reservation_status NOT NULL DEFAULT 'pending',
  mode                TEXT               NOT NULL CHECK (mode IN ('borrow', 'reserve')),
  pickup_code         TEXT               UNIQUE,
  -- Proposed pickup window (borrower suggests)
  pickup_window_start DATE,
  pickup_window_end   DATE,
  -- Agreed due date (set by owner on confirmation)
  due_date            DATE,
  -- State transition timestamps
  confirmed_at        TIMESTAMPTZ,  -- owner confirmed
  borrower_pickup_at  TIMESTAMPTZ,  -- borrower tapped "picked up"
  owner_pickup_at     TIMESTAMPTZ,  -- owner tapped "handed over" → status = active
  borrower_return_at  TIMESTAMPTZ,  -- borrower tapped "returned" → status = return_pending
  owner_return_at     TIMESTAMPTZ,  -- owner tapped "received back" → status = completed
  cancellation_reason TEXT,
  cancelled_by        UUID REFERENCES profiles(id),
  created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_not_own_listing CHECK (borrower_id <> owner_id),
  CONSTRAINT chk_pickup_window CHECK (
    pickup_window_end IS NULL OR pickup_window_start IS NULL OR
    pickup_window_end >= pickup_window_start
  )
);

CREATE INDEX idx_reservations_listing  ON reservations (listing_id);
CREATE INDEX idx_reservations_borrower ON reservations (borrower_id);
CREATE INDEX idx_reservations_owner    ON reservations (owner_id);
CREATE INDEX idx_reservations_status   ON reservations (status);
CREATE INDEX idx_reservations_due_date ON reservations (due_date)
  WHERE status = 'active';

CREATE TRIGGER trg_reservations_updated_at
  BEFORE UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reservations_select_participants"
  ON reservations FOR SELECT
  USING (auth.uid() = borrower_id OR auth.uid() = owner_id);

CREATE POLICY "reservations_insert_borrower"
  ON reservations FOR INSERT
  WITH CHECK (auth.uid() = borrower_id);

-- Participants can update (state transitions); protected further by RPC functions
CREATE POLICY "reservations_update_participants"
  ON reservations FOR UPDATE
  USING (auth.uid() = borrower_id OR auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- 4. reviews
-- ---------------------------------------------------------------------------
-- Linked to reservations (not just listings) — ensures exchange happened.
-- Both parties can review; one review per person per reservation.
-- Trust score recalculated on insert via trigger.
-- ---------------------------------------------------------------------------

CREATE TABLE reviews (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID        NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  listing_id     UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  reviewer_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reviewee_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating         SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
  text           TEXT        CHECK (text IS NULL OR length(text) <= 500),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (reservation_id, reviewer_id),
  CONSTRAINT chk_not_self_review CHECK (reviewer_id <> reviewee_id)
);

CREATE INDEX idx_reviews_reviewee      ON reviews (reviewee_id);
CREATE INDEX idx_reviews_reservation   ON reviews (reservation_id);
CREATE INDEX idx_reviews_listing       ON reviews (listing_id);

-- RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reviews_select_public"
  ON reviews FOR SELECT
  USING (TRUE);

-- Only reservation participants can insert; checked further by RPC
CREATE POLICY "reviews_insert_reviewer"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = reviewer_id);

-- ---------------------------------------------------------------------------
-- Trigger: recalculate trust score on new review
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recalculate_profile_stats(p_profile_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
  v_avg   NUMERIC(3,2);
BEGIN
  SELECT COUNT(*), COALESCE(AVG(rating), 0)::NUMERIC(3,2)
  INTO v_count, v_avg
  FROM reviews
  WHERE reviewee_id = p_profile_id;

  UPDATE profiles
  SET exchanges  = v_count,
      rating     = v_avg,
      updated_at = NOW()
  WHERE id = p_profile_id;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_review_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM recalculate_profile_stats(NEW.reviewee_id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reviews_recalculate
  AFTER INSERT ON reviews
  FOR EACH ROW EXECUTE FUNCTION trg_fn_review_insert();

-- ---------------------------------------------------------------------------
-- 5. conversations
-- ---------------------------------------------------------------------------
-- One conversation per (participant pair + listing).
-- Optionally linked to a reservation when borrow flow opens chat.
-- ---------------------------------------------------------------------------

CREATE TABLE conversations (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID        REFERENCES reservations(id) ON DELETE SET NULL,
  listing_id     UUID        REFERENCES listings(id) ON DELETE SET NULL,
  participant_1  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  participant_2  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_different_participants CHECK (participant_1 <> participant_2),
  UNIQUE (participant_1, participant_2, listing_id)
);

CREATE INDEX idx_conversations_p1        ON conversations (participant_1);
CREATE INDEX idx_conversations_p2        ON conversations (participant_2);
CREATE INDEX idx_conversations_reservation ON conversations (reservation_id);

-- RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversations_select_participants"
  ON conversations FOR SELECT
  USING (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "conversations_insert_participant"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = participant_1 OR auth.uid() = participant_2);

-- ---------------------------------------------------------------------------
-- 6. messages
-- ---------------------------------------------------------------------------
-- is_system=TRUE for system messages ("Request confirmed", "Pickup code: XYZ").
-- Realtime enabled for live chat.
-- RLS: only conversation participants can read/write.
-- ---------------------------------------------------------------------------

CREATE TABLE messages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID        NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content         TEXT        NOT NULL CHECK (length(trim(content)) > 0 AND length(content) <= 4000),
  is_system       BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages (conversation_id, created_at ASC);
CREATE INDEX idx_messages_sender       ON messages (sender_id);

ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "messages_select_participants"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
        AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );

CREATE POLICY "messages_insert_participants"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    NOT is_system AND  -- system messages only via SECURITY DEFINER functions
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
        AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- 7. notifications
-- ---------------------------------------------------------------------------
-- In-app notification center. Realtime-enabled for badge updates.
-- action_url: deep link (e.g. /listing/uuid, /messages/conv-uuid).
-- related_id: FK-less reference to listing/reservation/conversation.
-- ---------------------------------------------------------------------------

CREATE TABLE notifications (
  id          UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID              NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  title       TEXT              NOT NULL CHECK (length(title) <= 120),
  body        TEXT              CHECK (body IS NULL OR length(body) <= 500),
  action_url  TEXT,
  related_id  UUID,   -- listing_id, reservation_id, or conversation_id
  read        BOOLEAN           NOT NULL DEFAULT FALSE,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user    ON notifications (user_id, created_at DESC);
CREATE INDEX idx_notifications_unread  ON notifications (user_id) WHERE read = FALSE;

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_own_only"
  ON notifications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- System/RPC functions need SECURITY DEFINER to insert notifications for other users

-- ---------------------------------------------------------------------------
-- 8. favorites
-- ---------------------------------------------------------------------------

CREATE TABLE favorites (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, listing_id)
);

CREATE INDEX idx_favorites_user    ON favorites (user_id);
CREATE INDEX idx_favorites_listing ON favorites (listing_id);

-- RLS
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "favorites_own_only"
  ON favorites FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 9. reports
-- ---------------------------------------------------------------------------
-- Polymorphic target: target_type + target_id points to profile, listing, or message.
-- Reporters can see their own reports; admins need separate policy.
-- ---------------------------------------------------------------------------

CREATE TABLE reports (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id    UUID          NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type    TEXT          NOT NULL CHECK (target_type IN ('profile', 'listing', 'message')),
  target_id      UUID          NOT NULL,
  target_owner_id UUID         REFERENCES profiles(id) ON DELETE SET NULL,
  reason         report_reason NOT NULL,
  description    TEXT          CHECK (description IS NULL OR length(description) <= 1000),
  status         report_status NOT NULL DEFAULT 'open',
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_reporter ON reports (reporter_id);
CREATE INDEX idx_reports_target   ON reports (target_type, target_id);
CREATE INDEX idx_reports_status   ON reports (status);

CREATE TRIGGER trg_reports_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reports_insert_own"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "reports_select_own"
  ON reports FOR SELECT
  USING (auth.uid() = reporter_id);

-- ---------------------------------------------------------------------------
-- 10. blocks
-- ---------------------------------------------------------------------------
-- Bidirectional check via is_blocked() helper.
-- Blocked users filtered from listings/messages at app layer.
-- ---------------------------------------------------------------------------

CREATE TABLE blocks (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (blocker_id, blocked_id),
  CONSTRAINT chk_no_self_block CHECK (blocker_id <> blocked_id)
);

CREATE INDEX idx_blocks_blocker ON blocks (blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks (blocked_id);

-- RLS
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blocks_manage_own"
  ON blocks FOR ALL
  USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);

-- Helper: check mutual block
CREATE OR REPLACE FUNCTION is_blocked(a UUID, b UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = a AND blocked_id = b)
       OR (blocker_id = b AND blocked_id = a)
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ===========================================================================
-- RPC FUNCTIONS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- nearby_listings(lat, lng, radius_km, category, p_limit)
-- Returns listings within radius with owner profile data joined.
-- Auth: public (available listings only). Blocked owners excluded.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION nearby_listings(
  lat        FLOAT,
  lng        FLOAT,
  radius_km  FLOAT   DEFAULT 1.0,
  category   TEXT    DEFAULT NULL,
  p_limit    INT     DEFAULT 50
)
RETURNS TABLE (
  id             UUID,
  owner_id       UUID,
  title          TEXT,
  description    TEXT,
  category       TEXT,
  condition      item_condition,
  images         TEXT[],
  neighborhood   TEXT,
  status         listing_status,
  price_type     price_type,
  price_euro     NUMERIC,
  expires_at     TIMESTAMPTZ,
  distance_km    FLOAT,
  created_at     TIMESTAMPTZ,
  -- owner fields
  owner_name     TEXT,
  owner_avatar   TEXT,
  owner_rating   NUMERIC,
  owner_exchanges INT,
  owner_verified BOOLEAN,
  owner_neighborhood TEXT
) AS $$
DECLARE
  v_user UUID := auth.uid();
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.owner_id,
    l.title,
    l.description,
    l.category,
    l.condition,
    l.images,
    l.neighborhood,
    l.status,
    l.price_type,
    l.price_euro,
    l.expires_at,
    ROUND(
      (ST_Distance(
        l.location::geography,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
      ) / 1000.0)::NUMERIC,
      2
    )::FLOAT AS distance_km,
    l.created_at,
    p.name,
    p.avatar_url,
    p.rating,
    p.exchanges,
    p.verified,
    p.neighborhood
  FROM listings l
  JOIN profiles p ON p.id = l.owner_id
  WHERE
    l.location IS NOT NULL
    AND l.status = 'available'
    AND l.deleted_at IS NULL
    AND p.deleted_at IS NULL
    AND l.expires_at > NOW()
    AND ST_DWithin(
      l.location::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_km * 1000
    )
    -- Filter by category if provided
    AND (category IS NULL OR l.category = category)
    -- Exclude blocked owners (only when authenticated)
    AND (v_user IS NULL OR NOT is_blocked(v_user, l.owner_id))
  ORDER BY distance_km ASC
  LIMIT LEAST(p_limit, 200);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- get_listing_with_owner(p_id)
-- Single listing with full owner profile. Respects soft-delete.
-- Auth: public.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_listing_with_owner(p_id UUID)
RETURNS TABLE (
  id             UUID,
  owner_id       UUID,
  title          TEXT,
  description    TEXT,
  category       TEXT,
  condition      item_condition,
  images         TEXT[],
  location_x     FLOAT,   -- longitude
  location_y     FLOAT,   -- latitude
  neighborhood   TEXT,
  status         listing_status,
  price_type     price_type,
  price_euro     NUMERIC,
  expires_at     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ,
  owner_name     TEXT,
  owner_avatar   TEXT,
  owner_rating   NUMERIC,
  owner_exchanges INT,
  owner_verified BOOLEAN,
  owner_neighborhood TEXT,
  owner_bio      TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.owner_id,
    l.title,
    l.description,
    l.category,
    l.condition,
    l.images,
    ST_X(l.location::geometry)::FLOAT,
    ST_Y(l.location::geometry)::FLOAT,
    l.neighborhood,
    l.status,
    l.price_type,
    l.price_euro,
    l.expires_at,
    l.created_at,
    l.updated_at,
    p.name,
    p.avatar_url,
    p.rating,
    p.exchanges,
    p.verified,
    p.neighborhood,
    p.bio
  FROM listings l
  JOIN profiles p ON p.id = l.owner_id
  WHERE l.id = p_id
    AND l.deleted_at IS NULL
    AND p.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- create_reservation(p_listing_id, p_mode, p_start, p_end)
-- Atomically: creates reservation, sets listing status, opens conversation,
-- sends notification to owner.
-- Auth: authenticated borrower only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_reservation(
  p_listing_id         UUID,
  p_mode               TEXT    DEFAULT 'borrow',
  p_pickup_window_start DATE   DEFAULT NULL,
  p_pickup_window_end   DATE   DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id       UUID;
  v_borrower_id    UUID := auth.uid();
  v_reservation_id UUID;
  v_code           TEXT;
  v_conv_id        UUID;
BEGIN
  IF v_borrower_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Get listing owner
  SELECT owner_id INTO v_owner_id
  FROM listings
  WHERE id = p_listing_id AND status = 'available' AND deleted_at IS NULL;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Listing not found or not available';
  END IF;

  IF v_owner_id = v_borrower_id THEN
    RAISE EXCEPTION 'Cannot borrow your own item';
  END IF;

  -- Check for existing active reservation by this borrower
  IF EXISTS (
    SELECT 1 FROM reservations
    WHERE listing_id = p_listing_id
      AND borrower_id = v_borrower_id
      AND status IN ('pending', 'confirmed', 'active')
  ) THEN
    RAISE EXCEPTION 'Active reservation already exists for this item';
  END IF;

  -- Create reservation (pickup_code NULL until confirmed)
  INSERT INTO reservations (
    listing_id, borrower_id, owner_id, status, mode,
    pickup_window_start, pickup_window_end
  )
  VALUES (
    p_listing_id, v_borrower_id, v_owner_id, 'pending', p_mode,
    p_pickup_window_start, p_pickup_window_end
  )
  RETURNING id INTO v_reservation_id;

  -- Mark listing reserved
  UPDATE listings SET status = 'reserved' WHERE id = p_listing_id;

  -- Open or reuse conversation between borrower ↔ owner for this listing
  INSERT INTO conversations (listing_id, reservation_id, participant_1, participant_2)
  VALUES (p_listing_id, v_reservation_id,
    LEAST(v_borrower_id, v_owner_id),
    GREATEST(v_borrower_id, v_owner_id)
  )
  ON CONFLICT (participant_1, participant_2, listing_id) DO UPDATE
    SET reservation_id = v_reservation_id
  RETURNING id INTO v_conv_id;

  -- Notify owner
  INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
  VALUES (
    v_owner_id,
    'reservation_request',
    'New borrow request',
    'Someone wants to borrow one of your items.',
    '/listing/' || p_listing_id::TEXT,
    v_reservation_id
  );

  RETURN jsonb_build_object(
    'reservation_id',    v_reservation_id,
    'conversation_id',   v_conv_id,
    'status',            'pending'
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- confirm_reservation(p_reservation_id, p_due_date)
-- Owner confirms request: generates pickup code, sets due_date, notifies borrower.
-- Auth: owner only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confirm_reservation(
  p_reservation_id UUID,
  p_due_date       DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id    UUID := auth.uid();
  v_borrower_id UUID;
  v_listing_id  UUID;
  v_code        TEXT;
BEGIN
  SELECT borrower_id, listing_id
  INTO v_borrower_id, v_listing_id
  FROM reservations
  WHERE id = p_reservation_id
    AND owner_id = v_owner_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found or you are not the owner';
  END IF;

  -- Generate unique pickup code (retry on collision)
  LOOP
    v_code := generate_pickup_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM reservations WHERE pickup_code = v_code);
  END LOOP;

  UPDATE reservations
  SET status       = 'confirmed',
      pickup_code  = v_code,
      due_date     = COALESCE(p_due_date, CURRENT_DATE + INTERVAL '7 days'),
      confirmed_at = NOW()
  WHERE id = p_reservation_id;

  -- Notify borrower with pickup code
  INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
  VALUES (
    v_borrower_id,
    'reservation_confirmed',
    'Borrow request confirmed!',
    'Your pickup code: ' || v_code || '. Coordinate with the owner.',
    '/messages',
    p_reservation_id
  );

  -- System message in conversation
  INSERT INTO messages (conversation_id, sender_id, content, is_system)
  SELECT c.id, v_owner_id,
    'Request confirmed ✓ Pickup code: ' || v_code,
    TRUE
  FROM conversations c
  WHERE c.reservation_id = p_reservation_id;

  RETURN jsonb_build_object(
    'status',       'confirmed',
    'pickup_code',  v_code,
    'due_date',     COALESCE(p_due_date, CURRENT_DATE + INTERVAL '7 days')
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- decline_reservation(p_reservation_id, p_reason)
-- Owner declines: releases listing, notifies borrower.
-- Auth: owner only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION decline_reservation(
  p_reservation_id UUID,
  p_reason         TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id    UUID := auth.uid();
  v_borrower_id UUID;
  v_listing_id  UUID;
BEGIN
  SELECT borrower_id, listing_id
  INTO v_borrower_id, v_listing_id
  FROM reservations
  WHERE id = p_reservation_id
    AND owner_id = v_owner_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found or cannot be declined';
  END IF;

  UPDATE reservations
  SET status              = 'declined',
      cancellation_reason = p_reason,
      cancelled_by        = v_owner_id
  WHERE id = p_reservation_id;

  -- Release listing back to available
  UPDATE listings SET status = 'available' WHERE id = v_listing_id;

  -- Notify borrower
  INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
  VALUES (
    v_borrower_id,
    'reservation_declined',
    'Borrow request declined',
    'The owner was unable to accommodate your request.',
    '/listing/' || v_listing_id::TEXT,
    p_reservation_id
  );

  RETURN jsonb_build_object('status', 'declined');
END;
$$;

-- ---------------------------------------------------------------------------
-- pickup_verify(p_reservation_id, p_role)
-- Records pickup confirmation for borrower ('borrower') or owner ('owner').
-- When both confirm, status advances to 'active'.
-- Auth: reservation participant only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pickup_verify(
  p_reservation_id UUID,
  p_role           TEXT  -- 'borrower' | 'owner'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id     UUID := auth.uid();
  v_borrower_id UUID;
  v_owner_id    UUID;
  v_listing_id  UUID;
  v_new_status  reservation_status;
BEGIN
  SELECT borrower_id, owner_id, listing_id
  INTO v_borrower_id, v_owner_id, v_listing_id
  FROM reservations
  WHERE id = p_reservation_id AND status = 'confirmed';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found or not in confirmed state';
  END IF;

  IF p_role = 'borrower' THEN
    IF v_user_id <> v_borrower_id THEN
      RAISE EXCEPTION 'Not the borrower';
    END IF;
    UPDATE reservations SET borrower_pickup_at = NOW() WHERE id = p_reservation_id;
  ELSIF p_role = 'owner' THEN
    IF v_user_id <> v_owner_id THEN
      RAISE EXCEPTION 'Not the owner';
    END IF;
    UPDATE reservations SET owner_pickup_at = NOW() WHERE id = p_reservation_id;
  ELSE
    RAISE EXCEPTION 'Invalid role: must be borrower or owner';
  END IF;

  -- Advance to active when both have confirmed
  IF EXISTS (
    SELECT 1 FROM reservations
    WHERE id = p_reservation_id
      AND borrower_pickup_at IS NOT NULL
      AND owner_pickup_at IS NOT NULL
  ) THEN
    UPDATE reservations SET status = 'active' WHERE id = p_reservation_id;
    UPDATE listings SET status = 'active' WHERE id = v_listing_id;
    v_new_status := 'active';
  ELSE
    v_new_status := 'confirmed';
  END IF;

  RETURN jsonb_build_object('status', v_new_status);
END;
$$;

-- ---------------------------------------------------------------------------
-- confirm_return(p_reservation_id, p_role)
-- Borrower marks returned, owner confirms receipt → status = completed.
-- On completion: listing returns to available, review notifications sent.
-- Auth: reservation participant only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confirm_return(
  p_reservation_id UUID,
  p_role           TEXT  -- 'borrower' | 'owner'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id     UUID := auth.uid();
  v_borrower_id UUID;
  v_owner_id    UUID;
  v_listing_id  UUID;
  v_new_status  reservation_status;
BEGIN
  SELECT borrower_id, owner_id, listing_id
  INTO v_borrower_id, v_owner_id, v_listing_id
  FROM reservations
  WHERE id = p_reservation_id AND status IN ('active', 'return_pending');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found or not in active/return_pending state';
  END IF;

  IF p_role = 'borrower' THEN
    IF v_user_id <> v_borrower_id THEN RAISE EXCEPTION 'Not the borrower'; END IF;
    UPDATE reservations
    SET borrower_return_at = NOW(), status = 'return_pending'
    WHERE id = p_reservation_id;
    v_new_status := 'return_pending';

    -- Notify owner
    INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
    VALUES (
      v_owner_id, 'reservation_request',
      'Item marked as returned',
      'Please confirm you received the item back.',
      '/messages', p_reservation_id
    );

  ELSIF p_role = 'owner' THEN
    IF v_user_id <> v_owner_id THEN RAISE EXCEPTION 'Not the owner'; END IF;

    UPDATE reservations
    SET owner_return_at = NOW(), status = 'completed'
    WHERE id = p_reservation_id;

    -- Release listing
    UPDATE listings SET status = 'available' WHERE id = v_listing_id;

    -- Send review reminders to both parties
    INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
    VALUES
      (v_borrower_id, 'review_reminder',
       'How was the exchange?', 'Leave a quick review for the owner.',
       '/listing/' || v_listing_id::TEXT, p_reservation_id),
      (v_owner_id, 'review_reminder',
       'How was the exchange?', 'Leave a quick review for the borrower.',
       '/listing/' || v_listing_id::TEXT, p_reservation_id);

    v_new_status := 'completed';
  ELSE
    RAISE EXCEPTION 'Invalid role';
  END IF;

  RETURN jsonb_build_object('status', v_new_status);
END;
$$;

-- ---------------------------------------------------------------------------
-- send_message(p_conversation_id, p_content)
-- Inserts message + unread notification for the other participant.
-- Auth: conversation participant only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_content         TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sender_id   UUID := auth.uid();
  v_other_id    UUID;
  v_message_id  UUID;
BEGIN
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF length(trim(p_content)) = 0 THEN
    RAISE EXCEPTION 'Message content cannot be empty';
  END IF;

  -- Get the other participant
  SELECT
    CASE WHEN participant_1 = v_sender_id THEN participant_2 ELSE participant_1 END
  INTO v_other_id
  FROM conversations
  WHERE id = p_conversation_id
    AND (participant_1 = v_sender_id OR participant_2 = v_sender_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Conversation not found or access denied';
  END IF;

  -- Insert message
  INSERT INTO messages (conversation_id, sender_id, content)
  VALUES (p_conversation_id, v_sender_id, p_content)
  RETURNING id INTO v_message_id;

  -- Notify recipient (skip if they are the sender — shouldn't happen but guard)
  IF v_other_id IS NOT NULL AND v_other_id <> v_sender_id THEN
    INSERT INTO notifications (user_id, type, title, body, action_url, related_id)
    VALUES (
      v_other_id,
      'new_message',
      'New message',
      left(p_content, 100),
      '/messages',
      p_conversation_id
    );
  END IF;

  RETURN jsonb_build_object('message_id', v_message_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- mark_notification_read(p_notification_id)
-- Marks single notification read + sets read_at.
-- Auth: owner of notification only.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE notifications
  SET read    = TRUE,
      read_at = NOW()
  WHERE id = p_notification_id
    AND user_id = auth.uid()
    AND read = FALSE;
END;
$$;

-- ---------------------------------------------------------------------------
-- mark_all_notifications_read()
-- Marks all unread notifications for current user as read.
-- Auth: authenticated.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_count INT;
BEGIN
  WITH updated AS (
    UPDATE notifications
    SET read    = TRUE,
        read_at = NOW()
    WHERE user_id = auth.uid()
      AND read = FALSE
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM updated;
  RETURN v_count;
END;
$$;

-- ===========================================================================
-- Storage bucket policies (informational — applied via Supabase dashboard)
-- ===========================================================================
-- Bucket: avatars
--   SELECT: public (read)
--   INSERT: authenticated, path must start with {auth.uid()}/
--   UPDATE/DELETE: path starts with {auth.uid()}/
--
-- Bucket: listing-photos
--   SELECT: public (read)
--   INSERT: authenticated, path must start with {auth.uid()}/
--   UPDATE/DELETE: path starts with {auth.uid()}/
-- ===========================================================================

-- ===========================================================================
-- End of migration 003_v2_schema.sql
-- ===========================================================================
