-- Separate internal mission information from copy/paste post content.
alter table public.promotion_missions
  add column if not exists post_title text,
  add column if not exists post_body text;

-- Keep existing missions usable: old title/body were previously used as post title/body.
update public.promotion_missions
set
  post_title = coalesce(post_title, title),
  post_body = coalesce(post_body, body)
where post_title is null or post_body is null;

-- Refresh Supabase REST schema cache so the app can save post_title/post_body immediately.
select pg_notify('pgrst', 'reload schema');
