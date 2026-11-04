-- Local-only stand-ins for roles, auth and storage so the migrations and
-- supabase/tests can run on a plain Postgres. Not a substitute for Supabase;
-- CI uses the real supabase CLI (supabase db reset, supabase test db).
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema if not exists extensions;
grant usage on schema extensions, public to anon, authenticated, service_role;
-- Minimal stand-ins for the parts of Supabase's auth/storage schemas our
-- migration and pgTAP tests touch. Not a substitute for the real platform.
create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text,
  aud text,
  role text,
  created_at timestamptz not null default now()
);

create or replace function auth.uid() returns uuid
  language sql stable as $$
    select (nullif(current_setting('request.jwt.claims', true), '')::json ->> 'sub')::uuid;
$$;

create schema if not exists storage;
create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text,
  owner uuid,
  created_at timestamptz not null default now()
);
alter table storage.objects enable row level security;

create or replace function storage.foldername(name text) returns text[]
  language sql immutable as $$
    select string_to_array(name, '/');
$$;

grant usage on schema auth, storage to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant execute on function storage.foldername(text) to anon, authenticated, service_role;
grant select on storage.buckets to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
