-- Member privacy. Players and parents must not read other members' personal fields
-- (birth date, phone, email, notes, licence). Only admins read the members table.
-- Everyone in the club gets a name-only directory through a function.

drop policy if exists members_read on members;
create policy members_read_admin_or_self on members for select
  using (is_club_admin(club_id) or profile_id = auth.uid());

create or replace function member_directory(p_club uuid)
returns table (id uuid, first_name text, last_name text, roles text[], team_ids uuid[])
language sql stable security definer set search_path = public as $$
  select m.id, m.first_name, m.last_name,
         coalesce((select array_agg(r.role order by r.role) from member_roles r where r.member_id = m.id), '{}'),
         coalesce((select array_agg(t.team_id) from team_members t where t.member_id = m.id), '{}')
  from members m
  where m.club_id = p_club and is_club_member(p_club);
$$;
revoke all on function member_directory(uuid) from public;
grant execute on function member_directory(uuid) to authenticated;
