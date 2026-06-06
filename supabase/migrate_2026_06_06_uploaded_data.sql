-- MAST ETA uploaded data migration: 2026-06-06
-- Source files: missions_rows (1).csv, proofs_rows (1).csv
-- Run after setup_v1.sql and members import.
begin;

insert into public.promotion_missions (id, mission_date, title, body, due_at, late_until_at, status, mission_image_url, mission_image_path, created_by, created_at)
values (
  'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid,
  '2026-06-05'::date,
  'Mast 3기 모집 홍보 1일차🚀',
  '1. 공지된 매뉴얼에 따라 글을 작성하고, 포스터 사진을 첨부하여 에브리타임 게시글을 작성해주세요! 📝
2. 작성한 글을 캡쳐한 후 사진을 업로드 해주세요📷',
  (('2026-06-05'::date + '23:59:00'::time) at time zone 'Asia/Seoul'),
  ((('2026-06-05'::date + '23:59:00'::time) at time zone 'Asia/Seoul') + interval '24 hours'),
  'active',
  'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/missions/2026-06-05_1780628805968.jpeg',
  '2026-06-05_1780628805968.jpeg',
  '전현지',
  '2026-06-05 03:06:47.917989+00'::timestamptz
)
on conflict (id) do update set
  mission_date = excluded.mission_date,
  title = excluded.title,
  body = excluded.body,
  due_at = excluded.due_at,
  late_until_at = excluded.late_until_at,
  status = excluded.status,
  mission_image_url = excluded.mission_image_url,
  mission_image_path = excluded.mission_image_path,
  created_by = excluded.created_by;

with assignee_keys as (
  select jsonb_array_elements_text('["김민서|2기|가천대학교","정효상|2기|강원대학교","문서영|1기|건국대학교","김태훈|1기|경기대학교","유현민|1기|경희대학교","이우현|1기|고려대학교","성지연|2기|고려대학교 세종캠퍼스","김준석|1기|국민대학교","조규영|1기|단국대학교","김혜원|1기|동국대학교","박다인|1기|동덕여자대학교","마민서|2기|동아대학교","박재형|2기|명지대학교","이수민|2기|부산가톨릭대학교","손혜주|2기|부산대학교","양하영|1기|부산외국어대학교","강주연|1기|상명대학교","이서준|1기|상지대학교","홍준서|1기|서울과학기술대학교","박준영|2기|수원대학교","김채현|2기|숙명여자대학교","김종하|1기|숭실대학교","박승휘|1기|신구대학교","김나현|1기|안양대학교","이사랑|2기|연세대학교 미래캠퍼스","장지호|1기|울산대학교","이지민|2기|유니스트","김도연|1기|이화여자대학교","김태경|1기|인천대학교","김정원|1기|인하대학교","김아현|2기|중앙대학교","박규리|1기|충북대학교","김대한|1기|한경국립대학교","김수민|2기|한국외국어대학교 글로벌캠퍼스","권용진|1기|한국폴리텍대학교","문장연|2기|한성대학교","박수현|2기|한양대학교 에리카캠퍼스","최진서|1기|홍익대학교","황재준|1기|홍익대학교 세종캠퍼스","양지민|2기|서울여자대학교","이윤주|2기|연세대학교"]'::jsonb) as member_key
), matched_members as (
  select ak.member_key, mem.id as member_id
  from assignee_keys ak
  join public.members mem
    on mem.name = split_part(ak.member_key, '|', 1)
   and mem.gi = split_part(ak.member_key, '|', 2)
   and mem.school = split_part(ak.member_key, '|', 3)
)
insert into public.promotion_mission_assignments (mission_id, member_id, status, due_at, late_until_at, status_reason)
select
  'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid,
  member_id,
  case when now() > (('2026-06-05'::date + '23:59:00'::time) at time zone 'Asia/Seoul') then 'missed' else 'pending' end,
  (('2026-06-05'::date + '23:59:00'::time) at time zone 'Asia/Seoul'),
  ((('2026-06-05'::date + '23:59:00'::time) at time zone 'Asia/Seoul') + interval '24 hours'),
  'Migrated from uploaded CSV data'
from matched_members
on conflict (mission_id, member_id) do update set
  due_at = excluded.due_at,
  late_until_at = excluded.late_until_at;

