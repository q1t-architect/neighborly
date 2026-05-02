// Auto-generated style Database types for Neighborly v2
// Based on: neighborly/docs/DATABASE.md
// Update this file when schema migrations change enums or columns.

export type ListingStatus = 'available' | 'reserved' | 'active' | 'paused' | 'archived' | 'given'
export type PriceType = 'free' | 'symbolic'
export type ItemCondition = 'excellent' | 'good' | 'fair'
export type ReservationStatus =
  | 'pending'
  | 'confirmed'
  | 'active'
  | 'return_pending'
  | 'completed'
  | 'declined'
  | 'cancelled'
export type NotificationType =
  | 'reservation_request'
  | 'reservation_confirmed'
  | 'reservation_declined'
  | 'reservation_cancelled'
  | 'new_message'
  | 'pickup_reminder'
  | 'return_due'
  | 'review_reminder'
  | 'listing_expiring'
  | 'system'
export type ReportReason =
  | 'spam'
  | 'inappropriate_content'
  | 'fraud'
  | 'harassment'
  | 'item_unavailable'
  | 'other'
export type ReportStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed'
export type ReportTargetType = 'profile' | 'listing' | 'message'

// ---------------------------------------------------------------------------
// Table Row types
// ---------------------------------------------------------------------------

export interface Profile {
  id: string
  name: string
  avatar_url: string | null
  neighborhood: string | null
  location: unknown | null // PostGIS GEOGRAPHY — use ST_AsGeoJSON on server
  bio: string | null
  rating: number
  exchanges: number
  verified: boolean
  deleted_at: string | null
  created_at: string
  updated_at: string
}

export interface Listing {
  id: string
  owner_id: string
  title: string
  description: string | null
  category: string
  condition: ItemCondition | null
  images: string[]
  location: unknown | null
  neighborhood: string | null
  status: ListingStatus
  price_type: PriceType
  price_euro: number | null
  expires_at: string
  deleted_at: string | null
  created_at: string
  updated_at: string
}

export interface Reservation {
  id: string
  listing_id: string
  borrower_id: string
  owner_id: string
  status: ReservationStatus
  mode: 'borrow' | 'reserve'
  pickup_code: string | null
  pickup_window_start: string | null
  pickup_window_end: string | null
  due_date: string | null
  confirmed_at: string | null
  borrower_pickup_at: string | null
  owner_pickup_at: string | null
  borrower_return_at: string | null
  owner_return_at: string | null
  cancellation_reason: string | null
  cancelled_by: string | null
  created_at: string
  updated_at: string
}

export interface Review {
  id: string
  reservation_id: string
  listing_id: string
  reviewer_id: string
  reviewee_id: string
  rating: number
  text: string | null
  created_at: string
}

export interface Conversation {
  id: string
  reservation_id: string | null
  listing_id: string | null
  participant_1: string
  participant_2: string
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  content: string
  is_system: boolean
  created_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: NotificationType
  title: string
  body: string | null
  action_url: string | null
  related_id: string | null
  read: boolean
  read_at: string | null
  created_at: string
}

export interface Favorite {
  id: string
  user_id: string
  listing_id: string
  created_at: string
}

export interface Report {
  id: string
  reporter_id: string
  target_type: ReportTargetType
  target_id: string
  target_owner_id: string | null
  reason: ReportReason
  description: string | null
  status: ReportStatus
  created_at: string
  updated_at: string
}

export interface Block {
  id: string
  blocker_id: string
  blocked_id: string
  created_at: string
}

