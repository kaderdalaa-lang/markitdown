-- ASCteam schema (clone of SportEasy core). Postgres on Supabase, free tier.
-- Access: Row Level Security on every table. Helpers below decide membership.
-- Times: timestamptz, UTC. Money: none (free app, no payments).

create extension if not exists pgcrypto;

-- ---------- identity ----------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- club and teams ----------
create table clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport text,
  timezone text not null default 'Europe/Paris',
  created_by uuid not null references profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table club_admins (
  club_id uuid not null references clubs(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role text not null default 'manager' check (role in ('manager','volunteer')),
  primary key (club_id, profile_id)
);

create table seasons (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  name text not null,                       -- e.g. '2025-2026'
  starts_on date not null,
  ends_on date not null,
  constraint season_order check (ends_on > starts_on),
  unique (club_id, name)
);
create index on seasons (club_id);

create table teams (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  name text not null,
  kind text not null default 'team' check (kind in ('team','group')),
  category text,                            -- age group
  sport text,
  created_at timestamptz not null default now(),
  unique (club_id, name)
);
create index on teams (club_id);

-- ---------- members (people in the club) ----------
create table members (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  profile_id uuid references profiles(id) on delete set null,  -- set when the person signs in
  first_name text not null,
  last_name text not null,
  birth_date date,                          -- minors: restrict via RLS, see below
  licence_number text,
  email text,
  phone text,
  notes text,
  privacy jsonb not null default '{}',      -- per-field visibility: {"phone":"admins","birth_date":"admins"}
  external_ref text,                        -- id from the SportEasy export, for idempotent import
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, external_ref)
);
create index on members (club_id, last_name);
create index on members (profile_id);

create table member_roles (
  member_id uuid not null references members(id) on delete cascade,
  club_id uuid not null references clubs(id) on delete cascade,
  role text not null check (role in ('player','coach','parent','manager','volunteer')),
  primary key (member_id, role)
);
create index on member_roles (club_id);

create table team_members (
  team_id uuid not null references teams(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  club_id uuid not null references clubs(id) on delete cascade,
  role_in_team text not null default 'player' check (role_in_team in ('player','coach')),
  primary key (team_id, member_id)
);
create index on team_members (member_id);
create index on team_members (club_id);

create table member_files (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  storage_key text not null,                -- Supabase Storage path
  name text not null,
  mime text not null,
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 10485760),
  created_at timestamptz not null default now()
);
create index on member_files (member_id);

-- ---------- events, invitations ----------
create table events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  team_id uuid references teams(id) on delete cascade,   -- null = club-wide
  season_id uuid references seasons(id) on delete set null,
  kind text not null check (kind in ('training','match','meeting','party','other')),
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  place text,
  status text not null default 'scheduled' check (status in ('scheduled','cancelled','postponed')),
  created_by uuid not null references profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint event_order check (ends_at > starts_at)
);
create index on events (club_id, starts_at);
create index on events (team_id, starts_at);
create index on events (season_id);

create table invitations (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  event_id uuid not null references events(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  answer text not null default 'none' check (answer in ('yes','no','maybe','none')),
  answered_at timestamptz,
  reminder_sent_at timestamptz,
  unique (event_id, member_id)              -- one answer per member per event: concurrency guard
);
create index on invitations (member_id);
create index on invitations (club_id);

-- ---------- messaging ----------
create table threads (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  kind text not null check (kind in ('direct','group','team','event')),
  subject text,
  team_id uuid references teams(id) on delete cascade,
  event_id uuid references events(id) on delete cascade,
  created_by uuid not null references profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint thread_event_link check ((kind = 'event') = (event_id is not null))
);
create index on threads (club_id);

create table thread_participants (
  thread_id uuid not null references threads(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  primary key (thread_id, profile_id)
);
create index on thread_participants (profile_id);

create table messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references threads(id) on delete cascade,
  author_id uuid not null references profiles(id) on delete restrict,
  body text not null default '',
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index on messages (thread_id, created_at);

create table message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references messages(id) on delete cascade,
  storage_key text not null,
  mime text not null,
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 26214400)
);
create index on message_attachments (message_id);

