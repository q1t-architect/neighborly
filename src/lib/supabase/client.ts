// Browser (Client Component) Supabase client
// Use in: "use client" components only
// Do NOT import in Server Components or Server Actions — use server.ts instead

import { createBrowserClient } from '@supabase/ssr'
import type { Database } from './types'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
