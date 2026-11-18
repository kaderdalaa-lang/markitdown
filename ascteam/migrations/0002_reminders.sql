-- Event reminders. Queue in SQL, send from the app.
-- pg_cron runs queue_event_reminders() every 15 min. pg_net then calls /api/jobs/send-email,
-- which drains email_outbox through Resend. Both need the Supabase extensions enabled
-- (Dashboard > Database > Extensions: pg_cron, pg_net).

create table if not exists email_outbox (
  id uuid primary key default gen_random_uuid(),
  to_email text not null,
  subject text not null,
  body text not null,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  attempts integer not null default 0,
  last_error text
);
create index if not exists email_outbox_pending on email_outbox (created_at) where sent_at is null;
alter table email_outbox enable row level security;   -- no policies: only service role and functions touch it

-- Queues a reminder for every invitee who has not answered and whose event starts within 24 h.
-- Idempotent: reminder_sent_at is set in the same statement that queues the mail.
create or replace function queue_event_reminders() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  with due as (
    update invitations i
       set reminder_sent_at = now()
      from events e, members m
     where e.id = i.event_id
       and m.id = i.member_id
       and i.answer = 'none'
       and i.reminder_sent_at is null
       and e.status = 'scheduled'
       and e.starts_at > now()
       and e.starts_at <= now() + interval '24 hours'
       and m.email is not null
    returning m.email as to_email, e.title, e.starts_at, e.place
  ), queued as (
    insert into email_outbox (to_email, subject, body)
    select to_email,
           'Réponds à la convocation : ' || title,
           'Événement : ' || title || E'\nDébut : ' || to_char(starts_at at time zone 'Europe/Paris', 'DD/MM/YYYY HH24:MI') || E'\nLieu : ' || coalesce(place, 'à définir') || E'\n\nRéponds dans l''application.'
      from due
    returning 1
  )
  select count(*) into n from queued;
  return n;
end $$;

-- Schedules. Run once the extensions are on.
-- select cron.schedule('queue-event-reminders', '*/15 * * * *', $$select queue_event_reminders()$$);
-- select cron.schedule('send-outbox', '*/5 * * * *', $$select net.http_post(
--   url := 'https://YOUR-APP.vercel.app/api/jobs/send-email',
--   headers := jsonb_build_object('authorization', 'Bearer ' || current_setting('app.job_secret', true))
-- )$$);
