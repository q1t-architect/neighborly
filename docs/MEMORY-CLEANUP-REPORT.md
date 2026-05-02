# Memory Cleanup Report — Neighborly lil-peep-opal Archive

> **Date:** 2026-05-02  
> **Agent:** Spark  
> **Status:** Partially complete — memory files require Atlas (team lead) access

---

## 1. What Was Cleaned (Personal Workspace)

### Files Flagged for Removal (blocked by safety policy on `.goclaw/` paths):
- `lil-peep/` — Entire old project codebase directory in personal workspace
- `run_migration.mjs` — Neighborly-specific Supabase migration runner (contains old Supabase URL + anon key)
- `test_auth.mjs`, `test_auth2.mjs`, `test_auth3.mjs` — Old auth test placeholders

**Note:** File deletion via `rm`/`exec` is blocked by safety policy for `.goclaw/` paths. Atlas can remove these via direct filesystem access.

---

## 2. What Requires Atlas to Clean (Read-Only Memory Files)

Memory files (`memory/*.md`) are **read-only for team members**. Only team lead can edit. The following files contain Neighborly/lil-peep-opal references that must be purged:

### Priority 1 — Full File Purge (100% old project content)

| File | Status | Action |
|------|--------|--------|
| `memory/2026-05-02-project-freeze.md` | ⚠️ Empty but exists | Delete or archive |
| `memory/2026-04-29-lil-peep-phase2.md` | ⚠️ Empty but exists | Delete or archive |

### Priority 2 — Section Removal Required

| File | Lines | Content to Remove |
|------|-------|-------------------|
| `memory/2026-04-28.md` | ~86–114 (if present) | "Neighborly MVP — Project Brief" section |
| `memory/2026-04-28.md` | ~117–128 (if present) | "lil-peep Project — New Repo Setup" section |
| `memory/2026-04-29.md` | ~26–109 | Phase 2.3 Listings CRUD, build bugs, architecture notes |
| `memory/2026-04-30.md` | ~1–40 | "lil-peep (Neighborly MVP) — Final Status" |
| `memory/2026-04-30.md` | ~42–76 | "Neighborly Mock Removal — Phase 1 COMPLETE" |
| `memory/2026-04-30.md` | ~78–115 | "Session 3 — Mock Removal Restart" |

### Priority 3 — Auto-Extract Files (Scattered References)

| File | Content to Scrub |
|------|-----------------|
| `memory/2026-04-28-auto-extract.md` | `https://github.com/q1t-architect/lil-peep/settings` |
| `memory/2026-04-29-auto-extract.md` | `https://uitguktdrkhjpepkzrhe.supabase.co`, `https://github.com/q1t-architect/lil-peep`, `supabase/server`, `borrow/reserve`, `login/signup/forgot-password`, `create/edit/delete`, `MOCK_LISTINGS` |
| `memory/2026-04-30-auto-extract.md` | `Loading/Error/Toast`, `User/MOCK_LISTINGS/WISHLIST_TAGS` |

### Priority 4 — Episodic Memory

| ID | Content | Action |
|----|---------|--------|
| `019dea05-4a4a-736a-a510-bf91c56667de` | "systematically dissect the codebase... functional marketplace or hollow MVP" | Expunge or archive |

---

## 3. What Is Clean (No Neighborly References)

| File | Status |
|------|--------|
| `MEMORY.md` (main index) | ✅ Clean — focused on ATH Technologies project |
| `memory/2026-04-22.md` | ✅ Clean |
| `memory/2026-04-22-auto-extract.md` | ✅ Clean |
| `memory/2026-04-24.md` | ✅ Clean |
| `memory/2026-04-24-auto-extract.md` | ✅ Clean |
| `memory/2026-04-25.md` | ✅ Clean |
| `memory/2026-04-25-auto-extract.md` | ✅ Clean |
| `memory/2026-04-26.md` | ✅ Clean |
| `memory/2026-04-26-auto-extract.md` | ✅ Clean |
| `memory/2026-04-27.md` | ✅ Clean |
| `memory/2026-04-27-auto-extract.md` | ✅ Clean |
| `memory/2026-05-02-auto-extract.md` | ✅ Clean |

---

## 4. Knowledge That SHOULD Be Kept (Non-Project)

The following knowledge from the old project is **general skill** and should survive the purge:

- **Next.js 15 App Router patterns** — Server Components, Client Components boundaries
- **Supabase integration patterns** — Auth, RLS, Realtime, Storage, PostGIS
- **Mapbox GL + react-map-gl** — Map integration, clustering, geo-queries
- **Framer Motion animations** — Page transitions, modal animations, scroll triggers
- **Tailwind CSS glassmorphism** — `backdrop-blur`, `bg-white/60`, shadow utilities
- **i18n lightweight pattern** — Context-based locale switching without libraries
- **TypeScript strict practices** — No `any`, proper typing patterns
- **PWA manifest + service worker setup**
- **Lighthouse performance optimization**

---

## 5. Recommended Cleanup Script for Atlas

```bash
# 1. Delete empty/old project memory files
rm /home/wn/.goclaw/workspace/system/memory/2026-05-02-project-freeze.md
rm /home/wn/.goclaw/workspace/system/memory/2026-04-29-lil-peep-phase2.md

# 2. Delete old project files from personal workspace
rm -rf /home/wn/.goclaw/workspace/system/lil-peep/
rm /home/wn/.goclaw/workspace/system/run_migration.mjs
rm /home/wn/.goclaw/workspace/system/test_auth.mjs
rm /home/wn/.goclaw/workspace/system/test_auth2.mjs
rm /home/wn/.goclaw/workspace/system/test_auth3.mjs

# 3. Auto-extract files: either delete and let system regenerate,
#    or manually scrub the lil-peep references
# 4. Daily memory files: edit to remove Neighborly sections
```

---

## 6. Verification Checklist

- [ ] `memory_search` for "lil-peep" returns 0 results
- [ ] `memory_search` for "Neighborly" returns only new v2 content (if any)
- [ ] `memory_search` for "MOCK_LISTINGS" returns 0 results
- [ ] `memory_search` for "uitguktdrkhjpepkzrhe" (old Supabase ref) returns 0 results
- [ ] Personal workspace `lil-peep/` directory removed
- [ ] Old migration/test scripts removed
- [ ] General skills (Supabase, Mapbox, Next.js) still retrievable via memory_search

---

*Report generated by Spark. Memory file edits require Atlas (team lead) privileges.*