-- ---------- votes and statistics, with history ----------
create table votes (
  event_id uuid not null references events(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  club_id uuid not null references clubs(id) on delete cascade,
  score smallint not null check (score between 1 and 5),
  primary key (event_id, member_id)
);

create table stat_imports (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  season_id uuid references seasons(id) on delete set null,
  source_name text not null,                -- file name of the user's own export
  row_count integer not null default 0,
  imported_by uuid not null references profiles(id) on delete restrict,
  imported_at timestamptz not null default now()
);

create table stat_entries (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  season_id uuid references seasons(id) on delete set null,
  event_id uuid references events(id) on delete set null,   -- null for season totals
  import_id uuid references stat_imports(id) on delete set null,
  metric text not null,                     -- e.g. 'goals', 'games_played', 'minutes'
  value numeric not null,
  created_at timestamptz not null default now(),
  unique (member_id, season_id, event_id, metric)            -- re-import is idempotent
);
create index on stat_entries (club_id, season_id);
create index on stat_entries (member_id);

-- ---------- access helpers (RLS) ----------
create or replace function is_club_admin(p_club uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from club_admins
    where club_id = p_club and profile_id = auth.uid()
  );
$$;

create or replace function is_club_member(p_club uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select is_club_admin(p_club) or exists (
    select 1 from members m
    where m.club_id = p_club and m.profile_id = auth.uid()
  );
$$;

create or replace function is_team_member(p_team uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from team_members tm
    join members m on m.id = tm.member_id
    where tm.team_id = p_team and m.profile_id = auth.uid()
  );
$$;

-- ---------- RLS ----------
alter table profiles enable row level security;
alter table clubs enable row level security;
alter table club_admins enable row level security;
alter table seasons enable row level security;
alter table teams enable row level security;
alter table members enable row level security;
alter table member_roles enable row level security;
alter table team_members enable row level security;
alter table member_files enable row level security;
alter table events enable row level security;
alter table invitations enable row level security;
alter table threads enable row level security;
alter table thread_participants enable row level security;
alter table messages enable row level security;
alter table message_attachments enable row level security;
alter table votes enable row level security;
alter table stat_imports enable row level security;
alter table stat_entries enable row level security;

create policy profiles_self on profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy clubs_read on clubs for select using (is_club_member(id));
create policy clubs_admin_write on clubs for update using (is_club_admin(id)) with check (is_club_admin(id));
create policy club_admins_read on club_admins for select using (is_club_member(club_id));
create policy club_admins_write on club_admins for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy seasons_read on seasons for select using (is_club_member(club_id));
create policy seasons_write on seasons for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy teams_read on teams for select using (is_club_member(club_id));
create policy teams_write on teams for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));

-- members: admins see all; a member sees own row; minors' birth_date/phone hidden from non-admins by the data layer (privacy jsonb), not by RLS
create policy members_read on members for select using (is_club_admin(club_id) or profile_id = auth.uid() or is_club_member(club_id));
create policy members_write on members for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy member_roles_read on member_roles for select using (is_club_member(club_id));
create policy member_roles_write on member_roles for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy team_members_read on team_members for select using (is_club_member(club_id));
create policy team_members_write on team_members for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy member_files_admin on member_files for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));

create policy events_read on events for select using (is_club_member(club_id));
create policy events_write on events for all using (is_club_admin(club_id) or (team_id is not null and is_team_member(team_id) and created_by = auth.uid())) with check (is_club_admin(club_id) or (team_id is not null and is_team_member(team_id) and created_by = auth.uid()));
create policy invitations_read on invitations for select using (is_club_admin(club_id) or exists (select 1 from members m where m.id = member_id and m.profile_id = auth.uid()));
create policy invitations_answer on invitations for update using (exists (select 1 from members m where m.id = member_id and m.profile_id = auth.uid())) with check (exists (select 1 from members m where m.id = member_id and m.profile_id = auth.uid()));
create policy invitations_admin on invitations for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));

create policy threads_read on threads for select using (is_club_admin(club_id) or exists (select 1 from thread_participants tp where tp.thread_id = id and tp.profile_id = auth.uid()));
create policy threads_create on threads for insert with check (is_club_member(club_id) and created_by = auth.uid());
create policy thread_participants_read on thread_participants for select using (exists (select 1 from threads t where t.id = thread_id and (is_club_admin(t.club_id) or profile_id = auth.uid())));
create policy thread_participants_admin on thread_participants for all using (exists (select 1 from threads t where t.id = thread_id and is_club_admin(t.club_id))) with check (exists (select 1 from threads t where t.id = thread_id and is_club_admin(t.club_id)));
create policy messages_read on messages for select using (exists (select 1 from thread_participants tp where tp.thread_id = messages.thread_id and tp.profile_id = auth.uid()));
create policy messages_write on messages for insert with check (author_id = auth.uid() and exists (select 1 from thread_participants tp where tp.thread_id = messages.thread_id and tp.profile_id = auth.uid()));
create policy messages_delete_own on messages for update using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy message_attachments_read on message_attachments for select using (exists (select 1 from messages m join thread_participants tp on tp.thread_id = m.thread_id where m.id = message_id and tp.profile_id = auth.uid()));

create policy votes_read on votes for select using (is_club_member(club_id));
create policy votes_write on votes for all using (is_club_member(club_id) and exists (select 1 from members m where m.id = member_id and m.profile_id = auth.uid())) with check (is_club_member(club_id) and exists (select 1 from members m where m.id = member_id and m.profile_id = auth.uid()));

-- stats: admins only, history is sensitive (minors)
create policy stat_imports_admin on stat_imports for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));
create policy stat_entries_admin on stat_entries for all using (is_club_admin(club_id)) with check (is_club_admin(club_id));

-- ---------- invariants the UI cannot enforce ----------
-- one answer per member per event: unique (event_id, member_id) on invitations
-- one season name per club: unique (club_id, name) on seasons
-- no event ends before it starts: check on events
-- double booking of a place: add later with an exclusion constraint once place is a table
--   (create extension btree_gist; exclude using gist (place with =, tstzrange(starts_at, ends_at) with &&))
