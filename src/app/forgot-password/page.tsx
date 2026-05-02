import type { Metadata } from 'next'
import { ForgotPasswordForm } from './ForgotPasswordForm'

export const metadata: Metadata = {
  title: 'Reset password — Neighborly',
}

export default function ForgotPasswordPage() {
  return (
    <main>
      <h1>Reset your password</h1>
      <p>Enter your email and we&apos;ll send you a reset link.</p>
      <ForgotPasswordForm />
    </main>
  )
}
