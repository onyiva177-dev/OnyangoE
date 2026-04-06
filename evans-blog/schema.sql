-- ============================================================
--  EVANS ONYANGO — Full Blog + Admin System
--  Run this entire file in Supabase SQL Editor
--  Safe to run multiple times (uses IF NOT EXISTS)
-- ============================================================

create extension if not exists "pgcrypto";

-- ============================================================
-- BLOG POSTS
-- ============================================================
create table if not exists blog_posts (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null,
  excerpt     text,
  content     text,
  cover_url   text,
  category    text        not null default 'General',
  tags        text[]      not null default '{}',
  published   boolean     not null default false,
  featured    boolean     not null default false,
  views       integer     not null default 0,
  likes       integer     not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ============================================================
-- BLOG FILE ATTACHMENTS
-- ============================================================
create table if not exists blog_files (
  id          uuid        primary key default gen_random_uuid(),
  post_id     uuid        references blog_posts(id) on delete cascade,
  file_url    text        not null,
  file_name   text        not null,
  file_type   text        not null default 'other',
  file_size   bigint      not null default 0,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- COMMENTS
-- ============================================================
create table if not exists blog_comments (
  id          uuid        primary key default gen_random_uuid(),
  post_id     uuid        not null references blog_posts(id) on delete cascade,
  author_name text        not null,
  author_email text,
  content     text        not null check (char_length(content) between 1 and 800),
  status      text        not null default 'pending', -- 'pending' | 'approved' | 'rejected'
  created_at  timestamptz not null default now()
);

-- ============================================================
-- LIKES  (one per device fingerprint per post)
-- ============================================================
create table if not exists blog_likes (
  id          uuid        primary key default gen_random_uuid(),
  post_id     uuid        not null references blog_posts(id) on delete cascade,
  identifier  text        not null,   -- hashed device fingerprint
  created_at  timestamptz not null default now(),
  unique (post_id, identifier)
);

-- ============================================================
-- ADS
-- ============================================================
create table if not exists blog_ads (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null,
  body_html   text        not null,   -- custom HTML/image/text ad content
  image_url   text,
  link_url    text,
  placement   text        not null default 'between_posts', -- 'between_posts'|'sidebar'|'top_banner'
  position    integer     not null default 0,  -- ordering hint
  active      boolean     not null default true,
  clicks      integer     not null default 0,
  impressions integer     not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ============================================================
-- SITE SETTINGS  (key-value store for all toggles)
-- ============================================================
create table if not exists site_settings (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);

-- Seed default settings (safe — ON CONFLICT ignores existing)
insert into site_settings (key, value) values
  ('show_views',            'true'::jsonb),
  ('show_comments',         'true'::jsonb),
  ('show_likes',            'true'::jsonb),
  ('show_comment_count',    'true'::jsonb),
  ('comments_require_moderation', 'true'::jsonb),
  ('ads_enabled',           'true'::jsonb),
  ('animation_speed',       '"normal"'::jsonb),    -- 'slow' | 'normal' | 'fast'
  ('animation_style',       '"slide"'::jsonb),     -- 'slide' | 'fade' | 'zoom' | 'rotate'
  ('hero_animation',        'true'::jsonb),
  ('scroll_progress',       'true'::jsonb),
  ('cursor_effect',         'true'::jsonb),
  ('particle_bg',           'false'::jsonb),
  ('site_title',            '"Evans Onyango"'::jsonb),
  ('site_tagline',          '"Accounting & Financial Systems Strategist"'::jsonb)
on conflict (key) do nothing;

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_blog_posts_created  on blog_posts(created_at desc);
create index if not exists idx_blog_posts_published on blog_posts(published);
create index if not exists idx_blog_comments_post  on blog_comments(post_id);
create index if not exists idx_blog_comments_status on blog_comments(status);
create index if not exists idx_blog_likes_post     on blog_likes(post_id);
create index if not exists idx_blog_ads_active     on blog_ads(active, placement);
create index if not exists idx_blog_files_post     on blog_files(post_id);

-- ============================================================
-- TRIGGERS — auto updated_at
-- ============================================================
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists blog_posts_updated_at on blog_posts;
create trigger blog_posts_updated_at before update on blog_posts
  for each row execute function set_updated_at();

drop trigger if exists blog_ads_updated_at on blog_ads;
create trigger blog_ads_updated_at before update on blog_ads
  for each row execute function set_updated_at();

drop trigger if exists site_settings_updated_at on site_settings;
create trigger site_settings_updated_at before update on site_settings
  for each row execute function set_updated_at();

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================
create or replace function increment_blog_views(post_id uuid)
returns void language sql security definer as $$
  update blog_posts set views = views + 1 where id = post_id;
$$;

create or replace function increment_ad_impression(ad_id uuid)
returns void language sql security definer as $$
  update blog_ads set impressions = impressions + 1 where id = ad_id;
$$;

create or replace function increment_ad_click(ad_id uuid)
returns void language sql security definer as $$
  update blog_ads set clicks = clicks + 1 where id = ad_id;
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table blog_posts     enable row level security;
alter table blog_files     enable row level security;
alter table blog_comments  enable row level security;
alter table blog_likes     enable row level security;
alter table blog_ads       enable row level security;
alter table site_settings  enable row level security;

-- DROP old policies if re-running
do $$ begin
  drop policy if exists "pub_read_posts"     on blog_posts;
  drop policy if exists "admin_all_posts"    on blog_posts;
  drop policy if exists "pub_read_files"     on blog_files;
  drop policy if exists "admin_all_files"    on blog_files;
  drop policy if exists "pub_read_comments"  on blog_comments;
  drop policy if exists "pub_insert_comment" on blog_comments;
  drop policy if exists "admin_all_comments" on blog_comments;
  drop policy if exists "pub_read_likes"     on blog_likes;
  drop policy if exists "pub_insert_likes"   on blog_likes;
  drop policy if exists "admin_all_likes"    on blog_likes;
  drop policy if exists "pub_read_ads"       on blog_ads;
  drop policy if exists "admin_all_ads"      on blog_ads;
  drop policy if exists "pub_read_settings"  on site_settings;
  drop policy if exists "admin_all_settings" on site_settings;
exception when others then null;
end; $$;

-- blog_posts
create policy "pub_read_posts"  on blog_posts for select using (published = true);
create policy "admin_all_posts" on blog_posts for all   using (auth.uid() is not null) with check (auth.uid() is not null);

-- blog_files
create policy "pub_read_files"  on blog_files for select using (
  exists (select 1 from blog_posts where id = blog_files.post_id and published = true)
);
create policy "admin_all_files" on blog_files for all using (auth.uid() is not null) with check (auth.uid() is not null);

-- blog_comments
create policy "pub_read_comments"  on blog_comments for select using (status = 'approved');
create policy "pub_insert_comment" on blog_comments for insert with check (true);
create policy "admin_all_comments" on blog_comments for all using (auth.uid() is not null) with check (auth.uid() is not null);

-- blog_likes
create policy "pub_read_likes"   on blog_likes for select using (true);
create policy "pub_insert_likes" on blog_likes for insert with check (true);
create policy "admin_all_likes"  on blog_likes for all using (auth.uid() is not null) with check (auth.uid() is not null);

-- blog_ads
create policy "pub_read_ads"   on blog_ads for select using (active = true);
create policy "admin_all_ads"  on blog_ads for all using (auth.uid() is not null) with check (auth.uid() is not null);

-- site_settings
create policy "pub_read_settings"  on site_settings for select using (true);
create policy "admin_all_settings" on site_settings for all using (auth.uid() is not null) with check (auth.uid() is not null);

-- ============================================================
-- STORAGE BUCKET — documents (covers + attachments + library)
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit)
values ('documents','documents', true, 524288000)
on conflict (id) do nothing;

do $$ begin
  drop policy if exists "pub_read_docs"    on storage.objects;
  drop policy if exists "auth_upload_docs" on storage.objects;
  drop policy if exists "auth_update_docs" on storage.objects;
  drop policy if exists "auth_delete_docs" on storage.objects;
exception when others then null;
end; $$;

create policy "pub_read_docs"    on storage.objects for select using (bucket_id = 'documents');
create policy "auth_upload_docs" on storage.objects for insert with check (bucket_id = 'documents' and auth.uid() is not null);
create policy "auth_update_docs" on storage.objects for update using (bucket_id = 'documents' and auth.uid() is not null);
create policy "auth_delete_docs" on storage.objects for delete using (bucket_id = 'documents' and auth.uid() is not null);

-- ============================================================
-- DONE
-- Next: Go to Supabase → Auth → Users → Add User (your admin email + password)
-- ============================================================
