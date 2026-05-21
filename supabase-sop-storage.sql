-- Supabase setup for mercado-sop-training/index.html
-- Run this file in Supabase SQL Editor once before enabling cloud sync.

create extension if not exists pgcrypto;

create table if not exists public.sop_documents (
  project_key text primary key,
  html_sidebar text not null,
  html_main text not null,
  active_panel text,
  active_row text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.sop_documents
  add column if not exists project_key text,
  add column if not exists html_sidebar text,
  add column if not exists html_main text,
  add column if not exists active_panel text,
  add column if not exists active_row text,
  add column if not exists payload jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sop_documents_project_key_uidx
  on public.sop_documents (project_key);

create table if not exists public.sop_media (
  id uuid primary key default gen_random_uuid(),
  project_key text not null,
  file_path text not null,
  public_url text not null,
  file_name text,
  content_type text,
  file_size bigint,
  panel_id text,
  row_id text,
  title text,
  note text,
  created_at timestamptz not null default now()
);

alter table public.sop_media
  add column if not exists id uuid default gen_random_uuid(),
  add column if not exists project_key text,
  add column if not exists file_path text,
  add column if not exists public_url text,
  add column if not exists file_name text,
  add column if not exists content_type text,
  add column if not exists file_size bigint,
  add column if not exists panel_id text,
  add column if not exists row_id text,
  add column if not exists title text,
  add column if not exists note text,
  add column if not exists created_at timestamptz not null default now();

create index if not exists sop_media_project_created_idx
  on public.sop_media (project_key, created_at desc);

create or replace function public.set_sop_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_sop_documents_updated_at on public.sop_documents;
create trigger set_sop_documents_updated_at
before update on public.sop_documents
for each row
execute function public.set_sop_updated_at();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'sop-media',
  'sop-media',
  true,
  10485760,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

alter table public.sop_documents enable row level security;
alter table public.sop_media enable row level security;

drop policy if exists "SOP documents public read" on public.sop_documents;
drop policy if exists "SOP documents public insert" on public.sop_documents;
drop policy if exists "SOP documents public update" on public.sop_documents;
drop policy if exists "SOP media public read" on public.sop_media;
drop policy if exists "SOP media public insert" on public.sop_media;

create policy "SOP documents public read"
on public.sop_documents
for select
to anon, authenticated
using (true);

create policy "SOP documents public insert"
on public.sop_documents
for insert
to anon, authenticated
with check (true);

create policy "SOP documents public update"
on public.sop_documents
for update
to anon, authenticated
using (true)
with check (true);

create policy "SOP media public read"
on public.sop_media
for select
to anon, authenticated
using (true);

create policy "SOP media public insert"
on public.sop_media
for insert
to anon, authenticated
with check (true);

drop policy if exists "SOP storage public read" on storage.objects;
drop policy if exists "SOP storage public upload" on storage.objects;
drop policy if exists "SOP storage public update" on storage.objects;
drop policy if exists "SOP storage public delete" on storage.objects;

create policy "SOP storage public read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'sop-media');

create policy "SOP storage public upload"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'sop-media');

create policy "SOP storage public update"
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'sop-media')
with check (bucket_id = 'sop-media');

create policy "SOP storage public delete"
on storage.objects
for delete
to anon, authenticated
using (bucket_id = 'sop-media');

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.sop_documents to anon, authenticated;
grant select, insert on public.sop_media to anon, authenticated;
