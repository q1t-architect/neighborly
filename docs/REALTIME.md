# REALTIME.md — Realtime Subscription Design

> **Project:** Neighborly v2  
> **Author:** Kinetic  
> **Date:** 2026-05-02  
> **Status:** Draft — Phase 1 Design  
> **Scope:** Supabase Realtime channels, filters, client patterns

---

## Architecture Overview

Supabase Realtime uses PostgreSQL logical replication + WebSocket transport. All `postgres_changes` subscriptions respect RLS automatically — a user can only receive row events they are authorized to SELECT.

```
Client WebSocket
  ├── Channel: public:listings     → New available listings in area
  ├── Channel: private:messages:{conv_id}  → Chat messages
  └── Channel: private:notifications:{user_id} → User alerts
```

**Key constraint:** A single Supabase project supports one WebSocket connection per client. All channels multiplex over that connection. Clean up channels that are no longer needed.

---

## Channel 1: `public:listings`

**Purpose:** Notify all users when a new listing becomes available nearby.  
**Auth required:** No (public channel).  
**Filtering:** Client-side by neighborhood/radius (PostGIS filtering in Realtime is not available for MVP).

### Subscription Pattern

```typescript
const listingsChannel = supabase
  .channel('public:listings')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'listings',
      filter: 'status=eq.available',
    },
    (payload) => {
      const newListing = payload.new as Listing;
      // Client-side filter: only show if within user's radius
      if (isWithinRadius(newListing.location, userLocation, radiusKm)) {
        addListingToMap(newListing);
        showToast(`New item nearby: ${newListing.title}`);
      }
    }
  )
  .subscribe();
```

### Events Handled

| Event | Trigger | Action |
|-------|---------|--------|
| `INSERT` | New listing posted | Add pin to map, show toast |
| `UPDATE` | Status change (available → reserved) | Remove/grey-out pin |
| `DELETE` | Listing deleted | Remove pin |

```typescript
// Full event set
.on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'listings', filter: 'status=eq.available' }, onNewListing)
.on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'listings' }, onListingUpdated)
.on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'listings' }, onListingDeleted)
```

### Unsubscribe

```typescript
// On component unmount or user navigates away from map
await supabase.removeChannel(listingsChannel);
```

---

## Channel 2: `private:messages:{conv_id}`

**Purpose:** Real-time message delivery within a conversation.  
**Auth required:** Yes. RLS verifies the user is a participant in the conversation.  
**Isolation:** One channel per active conversation. Subscribe when user opens a chat, unsubscribe when they close it.

### Subscription Pattern

```typescript
function subscribeToConversation(convId: string) {
  const channel = supabase
    .channel(`private:messages:${convId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `conversation_id=eq.${convId}`,
      },
      (payload) => {
        const message = payload.new as Message;
        // Deduplicate: optimistic UI may have already added the message
        setMessages((prev) =>
          prev.some((m) => m.id === message.id) ? prev : [...prev, message]
        );
        scrollToBottom();
      }
    )
    .subscribe((status) => {
      if (status === 'CHANNEL_ERROR') {
        console.error(`Realtime error on conversation ${convId}`);
        // Fallback: poll every 5s
      }
    });

  return channel;
}
```

### Inbox-Level Channel (Sidebar Updates)

Separate channel for updating conversation list without opening each chat:

```typescript
// Loaded once when MessagesPage mounts
const inboxChannel = supabase
  .channel('private:inbox')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'messages' },
    (payload) => {
      const msg = payload.new as Message;
      // Client-side filter: only update if belongs to user's conversations
      if (!userConvIds.has(msg.conversation_id)) return;

      setConversations((prev) =>
        bubbleUp(
          prev.map((c) =>
            c.id !== msg.conversation_id
              ? c
              : {
                  ...c,
                  lastMessage: msg.content,
                  lastAt: 'just now',
                  // Don't increment unread if this is the active conversation
                  unread: activeConvId === msg.conversation_id ? c.unread : c.unread + 1,
                }
          ),
          msg.conversation_id
        )
      );
    }
  )
  .subscribe();
```

### Lifecycle

```typescript
// On open chat → subscribe
const chatChannel = subscribeToConversation(convId);

