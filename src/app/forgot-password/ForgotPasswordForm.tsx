'use client'

import { useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'

type State = 'form' | 'sent'

export function ForgotPasswordForm() {
  const [state, setState] = useState<State>('form')
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const supabase = createClient()
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/confirm?type=recovery`,
    })

    // Always show the "sent" state — don't reveal if email exists
    if (error) {
      console.error('[forgot-password] Reset error:', error.message)
    }

    setState('sent')
    setLoading(false)
  }

  if (state === 'sent') {
    return (
      <div role="status">
        <h2>Check your inbox</h2>
        <p>
          If an account exists for <strong>{email}</strong>, you&apos;ll receive
          a password reset link shortly.
        </p>
        <Link href="/login">Back to sign in</Link>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">Email address</label>
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

      {error && (
        <p role="alert" aria-live="polite">
          {error}
        </p>
      )}

      <button type="submit" disabled={loading || !email}>
        {loading ? 'Sending…' : 'Send reset link'}
      </button>

      <Link href="/login">Back to sign in</Link>
    </form>
  )
}