insert into public.promotion_missions (id, mission_date, title, body, due_at, late_until_at, status, mission_image_url, mission_image_path, created_by, created_at)
values (
  'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid,
  '2026-06-06'::date,
  'Mast 3기 모집 홍보 2일차🚀',
  '1. 공지된 매뉴얼에 따라 글을 작성하고, 포스터 사진을 첨부하여 에브리타임 게시글을 작성해주세요! 📝
2. 작성한 글을 캡쳐한 후 사진을 업로드해주세요 📷',
  (('2026-06-06'::date + '23:59:00'::time) at time zone 'Asia/Seoul'),
  ((('2026-06-06'::date + '23:59:00'::time) at time zone 'Asia/Seoul') + interval '24 hours'),
  'active',
  'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/missions/2026-06-06_1780708808184.jpeg',
  '2026-06-06_1780708808184.jpeg',
  '전현지',
  '2026-06-06 01:20:09.135198+00'::timestamptz
)
on conflict (id) do update set
  mission_date = excluded.mission_date,
  title = excluded.title,
  body = excluded.body,
  due_at = excluded.due_at,
  late_until_at = excluded.late_until_at,
  status = excluded.status,
  mission_image_url = excluded.mission_image_url,
  mission_image_path = excluded.mission_image_path,
  created_by = excluded.created_by;

with assignee_keys as (
  select jsonb_array_elements_text('["김민서|2기|가천대학교","정효상|2기|강원대학교","문서영|1기|건국대학교","심서연|1기|경기대학교","최용준|1기|경희대학교","이아나스타샤|2기|고려대학교","배준범|1기|고려대학교 세종캠퍼스","김준석|1기|국민대학교","김예진|2기|단국대학교","전동현|2기|동국대학교","이선아|2기|동덕여자대학교","마민서|2기|동아대학교","박재형|2기|명지대학교","이수민|2기|부산가톨릭대학교","손혜주|2기|부산대학교","오현선|2기|부산외국어대학교","송현아|1기|상명대학교","이서준|1기|상지대학교","홍준서|1기|서울과학기술대학교","전현지|2기|서울여자대학교","박준영|2기|수원대학교","김채현|2기|숙명여자대학교","신해원|2기|숭실대학교","박승휘|1기|신구대학교","김나현|1기|안양대학교","김우진|1기|연세대학교 미래캠퍼스","윤형진|2기|울산대학교","이지민|2기|유니스트","김신영|1기|이화여자대학교","김태경|1기|인천대학교","이희원|1기|인하대학교","박선호|1기|충북대학교","김채영|2기|한경국립대학교","김수민|2기|한국외국어대학교 글로벌캠퍼스","권용진|1기|한국폴리텍대학교","문장연|2기|한성대학교","박수현|2기|한양대학교 에리카캠퍼스","고준희|2기|홍익대학교","황재준|1기|홍익대학교 세종캠퍼스","배정은|2기|중앙대학교"]'::jsonb) as member_key
), matched_members as (
  select ak.member_key, mem.id as member_id
  from assignee_keys ak
  join public.members mem
    on mem.name = split_part(ak.member_key, '|', 1)
   and mem.gi = split_part(ak.member_key, '|', 2)
   and mem.school = split_part(ak.member_key, '|', 3)
)
insert into public.promotion_mission_assignments (mission_id, member_id, status, due_at, late_until_at, status_reason)
select
  'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid,
  member_id,
  case when now() > (('2026-06-06'::date + '23:59:00'::time) at time zone 'Asia/Seoul') then 'missed' else 'pending' end,
  (('2026-06-06'::date + '23:59:00'::time) at time zone 'Asia/Seoul'),
  ((('2026-06-06'::date + '23:59:00'::time) at time zone 'Asia/Seoul') + interval '24 hours'),
  'Migrated from uploaded CSV data'
from matched_members
on conflict (mission_id, member_id) do update set
  due_at = excluded.due_at,
  late_until_at = excluded.late_until_at;

