# Build log: ASCteam

Stack: Next.js 15.5 (App Router), React 19, TypeScript, Tailwind v4 mapped to design tokens. Code in `ascteam/`.
Data: fake in-memory layer (`ascteam/lib/data.ts`), same function names planned for Supabase. Resets on server restart.
Signed-in member: simulated (`CURRENT_MEMBER_ID = m-1`) until auth exists.

| ID | date | status | what is missing | harder than expected |
| --- | --- | --- | --- | --- |
| shell | 2026-11-18 | done | - | tokens prefixed `--token-*` to avoid name clash with Tailwind `--color-*` |
| S01 | 2026-11-18 | partial | sign-up, club creation, trial | no auth yet |
| S07 | 2026-11-18 | partial | grid view (day/week/month/season), event-type filter | list view only |
| S08 | 2026-11-18 | partial | edit/cancel event, event chat, votes | RSVP works, locked after start |
| S09 | 2026-11-18 | done | - | validation via redirect with `?error=`, no client JS |
| S10 | - | not started | threads, composer, recipient picker | - |
| S11 | 2026-11-18 | partial | profile drawer, privacy, file attach, export, import | list and search only |
| S14 | - | not started | stats view, history import | - |
| design | 2026-11-18 | partial | modal, toast, data table component, /design route | primitives in `app/components/ui.tsx` only |

## Feature matrix movement
See `features.csv` `clone` column. Counts after this build: yes 2, partial 4, no 18, skip 9.

## Known issues
- Browser console shows one 404 on load (not identified; likely `/favicon.ico`). Add `app/favicon.ico` or ignore.
- Date inputs use the server locale. Club timezone hard-coded `Europe/Paris` in `lib/format.ts`.
- Smoke test (`/tmp/claude-0/smoke.js`, not committed) passed on 390 px and 1440 px: calendar, RSVP toggle, event creation, members list. No horizontal scroll.

## Screenshots
`replica/clone-screens/S07.png`, `S08.png`, `S11.png` (desktop, full page). Clone only, not the original.
