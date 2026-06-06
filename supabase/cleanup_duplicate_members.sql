-- Cleanup all duplicate members by normalized identity:
-- name + gi + school, ignoring whitespace differences.
--
-- Keep rule:
-- 1) active member first
-- 2) row with major first
-- 3) older created_at first
--
-- This merges assignments/proofs into the kept member before creating
-- the normalized unique index.

begin;

do $$
declare
  g record;
  duplicate_member record;
  duplicate_assignment record;
  keep_assignment record;
begin
  for g in
    with normalized as (
      select
        id,
        lower(regexp_replace(trim(name), '\s+', '', 'g')) as n_name,
        lower(regexp_replace(trim(gi), '\s+', '', 'g')) as n_gi,
        lower(regexp_replace(trim(school), '\s+', '', 'g')) as n_school,
        row_number() over (
          partition by
            lower(regexp_replace(trim(name), '\s+', '', 'g')),
            lower(regexp_replace(trim(gi), '\s+', '', 'g')),
            lower(regexp_replace(trim(school), '\s+', '', 'g'))
          order by
            case when status = 'active' then 0 else 1 end,
            case when nullif(trim(coalesce(major, '')), '') is not null then 0 else 1 end,
            created_at asc,
            id asc
        ) as rn
      from public.members
    )
    select
      grouped.n_name,
      grouped.n_gi,
      grouped.n_school,
      keeper.id as keep_member_id
    from (
      select n_name, n_gi, n_school
      from normalized
      group by n_name, n_gi, n_school
      having count(*) > 1
    ) grouped
    join normalized keeper
      on keeper.n_name = grouped.n_name
     and keeper.n_gi = grouped.n_gi
     and keeper.n_school = grouped.n_school
     and keeper.rn = 1
  loop
    for duplicate_member in
      select m.*
      from public.members m
      where lower(regexp_replace(trim(m.name), '\s+', '', 'g')) = g.n_name
        and lower(regexp_replace(trim(m.gi), '\s+', '', 'g')) = g.n_gi
        and lower(regexp_replace(trim(m.school), '\s+', '', 'g')) = g.n_school
        and m.id <> g.keep_member_id
    loop
      -- Move or merge mission assignments.
      for duplicate_assignment in
        select *
        from public.promotion_mission_assignments
        where member_id = duplicate_member.id
      loop
        select *
        into keep_assignment
        from public.promotion_mission_assignments
        where mission_id = duplicate_assignment.mission_id
          and member_id = g.keep_member_id
        limit 1;

        if keep_assignment.id is null then
          update public.promotion_mission_assignments
          set member_id = g.keep_member_id
          where id = duplicate_assignment.id;

          update public.promotion_proofs
          set member_id = g.keep_member_id
          where assignment_id = duplicate_assignment.id;
        else
          -- If the duplicate assignment is more progressed than the kept one,
          -- copy its status fields before removing the duplicate assignment.
          if (
            case duplicate_assignment.status
              when 'submitted' then 5
              when 'approved' then 4
              when 'late' then 4
              when 'rejected' then 3
              when 'missed' then 2
              when 'exempted' then 2
              else 1
            end
          ) > (
            case keep_assignment.status
              when 'submitted' then 5
              when 'approved' then 4
              when 'late' then 4
              when 'rejected' then 3
              when 'missed' then 2
              when 'exempted' then 2
              else 1
            end
          ) then
            update public.promotion_mission_assignments
            set
              status = duplicate_assignment.status,
              submitted_at = duplicate_assignment.submitted_at,
              reviewed_at = duplicate_assignment.reviewed_at,
              status_reason = coalesce(duplicate_assignment.status_reason, status_reason),
              updated_at = now()
            where id = keep_assignment.id;
          end if;

          -- Preserve a proof image if the kept assignment does not already have one.
          if exists (
            select 1
            from public.promotion_proofs
            where assignment_id = duplicate_assignment.id
          ) and not exists (
            select 1
            from public.promotion_proofs
            where assignment_id = keep_assignment.id
          ) then
            update public.promotion_proofs
            set assignment_id = keep_assignment.id,
                member_id = g.keep_member_id
            where assignment_id = duplicate_assignment.id;
          else
            delete from public.promotion_proofs
            where assignment_id = duplicate_assignment.id;
          end if;

          delete from public.promotion_mission_assignments
          where id = duplicate_assignment.id;
        end if;
      end loop;

      update public.promotion_proofs
      set member_id = g.keep_member_id
      where member_id = duplicate_member.id;

      delete from public.members
      where id = duplicate_member.id;
    end loop;
  end loop;
end $$;

create unique index if not exists members_unique_identity_normalized
on public.members (
  lower(regexp_replace(trim(name), '\s+', '', 'g')),
  lower(regexp_replace(trim(gi), '\s+', '', 'g')),
  lower(regexp_replace(trim(school), '\s+', '', 'g'))
);

commit;
