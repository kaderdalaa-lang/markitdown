-- RLS tests. Run after schema.sql and supabase_stub.sql on a scratch database.
-- Each check raises on failure, so psql -v ON_ERROR_STOP=1 exits non-zero.
begin;

-- fixtures as superuser (bypasses RLS)
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'admin@test.invalid'),
  ('00000000-0000-0000-0000-00000000000b', 'player@test.invalid'),
  ('00000000-0000-0000-0000-00000000000c', 'outsider@test.invalid');
insert into profiles (id, display_name) values
  ('00000000-0000-0000-0000-00000000000a', 'Admin'),
  ('00000000-0000-0000-0000-00000000000b', 'Player'),
  ('00000000-0000-0000-0000-00000000000c', 'Outsider');
insert into clubs (id, name, created_by) values ('10000000-0000-0000-0000-000000000001', 'Club One', '00000000-0000-0000-0000-00000000000a');
insert into clubs (id, name, created_by) values ('10000000-0000-0000-0000-000000000002', 'Club Two', '00000000-0000-0000-0000-00000000000c');
insert into club_admins (club_id, profile_id) values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a');
insert into club_admins (club_id, profile_id) values ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000c');
insert into teams (id, club_id, name) values ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'U13');
insert into members (id, club_id, profile_id, first_name, last_name) values
  ('30000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'Player', 'One'),
  ('30000000-0000-0000-0000-00000000000d', '10000000-0000-0000-0000-000000000001', null, 'Other', 'Kid');
insert into team_members (team_id, member_id, club_id) values
  ('20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000d', '10000000-0000-0000-0000-000000000001');
insert into events (id, club_id, team_id, kind, title, starts_at, ends_at, created_by) values
  ('40000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'training', 'Training', now() + interval '1 day', now() + interval '1 day 1 hour', '00000000-0000-0000-0000-00000000000a');
insert into invitations (club_id, event_id, member_id) values
  ('10000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000b'),
  ('10000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000d');
insert into stat_entries (club_id, member_id, metric, value) values
  ('10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000b', 'goals', 3);

create or replace function pg_temp.as_user(uid text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid, true);
  execute 'set local role authenticated';
end $$;
create or replace function pg_temp.reset_role() returns void language plpgsql as $$
begin
  execute 'reset role';
end $$;

create or replace function pg_temp.expect(label text, got bigint, want bigint) returns void language plpgsql as $$
begin
  if got <> want then raise exception 'FAIL %: got %, want %', label, got, want; end if;
  raise notice 'ok   %', label;
end $$;

-- 1. outsider sees nothing in club one
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
select pg_temp.expect('outsider: clubs visible', (select count(*) from clubs where id = '10000000-0000-0000-0000-000000000001'), 0);
select pg_temp.expect('outsider: members visible', (select count(*) from members), 0);
select pg_temp.expect('outsider: events visible', (select count(*) from events), 0);
select pg_temp.expect('outsider: invitations visible', (select count(*) from invitations), 0);
select pg_temp.expect('outsider: stats visible', (select count(*) from stat_entries), 0);
select pg_temp.expect('outsider: directory empty', (select count(*) from member_directory('10000000-0000-0000-0000-000000000001')), 0);
select pg_temp.reset_role();

-- 2. player sees club one events and members, not stats
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.expect('player: club visible', (select count(*) from clubs where id = '10000000-0000-0000-0000-000000000001'), 1);
select pg_temp.expect('player: events visible', (select count(*) from events), 1);
select pg_temp.expect('player: own member row only', (select count(*) from members where club_id = '10000000-0000-0000-0000-000000000001'), 1);
select pg_temp.expect('player: directory lists club members', (select count(*) from member_directory('10000000-0000-0000-0000-000000000001')), 2);
select pg_temp.expect('player: stats hidden', (select count(*) from stat_entries), 0);
with u as (update clubs set name = 'hacked' where id = '10000000-0000-0000-0000-000000000001' returning 1) select pg_temp.expect('player: cannot write club', (select count(*) from u), 0);
do $$ begin
  begin
    insert into events (club_id, kind, title, starts_at, ends_at, created_by) values ('10000000-0000-0000-0000-000000000001','other','x', now(), now()+interval '1 hour', '00000000-0000-0000-0000-00000000000b');
    raise exception 'FAIL player: created event';
  exception when insufficient_privilege then raise notice 'ok   player: cannot create event (RLS rejected)';
  end;
end $$;
-- player answers own invitation only
with u as (update invitations set answer = 'yes' where member_id = '30000000-0000-0000-0000-00000000000b' returning 1) select pg_temp.expect('player: answers own invitation', (select count(*) from u), 1);
with u as (update invitations set answer = 'yes' where member_id = '30000000-0000-0000-0000-00000000000d' returning 1) select pg_temp.expect('player: cannot answer for other member', (select count(*) from u), 0);
select pg_temp.reset_role();

-- 3. admin sees stats and manages invitations
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect('admin: stats visible', (select count(*) from stat_entries), 1);
select pg_temp.expect('admin: invitations for other member', (select count(*) from invitations where member_id = '30000000-0000-0000-0000-00000000000d'), 1);
with u as (update invitations set answer = 'maybe' where member_id = '30000000-0000-0000-0000-00000000000d' returning 1) select pg_temp.expect('admin: can update other member invitation', (select count(*) from u), 1);
select pg_temp.reset_role();

-- 4. admin of club one cannot see club two
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect('admin one: club two hidden', (select count(*) from clubs where id = '10000000-0000-0000-0000-000000000002'), 0);
select pg_temp.reset_role();

-- 5. unique answer per member per event
do $$ begin
  begin
    insert into invitations (club_id, event_id, member_id) values ('10000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000b');
    raise exception 'FAIL duplicate invitation accepted';
  exception when unique_violation then raise notice 'ok   duplicate invitation rejected';
  end;
end $$;

rollback;
\echo ALL RLS CHECKS PASSED
