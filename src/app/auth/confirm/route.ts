// /auth/confirm — PKCE code exchange route handler
//
// Supabase sends confirmation emails with a link to:
//   {siteUrl}/auth/confirm?code=...&next=/...
//
// This handler exchanges the one-time code for a session cookie,
// then redirects the user to their destination.

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import type { Database } from '@/lib/supabase/types'

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)

  const code = searchParams.get('code')
  const type = searchParams.get('type') // 'signup' | 'recovery' | 'invite'
  const next = searchParams.get('next') ?? '/'

  // Missing code — show error
  if (!code) {
    return NextResponse.redirect(
      `${origin}/auth/error?message=missing_confirmation_code`
    )
  }

  const cookieStore = await cookies()

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        },
      },
    }
  )

  const { error } = await supabase.auth.exchangeCodeForSession(code)

  if (error) {
    console.error('[auth/confirm] Code exchange failed:', error.message)
    return NextResponse.redirect(
      `${origin}/auth/error?message=${encodeURIComponent(error.message)}`
    )
  }

  // Password reset flow — redirect to update-password page
  if (type === 'recovery') {
    return NextResponse.redirect(`${origin}/auth/update-password`)
  }

  // Signup flow — check if onboarding is needed
  if (type === 'signup') {
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (user) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('neighborhood')
        .eq('id', user.id)
        .single()

      // If no neighborhood set, send to onboarding
      if (!profile?.neighborhood) {
        return NextResponse.redirect(`${origin}/onboarding`)
      }
    }
  }

  // Default: redirect to intended destination or home
  return NextResponse.redirect(`${origin}${next}`)
}
