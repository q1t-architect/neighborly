# Neighborly — Deployment Guide

> **Status:** Ready for setup  
> **Date:** 2026-05-02  
> **Repo:** `q1t-architect/neighborly`  
> **Hosting:** Vercel (SSR — Node.js runtime, NOT static export)

---

## Overview

Deployment pipeline:

```
Local → GitHub (q1t-architect/neighborly) → Vercel (auto-deploy on push to main)
                                         ↗
                              GitHub Actions CI (lint + typecheck + build)
```

---

## Part 1: GitHub Repository

### 1.1 Create Repository

1. Go to [github.com/q1t-architect](https://github.com/q1t-architect)
2. Click **New repository**
3. Settings:
   - **Name:** `neighborly`
   - **Visibility:** Private (until launch)
   - **Initialize:** No (we push existing code)
4. Click **Create repository**

### 1.2 Add Deploy Key (SSH)

Generate a dedicated key for CI/CD:

```bash
ssh-keygen -t ed25519 -C "neighborly-deploy" -f ~/.ssh/neighborly_deploy -N ""
```

This creates two files:
- `~/.ssh/neighborly_deploy` — private key (goes into GitHub Secrets)
- `~/.ssh/neighborly_deploy.pub` — public key (goes into GitHub repo deploy key)

**Add public key to GitHub:**
1. Repo Settings → **Deploy keys** → Add deploy key
2. Title: `neighborly-deploy`
3. Key: paste contents of `neighborly_deploy.pub`
4. Allow write access: ✅ (needed for Vercel deploy hooks)

**Add private key to GitHub Actions Secrets:**
1. Repo Settings → **Secrets and variables** → Actions
2. New secret: `SSH_PRIVATE_KEY` = contents of `neighborly_deploy`

### 1.3 Initial Push

```bash
cd /path/to/neighborly

git init
git add .
git commit -m "feat: initial scaffold — Next.js 15 + Supabase + Mapbox"
git branch -M main
git remote add origin git@github.com:q1t-architect/neighborly.git
git push -u origin main
```

---

## Part 2: Vercel Setup

### 2.1 Create Vercel Project

Option A — Vercel CLI (recommended):
```bash
npm i -g vercel
vercel login
cd /path/to/neighborly
vercel link
# Choose: q1t-architect org, project name: neighborly
```

Option B — Vercel Dashboard:
1. Go to [vercel.com/new](https://vercel.com/new)
2. Select **Import Git Repository**
3. Connect GitHub → select `q1t-architect/neighborly`
4. Framework Preset: **Next.js** (auto-detected)
5. Root directory: `.` (repo root)

### 2.2 Framework Configuration

In Vercel project Settings → General:

| Setting | Value |
|---------|-------|
| Framework Preset | Next.js |
| Build Command | `npm run build` |
| Output Directory | `.next` |
| Install Command | `npm ci` |
| Node.js Version | 22.x |

**Do NOT** set `output: "export"` in `next.config.ts` — we use SSR (Server Components require Node.js runtime).

### 2.3 Environment Variables

In Vercel project Settings → **Environment Variables**:

Add all four for **Production**, **Preview**, and **Development**:

| Name | Value | Environments |
|------|-------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://your-project.supabase.co` | All |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJhbGci...` (anon key from Supabase) | All |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | `pk.eyJ1...` (public token) | All |
| `NEXT_PUBLIC_APP_URL` | `https://neighborly.vercel.app` (Production) | Production |
| `NEXT_PUBLIC_APP_URL` | `https://neighborly-git-develop-q1t.vercel.app` | Preview |
| `NEXT_PUBLIC_APP_URL` | `http://localhost:3000` | Development |

**Where to get values:**
- Supabase URL + Anon Key: [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → API
- Mapbox Token: [Mapbox Account](https://account.mapbox.com) → Access Tokens → Create a new public token

### 2.4 Deploy Region

In `vercel.json` (already configured):
```json
"regions": ["mad1"]
```

Madrid region (`mad1`) minimizes latency for the target audience.

### 2.5 First Deploy

After env vars are set:
```bash
vercel --prod
```

Or: any push to `main` triggers auto-deploy.

Expected result: Vercel build succeeds, hello-world page is live at `https://neighborly.vercel.app`.

---

## Part 3: GitHub Actions CI

The workflow at `.github/workflows/ci.yml` runs on every push:

1. **lint-and-typecheck** — ESLint + TypeScript + Prettier check
2. **build** — `npm run build` with real env vars injected from secrets

### Required GitHub Secrets for CI

| Secret | Description |
|--------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | Mapbox public token |

Set at: Repo Settings → Secrets and variables → Actions → New repository secret.

---

## Part 4: Supabase Configuration

### 4.1 Supabase Auth Settings

In [Supabase Dashboard](https://supabase.com/dashboard) → Auth → URL Configuration:

| Setting | Value |
|---------|-------|
| Site URL | `https://neighborly.vercel.app` |
| Redirect URLs | `https://neighborly.vercel.app/**`, `http://localhost:3000/**` |

### 4.2 Auth Providers

Enable in Auth → Providers:
- **Email** — ✅ Enable email confirmations
- **Google** (optional, Phase 3)

### 4.3 Storage Buckets

Create two buckets in Storage:

| Bucket | Public | Max file size | Allowed MIME types |
|--------|--------|---------------|-------------------|
| `avatars` | ✅ Public | 5 MB | `image/*` |
| `listing-photos` | ✅ Public | 10 MB | `image/*` |

RLS policies are in `supabase/migrations/003_v2_schema.sql`.

### 4.4 Run Migrations

```bash
# Option A: Supabase CLI
supabase link --project-ref your-project-ref
supabase db push

# Option B: Manual (psql)
psql postgres://postgres:password@db.your-project.supabase.co:5432/postgres \
  < supabase/migrations/003_v2_schema.sql
```

---

## Deployment Checklist

Before considering deployment production-ready:

### Repository
- [ ] `q1t-architect/neighborly` repo created on GitHub
- [ ] Deploy key added (public to repo, private to Secrets)
- [ ] Initial commit pushed to `main`
- [ ] GitHub Actions CI passes (green checkmark on main)

### Vercel
- [ ] Vercel project created, linked to GitHub repo
- [ ] Framework: Next.js (auto-detected or set manually)
- [ ] All 4 env vars set for Production
- [ ] First deploy successful — hello-world page live
- [ ] Custom domain configured (when ready)

### Supabase
- [ ] Auth redirect URLs updated (add production URL)
- [ ] Storage buckets created with RLS
- [ ] Migrations applied to production DB
- [ ] PostGIS extension enabled (`CREATE EXTENSION postgis;`)

### DNS / Domain (Phase 3)
- [ ] Domain purchased (e.g., `neighborly.es` or `neighborly.app`)
- [ ] CNAME pointing to Vercel
- [ ] Vercel domain verified
- [ ] `NEXT_PUBLIC_APP_URL` updated to real domain
- [ ] Supabase redirect URLs updated with real domain

---

## Local Development Setup

```bash
# 1. Clone
git clone git@github.com:q1t-architect/neighborly.git
cd neighborly

# 2. Install
npm install

# 3. Env
cp .env.local.example .env.local
# Fill in Supabase URL, anon key, Mapbox token

# 4. Dev server
npm run dev
# → http://localhost:3000

# 5. Before committing
npm run lint
npm run typecheck
npm run format:check
```

---

## Branch Strategy

| Branch | Purpose | Deploy Target |
|--------|---------|--------------|
| `main` | Production-ready code | Vercel Production |
| `develop` | Integration branch | Vercel Preview |
| `feature/*` | Feature development | Vercel Preview (PR) |
| `fix/*` | Bug fixes | Vercel Preview (PR) |

**Rule:** No direct commits to `main`. All changes via PR from `develop` or `feature/*`.

---

*End of Deployment Guide. Questions → task board comment.*
