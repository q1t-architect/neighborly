# Neighborly

> Hyperlocal borrow/give marketplace for Madrid neighborhoods.

Built with Next.js 15 (App Router) + React 19 + Supabase + Mapbox GL + Framer Motion.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Next.js 15 (App Router) |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS v3 |
| Animation | Framer Motion |
| Database | Supabase (PostgreSQL + PostGIS) |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Realtime | Supabase Realtime |
| Maps | Mapbox GL / react-map-gl |
| Hosting | Vercel (SSR — no static export) |

## Getting Started

### Prerequisites

- Node.js 22+
- A Supabase project
- A Mapbox account

### Setup

1. **Clone the repo**
   ```bash
   git clone git@github.com:q1t-architect/neighborly.git
   cd neighborly
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.local.example .env.local
   # Fill in your values — see .env.local.example for descriptions
   ```

4. **Run database migrations**
   ```bash
   supabase db push
   # or apply manually: psql < supabase/migrations/003_v2_schema.sql
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000).

### Environment Variables

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon/public key |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | Mapbox public access token |
| `NEXT_PUBLIC_APP_URL` | Full URL of the app (no trailing slash) |

See `.env.local.example` for the full template.

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for Architecture Decision Records.

Key rules:
- **Server Components by default** — `page.tsx`, `layout.tsx` are Server Components
- **`*.server.ts`** — server-only modules. Never import from Client Components.
- **`*.client.ts`** — client-only helpers. Never import in Server Components.
- **Server Actions for all writes** — no Route Handlers for CRUD.
- **PostGIS RPC** — always use `nearby_listings()`, never raw SELECT with distance.

## Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start dev server |
| `npm run build` | Production build |
| `npm run lint` | Run ESLint |
| `npm run typecheck` | TypeScript check (no emit) |
| `npm run format` | Format with Prettier |
| `npm run format:check` | Check Prettier formatting |
# Deploy trigger 2026-05-02T23:24:52Z
