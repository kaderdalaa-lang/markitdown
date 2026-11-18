# Backend: ASCteam

Date: 2026-11-18. Stack: Supabase (Auth, Postgres, Storage), Resend for email, pg_cron + pg_net for jobs. No payments (free app).
Code: `ascteam/` (`lib/db.ts`, `lib/supabase/*`, `middleware.ts`, `app/login`, `app/api/jobs/send-email`), migrations in `ascteam/migrations/`, tests in `ascteam/tests/db/`.

## What was verified and how

| item | status | evidence |
| --- | --- | --- |
| schema applies cleanly | done | `tests/db/run.sh` on local Postgres 16 with an auth stub |
| RLS: outsider, player, admin, cross-club | done, 18 checks pass | `tests/db/rls.test.sql` |
| unique answer per member per event | done | RLS test 5 |
| player cannot read others' personal fields | done | migration 0003, member directory function |
| reminder queue, idempotent | done | second call queues 0 rows |
| demo seed | done | `migrations/seed_demo.sql` (invented people) |
| app builds, smoke test (fake data mode) | done | `next build`, browser smoke 390 px and 1440 px |
| real Supabase Auth (sign up, email confirm, sessions) | NOT verified | needs the user's Supabase project |
| pg_cron schedules and pg_net call | NOT verified | needs Supabase extensions enabled |
| Resend sending | NOT verified | needs RESEND_API_KEY and a verified domain |

Limits of the local test: Supabase's real `auth` schema, GoTrue and pg_cron are not present. The `auth` stub is in `tests/db/supabase_stub.sql`.

## Auth
- [x] email + password sign up and sign in (`app/login`), zod-validated input
- [x] email confirmation link lands on `/auth/callback`, code exchange
- [x] session in http-only cookies via `@supabase/ssr`, refreshed in `middleware.ts`
- [x] sign out via POST `/logout` (route, not a link, so a click cannot log out by accident)
- [ ] password reset, magic link (not built)
- [ ] OAuth (Google, Apple): not built, not needed for v1 (no integrations)
- [ ] account deletion: not built. Required before any app-store release. Add `delete_my_account()` that removes the auth user and anonymises the member row.
- [ ] club admin links a sign-in to a member (`members.profile_id`): not built

## Database
- [x] migrations: `0001_init.sql` (schema), `0002_reminders.sql`, `0003_member_privacy.sql`
- [x] RLS on every table, helpers `is_club_admin`, `is_club_member`, `is_team_member`
- [x] tested with a second and third user
- [x] seed script with invented data
- [ ] backups: Supabase free tier has daily backups only on paid plans. Export with `pg_dump` weekly, or accept the risk. Decide before real data.

## Email and jobs
- [x] outbox table `email_outbox` (RLS on, no policies: only the service role and functions touch it)
- [x] `queue_event_reminders()` queues mail for invitees who have not answered, starts within 24 h, idempotent
- [x] `/api/jobs/send-email` drains the outbox through Resend, Bearer `JOB_SECRET`, fails closed without secret
- [ ] pg_cron schedules: commented in `0002_reminders.sql`, enable extensions, fill `YOUR-APP.vercel.app`
- [ ] `app.job_secret` set in Postgres (`alter database postgres set app.job_secret = '...'`): choose storage (Supabase Vault preferred)
- [ ] Resend sender domain verified (free `onboarding@resend.dev` only reaches the account owner)
- Free-tier limit: Resend 100 emails/day. Reminder volume must stay under it.

## Payments
Not applicable. Free app (decision 2026-11-18). No Stripe code.

## Integrations
None in v1. Google Calendar (if added later) needs Google OAuth verification before public launch, which takes weeks. Start it early if wanted.

## Security checklist
- [x] secrets only in env vars; `.env*` ignored, `.env.example` lists names without values
- [x] service role key only in `lib/supabase/admin.ts` (`server-only`), used only by the job route
- [~] input validation: zod on auth. Event and member actions still use manual checks. Move them to zod.
- [x] authorisation on reads and writes: RLS, tested with other users
- [ ] rate limits on sign up and sign in: rely on Supabase Auth limits for now, add app limits before launch
- [x] webhooks: none
- [ ] uploads: not built (member files, message attachments). Must add size and type limits when built, served from a Storage bucket with its own policies
- [x] no user data in URLs; email not logged by the app
- [~] dependencies (`npm audit --omit=dev`): zod fixed (4.6.7). Remaining: `next` 15.5.29 moderate, and `postcss` high (bundled in next, advisory about processing untrusted CSS). Fix = Next 16 (major). Not done, needs your decision.
- [ ] privacy policy lists processors (Supabase, Resend, Vercel). Not written.

## Known issues
- Middleware (`@supabase/ssr`) prints an Edge Runtime warning at build (realtime-js). Harmless for this app, noted.
- Fake data mode runs only with `ASCTEAM_FAKE=1` in production. Without Supabase env in production the app returns 503 (fails closed).
- Stats import and team messaging are not built. Roster import is not built.

## Next
`/replica-test`. Before real use with the user's club: create the Supabase project (user), apply migrations, enable pg_cron and pg_net, set env, run the RLS suite again against the real project's auth.
