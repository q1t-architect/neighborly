// Login page — Server Component
// Auth check is handled by middleware; this page is only reached by unauthenticated users.

import { Suspense } from 'react'
import type { Metadata } from 'next'
import { LoginForm } from './LoginForm'

export const metadata: Metadata = {
  title: 'Sign in — Neighborly',
}

export default function LoginPage() {
  return (
    <main>
      <h1>Welcome back</h1>
      <p>Sign in to borrow and lend with your neighbors.</p>

      {/* Suspense required: LoginForm uses useSearchParams() */}
      <Suspense fallback={null}>
        <LoginForm />
      </Suspense>
    </main>
  )
}
