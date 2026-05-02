import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Routes that require authentication
const PROTECTED_ROUTES = [
  '/profile',
  '/listing/new',
  '/messages',
  '/notifications',
]

// Routes only for unauthenticated users (redirect away if already logged in)
const AUTH_ROUTES = [
  '/login',
  '/signup',
  '/forgot-password',
]

function isProtectedRoute(pathname: string): boolean {
  if (PROTECTED_ROUTES.some((r) => pathname.startsWith(r))) return true
  // /listing/[id]/edit
  if (/^\/listing\/[^/]+\/edit(\/|$)/.test(pathname)) return true
  return false
}

function isAuthRoute(pathname: string): boolean {
  // /auth/confirm is not an auth route — it must be accessible without session
  return AUTH_ROUTES.some((r) => pathname.startsWith(r))
}

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          // Write new cookies back to both the request (for future middleware)
          // and the response (to set headers for the browser)
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Always use getUser() — not getSession().
  // getSession() reads from cookie without server-side validation and can be forged.
  // getUser() validates the JWT with Supabase Auth on each call.
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // Redirect unauthenticated users away from protected routes
  if (!user && isProtectedRoute(pathname)) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirectTo', pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Redirect authenticated users away from auth routes
  if (user && isAuthRoute(pathname)) {
    return NextResponse.redirect(new URL('/', request.url))
  }

  // Always return supabaseResponse (not a new NextResponse) so cookies are preserved
  return supabaseResponse
}

export const config = {
  matcher: [
    /*
     * Match all request paths EXCEPT:
     * - _next/static (static files)
     * - _next/image (image optimization)
     * - favicon.ico
     * - public image formats
     */
    '/((?!_next/static|_next/image|favicon\\.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
