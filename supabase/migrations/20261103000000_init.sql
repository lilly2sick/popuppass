-- Pop-Up Pass initial schema. Default deny everywhere; see docs/SPEC.md §13.
--
-- Cloud tables mirror the device's syncable tables plus user_id. Rows are
-- created on device (UUIDv7 ids), so there are no cross-table foreign keys
-- here: sync order is not guaranteed and the device enforces integrity.

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  display_name    text,
  is_pro          boolean not null default false,
  pro_expires_at  timestamptz,
  created_at      timestamptz not null default now()
);

-- New auth user -> profile row. Definer so it can write; search_path pinned.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Invoker rights: callers can only see their own profile, which is all it needs.
create function public.is_pro(uid uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    (select p.is_pro and (p.pro_expires_at is null or p.pro_expires_at > now())
       from public.profiles p where p.id = uid),
    false);
$$;

-- ---------------------------------------------------------------------------
-- user tables (synced from device)
-- ---------------------------------------------------------------------------
create table public.events (
  id               uuid primary key,
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name             text not null check (length(name) <= 200),
  starts_at        timestamptz not null,
  ends_at          timestamptz not null,
  venue            text,
  city             text,
  lat              double precision,
  lng              double precision,
  booth_fee_cents  integer not null default 0 check (booth_fee_cents >= 0),
  booth_label      text,
  source           text not null default 'manual' check (source in ('manual', 'square', 'csv', 'animecons', 'ics')),
  external_id      text,
  updated_at       timestamptz not null default now(),
  device_id        text,
  deleted          boolean not null default false
);

create table public.products (
  id                   uuid primary key,
  user_id              uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name                 text not null check (length(name) <= 200),
  sku                  text,
  price_cents          integer not null check (price_cents >= 0),
  unit_cost_cents      integer not null default 0 check (unit_cost_cents >= 0),
  minutes_to_make      integer,
  tags                 jsonb not null default '[]',
  photo_paths          jsonb not null default '[]',
  low_stock_threshold  integer not null default 3,
  square_item_id       text,
  archived             boolean not null default false,
  updated_at           timestamptz not null default now(),
  device_id            text,
  deleted              boolean not null default false
);

create table public.bom_lines (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id  uuid not null,
  material    text not null,
  qty         double precision not null default 1,
  unit        text,
  cost_cents  integer not null check (cost_cents >= 0),
  updated_at  timestamptz not null default now(),
  device_id   text,
  deleted     boolean not null default false
);

create table public.brands (
  id           uuid primary key,
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  shop_name    text not null,
  handle       text,
  colors       jsonb not null default '[]',
  logo_path    text,
  booth_label  text,
  niche_tags   jsonb not null default '[]',
  updated_at   timestamptz not null default now(),
  device_id    text,
  deleted      boolean not null default false
);

create table public.price_history (
  id           uuid primary key,
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id   uuid not null,
  price_cents  integer not null,
  at           timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  device_id    text,
  deleted      boolean not null default false
);

create table public.sales (
  id              uuid primary key,
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  event_id        uuid,
  sold_at         timestamptz not null,
  payment_method  text not null check (payment_method in ('cash', 'card', 'zelle', 'venmo', 'cashapp', 'paypal', 'other')),
  source          text not null default 'manual' check (source in ('manual', 'square', 'csv')),
  external_id     text,
  total_cents     integer not null,
  note            text,
  updated_at      timestamptz not null default now(),
  device_id       text,
  deleted         boolean not null default false
);

create table public.sale_lines (
  id                uuid primary key,
  user_id           uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sale_id           uuid not null,
  product_id        uuid,
  external_name     text,
  qty               integer not null,
  unit_price_cents  integer not null,
  unit_cost_cents   integer not null,
  updated_at        timestamptz not null default now(),
  device_id         text,
  deleted           boolean not null default false
);

create table public.inventory_moves (
  id            uuid primary key,
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id    uuid not null,
  event_id      uuid,
  delta         integer not null,
  reason        text not null check (reason in ('restock', 'sale', 'adjust', 'voided')),
  sale_line_id  uuid,
  at            timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  device_id     text,
  deleted       boolean not null default false
);

create unique index sales_user_source_external on public.sales (user_id, source, external_id) where external_id is not null;
create index events_user on public.events (user_id);
create index products_user on public.products (user_id);
create index bom_lines_user on public.bom_lines (user_id);
create index brands_user on public.brands (user_id);
create index price_history_user on public.price_history (user_id);
create index sales_user_event on public.sales (user_id, event_id, sold_at);
create index sale_lines_user on public.sale_lines (user_id);
create index inventory_moves_user on public.inventory_moves (user_id, product_id);

