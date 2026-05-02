'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'

export function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirectTo') ?? '/'

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const supabase = createClient()
    const { error } = await supabase.auth.signInWithPassword({ email, password })

    if (error) {
      setError(
        error.message === 'Email not confirmed'
          ? 'Please confirm your email before signing in.'
          : error.message === 'Invalid login credentials'
          ? 'Invalid email or password.'
          : error.message
      )
      setLoading(false)
      return
    }

    router.push(redirectTo)
    router.refresh()
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="email"
          disabled={loading}
          placeholder="you@example.com"
        />
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          autoComplete="current-password"
          disabled={loading}
          placeholder="••••••••"
        />
      </div>

      {error && (
        <p role="alert" aria-live="polite">
          {error}
        </p>
      )}

      <div>
        <Link href="/forgot-password">Forgot password?</Link>
      </div>

      <button type="submit" disabled={loading || !email || !password}>
        {loading ? 'Signing in…' : 'Sign in'}
      </button>

      <p>
        Don&apos;t have an account?{' '}
        <Link href="/signup">Create one</Link>
      </p>
    </form>
  )
}
