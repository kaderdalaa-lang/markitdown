# Architecture: ASCteam (a rebuild of SportEasy's core features)

Free app. No payments. Clean-room: built from `recon.md` and `features.csv`, not from SportEasy's code.

## Stack

| layer | choice | why |
| --- | --- | --- |
| web | Next.js (App Router) + TypeScript | one codebase, SSR for public pages, free on Vercel hobby |
| styling | Tailwind, tokens from replica-design (later) | fast, no lock-in |
| mobile | none in v1; PWA (installable web app) | native apps are out of v1 scope (features.csv, could) and cost money to ship |
| database | Postgres on Supabase (free tier) | RLS in the database, one place for access rules |
| auth | Supabase Auth (email link + password) | free, integrated with RLS (`auth.uid()`) |
| files | Supabase Storage (free tier, 1 GB) | member files and message attachments, same auth |
| email | Resend (free tier) | invitations and reminders; free tier is 100 emails/day, enough for a test club |
| jobs | Supabase `pg_cron` (free) | Vercel hobby cron runs only once a day; reminders need every 15 min |
| hosting | Vercel hobby | free, preview deploys per branch |
| payments | none | free app, decision 2026-11-18 |

Limits to know now:
- Supabase free projects pause after about one week without activity. Keep a weekly ping or accept a manual restart.
- Resend free: 100 emails/day. Reminder volume must stay under that.
- Vercel hobby: personal, non-commercial use only. Fine for a club's own use. Check before any public launch.

## Schema

Tables: 18. Access rules: Row Level Security on every table, helpers `is_club_admin`, `is_club_member`, `is_team_member`. See `replica/schema.sql`.

Key decisions:
- `members` is the person record. `profile_id` links to a Supabase login only when the person signs in. Import creates members without logins.
- Roles (`member_roles`) and team membership (`team_members`) are separate: one person can be a parent and a player.
- Season history: `seasons`, `stat_entries` keyed by `(member, season, event, metric)`. A re-import of the same file is idempotent (unique key + `external_ref`).
- Minors: birth date and phone are hidden from non-admins through `members.privacy` in the data layer. RLS does not do field-level hiding in v1. Known gap, see parts that bite.
- Times: `timestamptz`, UTC. Display in `clubs.timezone`.

## API

Server actions (Next.js) and Supabase RPC. All run under the user's session, so RLS applies.

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| POST /auth/sign-up | create login | anyone | email, password | session | F08 |
| POST /clubs | create club, first admin | signed-in user | name, sport, timezone | club | F08 |
| GET /clubs/:id/calendar | list events by range, team, kind | member | from, to, team?, kind? | events[] | F01, S07 |
| POST /clubs/:id/events | create event, team or club-wide | admin or team coach | kind, title, starts_at, ends_at, place, team_id? | event | F01, S09 |
| PATCH /events/:id | edit or cancel, notify invitees | creator or admin | fields, status | event | F01, S08 |
| POST /events/:id/invitations | invite members or whole team | admin or coach | member_ids or team_id | invitations[] | F01 |
| PUT /events/:id/answer | set own answer | the invited member | answer yes/no/maybe | invitation | F02 |
| GET /events/:id/attendance | list answers | admin or coach of team | - | invitations[] | F02, S08 |
| PUT /events/:id/votes | rate the event | member who played | score 1-5 | vote | S15 |
| GET /clubs/:id/members | list with filter and sort | admin; member sees own row and team | q, role, team, sort | members[] | F05, S11 |
| POST /clubs/:id/members | add one member | admin | profile fields | member | F05 |
| PATCH /members/:id | edit profile and privacy | admin, or member for own non-admin fields | fields | member | F05 |
| POST /members/:id/files | attach a file | admin | multipart file, max 10 MB | member_file | F05 |
| POST /clubs/:id/imports/members | import roster from SportEasy export | admin | CSV or XLSX | import report | F05 |
| POST /clubs/:id/imports/stats | import season stats from export | admin | season_id, CSV or XLSX | stat_import | F05 |
| GET /clubs/:id/members/export | export roster | admin | - | CSV | S11 |
| GET /clubs/:id/stats | season totals and per-event | admin; player sees own | season_id, member_id? | stat_entries[] | S14 |
| POST /threads | create direct, group, team or event thread | member (team or event rules) | kind, subject, participant ids | thread | F03, F04 |
| POST /threads/:id/messages | send message with attachments | participant | body, files? | message | F03, F04 |
| DELETE /messages/:id | soft delete own message | author or admin | - | 204 | messaging |
| GET /threads/:id/messages | list | participant | cursor | messages[] | S10 |
| POST /clubs/:id/seasons | create season | admin | name, starts_on, ends_on | season | setup |
| POST /clubs/:id/invites | invite a person to sign in and link to member | admin | email, member_id | invite | F05 |
| POST /clubs/:id/teams | create team or group | admin | name, kind, category | team | F05 |

