import type { Metadata } from 'next'
import { SignupForm } from './SignupForm'

export const metadata: Metadata = {
  title: 'Create account — Neighborly',
}

export default function SignupPage() {
  return (
    <main>
      <h1>Join Neighborly</h1>
      <p>Borrow and lend everyday items with people in your neighborhood.</p>
      <SignupForm />
    </main>
  )
}