-- ---------------------------------------------------------------------------
-- public, read-only feeds (written only by Edge Functions with service role)
-- ---------------------------------------------------------------------------
create table public.cons (
  external_id  text primary key,
  name         text not null,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  venue        text,
  city         text,
  region       text,
  country      text,
  lat          double precision,
  lng          double precision,
  url          text,
  fetched_at   timestamptz not null default now()
);

create table public.trends (
  id                text primary key,
  keyword           text not null,
  niche             text not null,
  score             double precision not null,
  velocity          double precision not null,
  title             text not null,
  why               text not null,
  item_idea         text,
  sources           jsonb not null default '[]',
  snapshot_version  text not null,
  built_at          timestamptz not null default now()
);

-- Raw connector output. Service role only: no grants, no policies.
create table public.signals_raw (
  id           bigint generated always as identity primary key,
  source       text not null,
  keyword      text not null,
  niche        text,
  value        double precision not null,
  observed_at  timestamptz not null,
  meta         jsonb not null default '{}'
);
create index signals_raw_keyword_time on public.signals_raw (keyword, observed_at);

-- ---------------------------------------------------------------------------
-- privileges: revoke Supabase's broad defaults, then grant exactly
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated, public;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated, public;

grant execute on function public.is_pro(uuid) to authenticated;

grant select on public.cons, public.trends to anon, authenticated;

-- profiles: read own; only display_name is client-writable.
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

-- synced tables: client never writes user_id (it defaults to auth.uid()).
do $$
declare
  t text;
begin
  foreach t in array array['events', 'products', 'bom_lines', 'brands', 'price_history', 'sales', 'sale_lines', 'inventory_moves']
  loop
    execute format('grant select, delete on public.%I to authenticated', t);
    execute format(
      'grant insert (%1$s), update (%1$s) on public.%2$I to authenticated',
      (select string_agg(quote_ident(column_name), ', ')
         from information_schema.columns
        where table_schema = 'public' and table_name = t and column_name <> 'user_id'),
      t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- row level security: enabled AND forced on every table
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);
  end loop;
end;
$$;

create policy "profiles: read own" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "cons: public read" on public.cons for select to anon, authenticated using (true);
create policy "trends: public read" on public.trends for select to anon, authenticated using (true);

-- Owner can always read and delete their rows (a lapsed Pro can still export).
-- Writes additionally require an active Pro entitlement.
do $$
declare
  t text;
begin
  foreach t in array array['events', 'products', 'bom_lines', 'brands', 'price_history', 'sales', 'sale_lines', 'inventory_moves']
  loop
    execute format($f$
      create policy "%1$s: read own" on public.%1$I
        for select to authenticated
        using (user_id = (select auth.uid()))$f$, t);
    execute format($f$
      create policy "%1$s: insert own (pro)" on public.%1$I
        for insert to authenticated
        with check (user_id = (select auth.uid()) and public.is_pro((select auth.uid())))$f$, t);
    execute format($f$
      create policy "%1$s: update own (pro)" on public.%1$I
        for update to authenticated
        using (user_id = (select auth.uid()))
        with check (user_id = (select auth.uid()) and public.is_pro((select auth.uid())))$f$, t);
    execute format($f$
      create policy "%1$s: delete own" on public.%1$I
        for delete to authenticated
        using (user_id = (select auth.uid()))$f$, t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- views: invoker rights so RLS applies to the caller
-- ---------------------------------------------------------------------------
create view public.product_stock with (security_invoker = true) as
  select user_id, product_id, sum(delta)::integer as on_hand
    from public.inventory_moves
   where not deleted
   group by user_id, product_id;
grant select on public.product_stock to authenticated;

-- ---------------------------------------------------------------------------
-- storage: private photos bucket, one folder per user ({uid}/...)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "photos: read own" on storage.objects
  for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "photos: insert own (pro)" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.is_pro((select auth.uid())));

create policy "photos: update own (pro)" on storage.objects
  for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.is_pro((select auth.uid())));

create policy "photos: delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
-- AI usage ledger for rate limits (service role only)
-- ---------------------------------------------------------------------------
create table public.ai_usage (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  kind        text not null,
  created_at  timestamptz not null default now()
);
create index ai_usage_user_time on public.ai_usage (user_id, created_at);
alter table public.ai_usage enable row level security;
alter table public.ai_usage force row level security;