// ---------------------------------------------------------------------------
// Database type (Supabase generic parameter)
// ---------------------------------------------------------------------------

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile
        Insert: Omit<Profile, 'rating' | 'exchanges' | 'verified' | 'deleted_at' | 'created_at' | 'updated_at'> &
          Partial<Pick<Profile, 'rating' | 'exchanges' | 'verified' | 'deleted_at'>>
        Update: Partial<Omit<Profile, 'id' | 'created_at'>>
      }
      listings: {
        Row: Listing
        Insert: Omit<Listing, 'id' | 'status' | 'expires_at' | 'deleted_at' | 'created_at' | 'updated_at'> &
          Partial<Pick<Listing, 'id' | 'status' | 'expires_at' | 'deleted_at'>>
        Update: Partial<Omit<Listing, 'id' | 'owner_id' | 'created_at'>>
      }
      reservations: {
        Row: Reservation
        Insert: Pick<Reservation, 'listing_id' | 'borrower_id' | 'owner_id' | 'mode'> &
          Partial<Pick<Reservation, 'id' | 'pickup_window_start' | 'pickup_window_end'>>
        Update: Partial<Omit<Reservation, 'id' | 'listing_id' | 'borrower_id' | 'owner_id' | 'created_at'>>
      }
      reviews: {
        Row: Review
        Insert: Omit<Review, 'id' | 'created_at'> & Partial<Pick<Review, 'id'>>
        Update: never // Reviews are immutable
      }
      conversations: {
        Row: Conversation
        Insert: Omit<Conversation, 'id' | 'created_at'> & Partial<Pick<Conversation, 'id'>>
        Update: never
      }
      messages: {
        Row: Message
        Insert: Pick<Message, 'conversation_id' | 'sender_id' | 'content'> &
          Partial<Pick<Message, 'id' | 'is_system'>>
        Update: never // Messages are immutable
      }
      notifications: {
        Row: Notification
        Insert: Pick<Notification, 'user_id' | 'type' | 'title'> &
          Partial<Pick<Notification, 'id' | 'body' | 'action_url' | 'related_id'>>
        Update: Pick<Notification, 'read' | 'read_at'>
      }
      favorites: {
        Row: Favorite
        Insert: Pick<Favorite, 'user_id' | 'listing_id'> & Partial<Pick<Favorite, 'id'>>
        Update: never
      }
      reports: {
        Row: Report
        Insert: Pick<Report, 'reporter_id' | 'target_type' | 'target_id' | 'reason'> &
          Partial<Pick<Report, 'id' | 'description' | 'target_owner_id'>>
        Update: Pick<Report, 'status'>
      }
      blocks: {
        Row: Block
        Insert: Pick<Block, 'blocker_id' | 'blocked_id'> & Partial<Pick<Block, 'id'>>
        Update: never
      }
    }
    Views: Record<string, never>
    Functions: {
      nearby_listings: {
        Args: {
          lat: number
          lng: number
          radius_km: number
          category?: string
          limit_n?: number
        }
        Returns: Array<{
          id: string
          title: string
          category: string
          status: ListingStatus
          price_type: PriceType
          neighborhood: string | null
          images: string[]
          owner_id: string
          distance_km: number
          lat: number
          lng: number
        }>
      }
      create_reservation: {
        Args: {
          p_listing_id: string
          p_pickup_window_start: string
          p_pickup_window_end: string
          p_mode: 'borrow' | 'reserve'
        }
        Returns: string // reservation_id
      }
      confirm_reservation: {
        Args: { p_reservation_id: string; p_due_date: string }
        Returns: void
      }
      decline_reservation: {
        Args: { p_reservation_id: string }
        Returns: void
      }
      cancel_reservation: {
        Args: { p_reservation_id: string; p_reason?: string }
        Returns: void
      }
      is_blocked: {
        Args: { a: string; b: string }
        Returns: boolean
      }
      recalculate_profile_stats: {
        Args: { p_profile_id: string }
        Returns: void
      }
    }
    Enums: {
      listing_status: ListingStatus
      price_type: PriceType
      item_condition: ItemCondition
      reservation_status: ReservationStatus
      notification_type: NotificationType
      report_reason: ReportReason
      report_status: ReportStatus
    }
  }
}

// ---------------------------------------------------------------------------
// Convenience helpers
// ---------------------------------------------------------------------------

/** Extract Row type for a table */
export type TableRow<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']

/** Extract Insert type for a table */
export type TableInsert<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']