Webhooks in: none (no payments, no third-party calendar sync in v1).
Webhooks out: none.

Jobs (Supabase `pg_cron`):
- `send_event_reminders`: every 15 min. Email invitees with `answer = 'none'` for events starting within 24 h and `reminder_sent_at is null`. Set `reminder_sent_at`. Respect the Resend daily cap.
- `cleanup_orphan_files`: daily. Delete storage objects with no row in `member_files` or `message_attachments`.
- `keepalive`: weekly. Read one row so the Supabase project does not pause.

Imports (`/imports/*`) are user-triggered, not background jobs. They parse the user's own export file only. Upsert by `external_ref` (members) and `(member, season, event, metric)` (stats).

## The parts that bite

- Time zones and DST: events stored UTC, shown in club timezone. Reminders compare in UTC. Test an event across the March and October switch.
- Idempotency: email sends can repeat if a job retries. Guard with `reminder_sent_at` set in the same transaction as the send call, and accept that a crash between send and update can send twice. Log it.
- Races: two admins editing one event, two members answering at once. Last write wins for answers (each member edits only own row). Event edits: add `updated_at` check (optimistic lock) in PATCH.
- Double booking of a place: not enforced in v1. Exclusion constraint noted in `schema.sql`, needs `place` as a table first.
- Field-level privacy: `members.privacy` is enforced in the API layer. A direct Supabase query from the browser can bypass it. Options: separate `member_private` table with its own RLS (preferred before real use), or query only through API routes. Decide before inviting parents.
- Minors' data (birth date, health notes, files): GDPR. Store only what the club needs. Give a delete path (member and files, cascade). Keep the user's export files out of the repo and out of storage after import.
- Stats history: imports must not overwrite a season's totals silently. Re-import shows a diff first. Not built in v1, flagged.
- Email deliverability: Resend needs a verified sender domain. Free `onboarding@resend.dev` only sends to the account owner.
- Uploads: 10 MB member files, 25 MB message attachments. Check MIME by content, not extension.
- Search: roster search with `ilike` on `last_name` is enough for a club of hundreds. Revisit above a few thousand.
- Realtime: not in v1. Messages refresh on load. Add Supabase Realtime later if needed.
- Multi-tenancy: every table has `club_id` except `profiles`, `messages` and `message_attachments` (reached through thread). RLS checks club on every row.

## Build order

1. Vertical slice: sign up, create club, create one team, add one member, create one training event, invite that member, member answers yes, admin sees the answer. Screens: S01, S07, S08, S09, S11 (minimal). Tables: profiles, clubs, club_admins, teams, members, events, invitations. Routes: POST /auth/sign-up, POST /clubs, POST /clubs/:id/teams, POST /clubs/:id/members, POST /clubs/:id/events, POST /events/:id/invitations, PUT /events/:id/answer, GET /events/:id/attendance.
2. Must-haves (14 rows in features.csv): calendar with filters (S07), event kinds (S09), invitations and answers (S08), attendance, reminders (job), event chat and team messaging (S10), roster import (F09), member database (S11), sign-up and onboarding (S01, S02-S03 static copy). Roster import (F05) and season-stats import (F05) are must-haves per the user's request.
3. Should-haves (6): per-field privacy, member files, attachments and delete in messages, export roster CSV, registration form without payment (F07 minus payment step).
4. Could-haves (4): season stats view and history import (S14, user request: import season stats from their own export, so this moves to must in practice), votes and ratings (S15), sponsor banners (drop unless wanted), native apps (later).
5. Fixes from replica-entrepreneur: not run yet.

Note on priority: the user asked for roster and season-history import. In `features.csv` those rows are `must`. Build them in step 2, after the slice works.

## Next step

`/replica-design`.