with old_proofs (id, mission_id, member_key, old_status, proof_image_url, proof_file_path, submitted_at) as (
values
  ('05ae9b2d-04bf-4ae0-b623-4a7c6b9bc0e9'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '정효상|2기|강원대학교', 'approved', null, null, '2026-06-05 13:35:24.118+00'::timestamptz),
  ('13761f81-5763-4926-a069-55b9181ed0ff'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '양지민|2기|서울여자대학교', 'approved', null, null, '2026-06-05 04:11:44.438+00'::timestamptz),
  ('15278951-dca1-46c6-820a-36a6e3914fb9'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박수현|2기|한양대학교 에리카캠퍼스', 'approved', null, null, '2026-06-05 04:57:33.651+00'::timestamptz),
  ('177f2149-994e-440e-bf17-c647fcdcab4f'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김종하|1기|숭실대학교', 'approved', null, null, '2026-06-05 03:14:11.532+00'::timestamptz),
  ('17ee978e-23f5-49b8-93b3-10c62a34ac23'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '유현민|1기|경희대학교', 'approved', null, null, '2026-06-05 13:45:52.141+00'::timestamptz),
  ('21bc72fd-4ddb-45eb-99ee-5fa728558413'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '문장연|2기|한성대학교', 'pending', 'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/proofs/2026-06-06/_EB_AC_B8_EC_9E_A5_E_1780709778408.png', '2026-06-06/_EB_AC_B8_EC_9E_A5_E_1780709778408.png', '2026-06-06 01:36:18.406+00'::timestamptz),
  ('2979720a-d74b-4f3f-b88a-989813372eea'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '조규영|1기|단국대학교', 'approved', null, null, '2026-06-05 04:17:19.437+00'::timestamptz),
  ('41cb42a4-1eaa-45bd-a1d9-3e02589b9d5f'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박준영|2기|수원대학교', 'approved', null, null, '2026-06-05 03:27:06.37+00'::timestamptz),
  ('44c2ee32-4963-49b8-95e2-6a69e29c36aa'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이수민|2기|부산가톨릭대학교', 'approved', null, null, '2026-06-05 04:53:10.953+00'::timestamptz),
  ('48ab756d-4d1d-4beb-9130-037b8c6d77b3'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김수민|2기|한국외국어대학교 글로벌캠퍼스', 'approved', null, null, '2026-06-05 03:44:38.025+00'::timestamptz),
  ('59fdec1e-cf0a-45d2-a124-764903b66168'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김채현|2기|숙명여자대학교', 'approved', null, null, '2026-06-05 03:14:39.251+00'::timestamptz),
  ('5dfacefc-ffa6-457b-b491-82d905fd3e2b'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김아현|2기|중앙대학교', 'approved', null, null, '2026-06-05 04:02:47.025+00'::timestamptz),
  ('60807c09-927f-4644-b191-87b90539ab60'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이지민|2기|유니스트', 'approved', null, null, '2026-06-05 06:15:30.313+00'::timestamptz),
  ('67db3e31-0620-4cf8-b60f-a6b7376cf253'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박규리|1기|충북대학교', 'approved', null, null, '2026-06-05 13:03:57.605+00'::timestamptz),
  ('6caaa2ae-75f6-43bf-8b88-8e0f72b1e787'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이사랑|2기|연세대학교 미래캠퍼스', 'approved', null, null, '2026-06-05 03:14:18.949+00'::timestamptz),
  ('6dfa276a-e1a9-409c-b4a2-2a4d5f45e8ca'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '김채현|2기|숙명여자대학교', 'pending', 'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/proofs/2026-06-06/_EA_B9_80_EC_B1_84_E_1780709607471.png', '2026-06-06/_EA_B9_80_EC_B1_84_E_1780709607471.png', '2026-06-06 01:33:27.47+00'::timestamptz),
  ('78784de4-7d67-4da8-afc1-55f226e57bcf'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '장지호|1기|울산대학교', 'approved', null, null, '2026-06-05 14:26:15.359+00'::timestamptz),
  ('8008cd28-b7a0-4221-9681-6a07c4fe2991'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '오현선|2기|부산외국어대학교', 'approved', null, null, '2026-06-06 01:29:15.702+00'::timestamptz),
  ('872e972c-a636-481f-89e8-013bc9ff2be6'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김대한|1기|한경국립대학교', 'approved', null, null, '2026-06-05 04:11:40.164+00'::timestamptz),
  ('90366a52-f1f6-49fa-a406-d6f7e9d286ef'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '최진서|1기|홍익대학교', 'approved', null, null, '2026-06-05 13:41:10.849+00'::timestamptz),
  ('a075d1e7-5884-4618-8715-e736545ca027'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '마민서|2기|동아대학교', 'approved', null, null, '2026-06-06 01:30:34.435+00'::timestamptz),
  ('a9be68f5-c7bc-4643-9cdc-eaa1695db4d8'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '박수현|2기|한양대학교 에리카캠퍼스', 'approved', null, null, '2026-06-06 01:27:57.768+00'::timestamptz),
  ('b4eb74f1-cdd1-4d86-a10c-bb4e95a156c8'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김혜원|1기|동국대학교', 'approved', null, null, '2026-06-05 03:15:50.425+00'::timestamptz),
  ('b567ddc9-e22c-4ec0-98db-39bede4f0968'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '문서영|1기|건국대학교', 'approved', null, null, '2026-06-05 14:08:59.651+00'::timestamptz),
  ('becd49a7-e952-4673-85b8-1e489073e85e'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이서준|1기|상지대학교', 'approved', null, null, '2026-06-05 09:04:57.837+00'::timestamptz),
  ('c5e7a1c5-a1c3-46f4-9d13-76b207f4f7d0'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김민서|2기|가천대학교', 'approved', null, null, '2026-06-05 06:34:00.143+00'::timestamptz),
  ('e00f96cf-e78d-4ce2-8341-28e2c7db85e5'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '양하영|1기|부산외국어대학교', 'approved', null, null, '2026-06-05 03:17:11.26+00'::timestamptz),
  ('e30d70ad-dd03-4204-8e88-75ea26398656'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박재형|2기|명지대학교', 'approved', null, null, '2026-06-05 03:28:18.3+00'::timestamptz),
  ('ea91d3c1-35f4-411b-a7e1-81e482c64aa8'::uuid, 'e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '성지연|2기|고려대학교 세종캠퍼스', 'approved', null, null, '2026-06-05 05:30:01.591+00'::timestamptz),
  ('fd1dfd12-395b-4ccf-9522-054a1e6e1cce'::uuid, 'e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '전현지|2기|서울여자대학교', 'approved', null, null, '2026-06-06 01:26:47.436+00'::timestamptz)
), matched as (
  select op.*, a.id as assignment_id, a.member_id, a.due_at,
    case
      when op.old_status = 'approved' and op.submitted_at > a.due_at then 'late'
      when op.old_status = 'approved' then 'approved'
      when op.old_status = 'pending' and coalesce(op.proof_image_url, '') <> '' then 'submitted'
      when op.old_status = 'pending' then 'pending'
      when op.old_status = 'rejected' then 'rejected'
      else op.old_status
    end as new_status
  from old_proofs op
  join public.members mem
    on mem.name = split_part(op.member_key, '|', 1)
   and mem.gi = split_part(op.member_key, '|', 2)
   and mem.school = split_part(op.member_key, '|', 3)
  join public.promotion_mission_assignments a
    on a.mission_id = op.mission_id
   and a.member_id = mem.id
)
insert into public.promotion_proofs (id, assignment_id, mission_id, member_id, proof_image_url, proof_file_path, submitted_at, created_at)
select id, assignment_id, mission_id, member_id, proof_image_url, proof_file_path, submitted_at, submitted_at
from matched
where submitted_at is not null
on conflict (assignment_id) do update set
  proof_image_url = excluded.proof_image_url,
  proof_file_path = excluded.proof_file_path,
  submitted_at = excluded.submitted_at;

with old_proofs (mission_id, member_key, old_status, proof_image_url, submitted_at) as (
values
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '정효상|2기|강원대학교', 'approved', null, '2026-06-05 13:35:24.118+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '양지민|2기|서울여자대학교', 'approved', null, '2026-06-05 04:11:44.438+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박수현|2기|한양대학교 에리카캠퍼스', 'approved', null, '2026-06-05 04:57:33.651+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김종하|1기|숭실대학교', 'approved', null, '2026-06-05 03:14:11.532+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '유현민|1기|경희대학교', 'approved', null, '2026-06-05 13:45:52.141+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '문장연|2기|한성대학교', 'pending', 'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/proofs/2026-06-06/_EB_AC_B8_EC_9E_A5_E_1780709778408.png', '2026-06-06 01:36:18.406+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '조규영|1기|단국대학교', 'approved', null, '2026-06-05 04:17:19.437+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박준영|2기|수원대학교', 'approved', null, '2026-06-05 03:27:06.37+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이수민|2기|부산가톨릭대학교', 'approved', null, '2026-06-05 04:53:10.953+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김수민|2기|한국외국어대학교 글로벌캠퍼스', 'approved', null, '2026-06-05 03:44:38.025+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김채현|2기|숙명여자대학교', 'approved', null, '2026-06-05 03:14:39.251+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김아현|2기|중앙대학교', 'approved', null, '2026-06-05 04:02:47.025+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이지민|2기|유니스트', 'approved', null, '2026-06-05 06:15:30.313+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박규리|1기|충북대학교', 'approved', null, '2026-06-05 13:03:57.605+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이사랑|2기|연세대학교 미래캠퍼스', 'approved', null, '2026-06-05 03:14:18.949+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '김채현|2기|숙명여자대학교', 'pending', 'https://pmbnrqfgefgeyhklymhg.supabase.co/storage/v1/object/public/proofs/2026-06-06/_EA_B9_80_EC_B1_84_E_1780709607471.png', '2026-06-06 01:33:27.47+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '장지호|1기|울산대학교', 'approved', null, '2026-06-05 14:26:15.359+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '오현선|2기|부산외국어대학교', 'approved', null, '2026-06-06 01:29:15.702+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김대한|1기|한경국립대학교', 'approved', null, '2026-06-05 04:11:40.164+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '최진서|1기|홍익대학교', 'approved', null, '2026-06-05 13:41:10.849+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '마민서|2기|동아대학교', 'approved', null, '2026-06-06 01:30:34.435+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '박수현|2기|한양대학교 에리카캠퍼스', 'approved', null, '2026-06-06 01:27:57.768+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김혜원|1기|동국대학교', 'approved', null, '2026-06-05 03:15:50.425+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '문서영|1기|건국대학교', 'approved', null, '2026-06-05 14:08:59.651+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '이서준|1기|상지대학교', 'approved', null, '2026-06-05 09:04:57.837+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '김민서|2기|가천대학교', 'approved', null, '2026-06-05 06:34:00.143+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '양하영|1기|부산외국어대학교', 'approved', null, '2026-06-05 03:17:11.26+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '박재형|2기|명지대학교', 'approved', null, '2026-06-05 03:28:18.3+00'::timestamptz),
  ('e58b1961-dde4-4afd-814d-86bb00ee0f00'::uuid, '성지연|2기|고려대학교 세종캠퍼스', 'approved', null, '2026-06-05 05:30:01.591+00'::timestamptz),
  ('e843a7c6-b148-4629-95c0-cc7fd984752e'::uuid, '전현지|2기|서울여자대학교', 'approved', null, '2026-06-06 01:26:47.436+00'::timestamptz)
), matched as (
  select a.id as assignment_id, op.submitted_at,
    case
      when op.old_status = 'approved' and op.submitted_at > a.due_at then 'late'
      when op.old_status = 'approved' then 'approved'
      when op.old_status = 'pending' and coalesce(op.proof_image_url, '') <> '' then 'submitted'
      when op.old_status = 'pending' then 'pending'
      when op.old_status = 'rejected' then 'rejected'
      else op.old_status
    end as new_status
  from old_proofs op
  join public.members mem
    on mem.name = split_part(op.member_key, '|', 1)
   and mem.gi = split_part(op.member_key, '|', 2)
   and mem.school = split_part(op.member_key, '|', 3)
  join public.promotion_mission_assignments a
    on a.mission_id = op.mission_id
   and a.member_id = mem.id
)
update public.promotion_mission_assignments a
set
  status = m.new_status,
  submitted_at = m.submitted_at,
  reviewed_at = case when m.new_status in ('approved', 'late', 'rejected') then m.submitted_at else a.reviewed_at end,
  status_reason = case
    when m.new_status = 'submitted' then null
    when m.new_status = 'pending' then a.status_reason
    else 'Migrated from uploaded CSV proof status'
  end
from matched m
where a.id = m.assignment_id;

-- Result checks
select mission_date, count(*) as assignment_count from public.promotion_assignment_status_view group by mission_date order by mission_date;
select mission_date, status, count(*) from public.promotion_assignment_status_view group by mission_date, status order by mission_date, status;
select count(*) as proof_count from public.promotion_proofs;
commit;