// On close chat / switch conversation
await supabase.removeChannel(chatChannel);

// On MessagesPage unmount → clean all channels
await supabase.removeChannel(inboxChannel);
await supabase.removeChannel(chatChannel);
```

### Security Verification

Supabase applies RLS to realtime subscriptions. A user subscribing to `conversation_id=eq.{X}` will receive NO events if they are not a participant of conversation X (the `messages_select` policy blocks it). No additional client-side auth check needed.

---

## Channel 3: `private:notifications:{user_id}`

**Purpose:** Push notification badge updates in real-time.  
**Auth required:** Yes. RLS ensures users only receive their own notifications.

### Subscription Pattern

```typescript
function subscribeToNotifications(userId: string) {
  return supabase
    .channel(`private:notifications:${userId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${userId}`,
      },
      (payload) => {
        const notification = payload.new as Notification;
        setUnreadCount((n) => n + 1);
        showNotificationToast(notification);
      }
    )
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${userId}`,
      },
      (payload) => {
        const updated = payload.new as Notification;
        // User marked notification as read
        if (updated.read) {
          setUnreadCount((n) => Math.max(0, n - 1));
        }
      }
    )
    .subscribe();
}
```

### Lifecycle

```typescript
// Subscribe once on AppShell mount (after auth resolves)
const notifChannel = subscribeToNotifications(user.id);

// Unsubscribe on logout or app close
supabase.auth.onAuthStateChange((event) => {
  if (event === 'SIGNED_OUT') {
    supabase.removeChannel(notifChannel);
  }
});
```

---

## Connection Management

### Channel Count Limits

Supabase free tier: **200 concurrent realtime connections** per project. Each client opens one WebSocket with multiple channels multiplexed. Budget per active user session:

| Channel | Count | When Active |
|---------|-------|-------------|
| `public:listings` | 1 | Browse/map pages |
| `private:inbox` | 1 | Messages page |
| `private:messages:{id}` | 1 | Active conversation |
| `private:notifications:{id}` | 1 | Always (AppShell) |
| **Total** | **≤ 4** | Peak usage |

1,000 concurrent users × 4 channels = 4,000 channel subscriptions on 1,000 connections → within limits.

### Error Handling & Reconnection

```typescript
.subscribe((status, err) => {
  if (status === 'SUBSCRIBED') {
    console.log('Realtime connected');
  }
  if (status === 'CHANNEL_ERROR') {
    console.error('Realtime error:', err);
    // Implement exponential backoff reconnect
  }
  if (status === 'TIMED_OUT') {
    // Channel timed out — re-subscribe
  }
  if (status === 'CLOSED') {
    // Clean close — do nothing
  }
})
```

### Cleanup Pattern (React)

```typescript
useEffect(() => {
  const channel = supabase.channel('...')
    .on(...)
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}, [convId]); // Re-subscribe when conversation changes
```

---

## Realtime Security Matrix

| Channel | Table | Event | RLS Policy Applied | Result |
|---------|-------|-------|-------------------|--------|
| `public:listings` | listings | INSERT | `listings_select`: status=available | Public receives new available items only |
| `private:inbox` | messages | INSERT | `messages_select`: participant check | Non-participants receive nothing |
| `private:messages:{id}` | messages | INSERT | `messages_select`: participant check | Non-participants receive nothing |
| `private:notifications:{id}` | notifications | INSERT/UPDATE | `notifications_select`: user_id match | Users receive only their own |

**RLS applies automatically.** Client does not need to validate channel identity — Supabase enforces it at the database level.

---

## Realtime vs. Polling Decision Matrix

| Use Case | Approach | Rationale |
|----------|----------|-----------|
| New message in active chat | Realtime | < 500ms delivery requirement (PRD) |
| Unread notification badge | Realtime | Badge must update without refresh |
| New listing on map | Realtime | Delight feature, not critical path |
| Reservation status change | Polling (5s) OR trigger notification | Low frequency, notification covers it |
| User's own listing views/stats | On-demand | No realtime requirement |

---

*See SECURITY.md for RLS policies governing realtime access.*  
*See STORAGE.md for storage buckets and auth flow.*
