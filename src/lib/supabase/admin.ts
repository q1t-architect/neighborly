// Admin (service_role) Supabase client
// SERVER-ONLY — bypasses ALL RLS policies
// Use only in: admin Server Actions, Edge Functions, internal cron jobs
// NEVER import from Client Components or expose to browser

import { createClient as createSupabaseClient } from '@supabase/supabase-js'
import type { Database } from './types'

// Guard: hard fail at module load if accidentally included in browser bundle
if (typeof window !== 'undefined') {
  throw new Error(
    '[admin.ts] Admin Supabase client must never run in the browser. ' +
    'Check your import — this file is server-only.'
  )
}

let _adminClient: ReturnType<typeof createSupabaseClient<Database>> | null = null

/**
 * Returns a singleton service_role client.
 * Singleton is safe here because server-side modules are not shared between users.
 *
 * Usage:
 *   const admin = createAdminClient()
 *   await admin.from('profiles').update({ role: 'admin' }).eq('id', userId)
 */
export function createAdminClient() {
  if (_adminClient) return _adminClient

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!supabaseUrl) throw new Error('Missing env: NEXT_PUBLIC_SUPABASE_URL')
  if (!serviceRoleKey) throw new Error('Missing env: SUPABASE_SERVICE_ROLE_KEY')

  _adminClient = createSupabaseClient<Database>(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  return _adminClient
}
