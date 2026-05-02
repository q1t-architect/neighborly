'use client'

import { useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'

type State = 'form' | 'check-inbox'

export function SignupForm() {
  const [state, setState] = useState<State>('form')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const supabase = createClient()
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        // After email confirmation, redirect to /auth/confirm?type=signup
        emailRedirectTo: `${window.location.origin}/auth/confirm?type=signup`,
      },
    })

    if (error) {
      setError(
        error.message === 'User already registered'
          ? 'An account with this email already exists. Try signing in.'
          : error.message
      )
      setLoading(false)
      return
    }

    setState('check-inbox')
  }

  if (state === 'check-inbox') {
    return (
      <div role="status">
        <h2>Check your inbox</h2>
        <p>
          We sent a confirmation link to <strong>{email}</strong>.
          Click it to activate your account.
        </p>
        <p>
          Didn&apos;t receive it?{' '}
          <button
            type="button"
            onClick={() => setState('form')}
          >
            Try again
          </button>
        </p>
      </div>
    )
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
          autoComplete="new-password"
          disabled={loading}
          placeholder="At least 8 characters"
          minLength={8}
        />
        <span>Min 8 characters</span>
      </div>

      {error && (
        <p role="alert" aria-live="polite">
          {error}
        </p>
      )}

      <button type="submit" disabled={loading || !email || password.length < 8}>
        {loading ? 'Creating account…' : 'Create account'}
      </button>

      <p>
        Already have an account?{' '}
        <Link href="/login">Sign in</Link>
      </p>
    </form>
  )
}
