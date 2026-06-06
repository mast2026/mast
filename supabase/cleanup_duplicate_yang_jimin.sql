-- Cleanup duplicate member: 양지민 / 2기 / 서울여자대학교
-- Keep the row with major = 경영학과, merge history from the empty-major duplicate.

begin;

do $$
declare
  keep_member_id uuid := '5a5e53be-4bdb-4fbe-9170-b2b376dc7dad';
  duplicate_member_id uuid := '0c04cb52-2331-4b2b-8277-94d93ae19bbe';
  duplicate_assignment_20260606 uuid := '2342d2ae-d63b-4fc8-ba73-893b6416d0dc';
begin
  -- 2026-06-06 has both member ids assigned. Remove the empty-major duplicate assignment.
  delete from public.promotion_proofs
  where assignment_id = duplicate_assignment_20260606;

  delete from public.promotion_mission_assignments
  where id = duplicate_assignment_20260606;

  -- Move older proof rows to the kept member id.
  update public.promotion_proofs
  set member_id = keep_member_id
  where member_id = duplicate_member_id;

  -- Move older assignments to the kept member id only when that mission does not already have keep_member_id.
  update public.promotion_mission_assignments a
  set member_id = keep_member_id
  where a.member_id = duplicate_member_id
    and not exists (
      select 1
      from public.promotion_mission_assignments existing
      where existing.mission_id = a.mission_id
        and existing.member_id = keep_member_id
    );

  -- If anything remains on the duplicate id after safe merge, fail instead of deleting history.
  if exists (
    select 1 from public.promotion_mission_assignments where member_id = duplicate_member_id
  ) or exists (
    select 1 from public.promotion_proofs where member_id = duplicate_member_id
  ) then
    raise exception 'Duplicate member still has linked records. Check manually before deleting.';
  end if;

  delete from public.members
  where id = duplicate_member_id;
end $$;

-- Prevent the same person from being imported again with only whitespace differences.
create unique index if not exists members_unique_identity_normalized
on public.members (
  lower(regexp_replace(trim(name), '\s+', '', 'g')),
  lower(regexp_replace(trim(gi), '\s+', '', 'g')),
  lower(regexp_replace(trim(school), '\s+', '', 'g'))
);

commit;
