-- RLS tests. Run with: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(60);

-- Two users. A is Pro, B is free.
insert into auth.users (id, email, aud, role)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'a@test.local', 'authenticated', 'authenticated'),
       ('bbbbbbbb-0000-0000-0000-000000000002', 'b@test.local', 'authenticated', 'authenticated');
update public.profiles set is_pro = true where id = 'aaaaaaaa-0000-0000-0000-000000000001';

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;
create function pg_temp.act_as_anon() returns void language sql as $$
  select set_config('role', 'anon', true),
         set_config('request.jwt.claims', '{"role":"anon"}', true);
$$;

-- 1. Every public table has RLS enabled and forced.
select is_empty(
  $$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r'
        and not (c.relrowsecurity and c.relforcerowsecurity) $$,
  'every public table has forced RLS');


-- 1b. Each user table has exactly select/insert/update/delete policies, all to authenticated.
select is_empty(
  $$ select tablename from pg_policies
      where schemaname = 'public'
        and tablename in ('events', 'products', 'bom_lines', 'brands', 'price_history', 'sales', 'sale_lines', 'inventory_moves')
      group by tablename
     having count(*) <> 4 or count(distinct cmd) <> 4 or bool_or(roles <> '{authenticated}') $$,
  'user tables have four per-command policies, all to authenticated');

-- 1c. anon holds no table privilege other than select on cons and trends.
select is_empty(
  $$ select c.relname, p.priv
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      cross join (values ('select'), ('insert'), ('update'), ('delete'), ('truncate'), ('references'), ('trigger')) as p(priv)
      where n.nspname = 'public' and c.relkind in ('r', 'v')
        and has_table_privilege('anon', c.oid, p.priv)
        and not (c.relname in ('cons', 'trends') and p.priv = 'select') $$,
  'anon has no table grants except select on cons and trends');

-- 1d. Service-only tables expose nothing to clients.
select is_empty(
  $$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname in ('signals_raw', 'ai_usage')
        and (has_table_privilege('authenticated', c.oid, 'select')
          or has_table_privilege('authenticated', c.oid, 'insert')
          or has_table_privilege('anon', c.oid, 'select')) $$,
  'service-only tables have no client grants');

-- 1e. Every SECURITY DEFINER function pins an empty search_path.
select is_empty(
  $$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prosecdef
        and not coalesce(p.proconfig @> array['search_path=""'], false) $$,
  'every security definer function sets search_path to empty');

-- 1f. Every public view is security_invoker.
select is_empty(
  $$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'v'
        and not coalesce(c.reloptions @> array['security_invoker=true'], false) $$,
  'every public view is security_invoker');

-- 1g. Photos bucket is private; is_pro() is not callable by anon.
select is((select public from storage.buckets where id = 'photos'), false, 'photos bucket is private');
select ok(not has_function_privilege('anon', 'public.is_pro(uuid)', 'execute'), 'anon cannot execute is_pro');

-- Helper: rows visible to the current role in storage.objects, 0 when the role has no grant at all.
create function pg_temp.visible_objects() returns int language plpgsql as $$
begin
  return (select count(*)::int from storage.objects);
exception when insufficient_privilege then
  return 0;
end;
$$;

-- ---- user A (Pro) ----
select pg_temp.act_as('aaaaaaaa-0000-0000-0000-000000000001');

select lives_ok(
  $$ insert into public.products (id, name, price_cents) values ('11111111-0000-0000-0000-000000000001', 'Cat sticker', 700) $$,
  'pro user can insert own product');

select is((select count(*)::int from public.products), 1, 'pro user sees own product');

select is((select user_id from public.products limit 1), 'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
  'user_id defaults to auth.uid()');

select throws_ok(
  $$ insert into public.products (id, user_id, name, price_cents)
     values ('11111111-0000-0000-0000-000000000009', 'bbbbbbbb-0000-0000-0000-000000000002', 'Spoof', 1) $$,
  '42501', null, 'client cannot write user_id (no column grant)');

select throws_ok(
  $$ update public.profiles set is_pro = false where id = 'aaaaaaaa-0000-0000-0000-000000000001' $$,
  '42501', null, 'client cannot change is_pro');

select lives_ok(
  $$ update public.profiles set display_name = 'Lilly' where id = 'aaaaaaaa-0000-0000-0000-000000000001' $$,
  'client can change own display_name');

select lives_ok(
  $$ insert into public.sales (id, sold_at, payment_method, total_cents)
     values ('22222222-0000-0000-0000-000000000001', now(), 'cash', 700) $$,
  'pro user can insert own sale');

select throws_ok(
  $$ insert into public.sales (id, sold_at, payment_method, total_cents)
     values ('22222222-0000-0000-0000-000000000002', now(), 'bitcoin', 700) $$,
  '23514', null, 'payment_method is constrained');

select lives_ok(
  $$ insert into public.inventory_moves (id, product_id, delta, reason)
     values ('33333333-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 5, 'restock') $$,
  'pro user can insert own inventory move');
select is((select on_hand from public.product_stock), 5, 'product_stock view shows own stock');

select throws_ok(
  $$ update public.products set user_id = 'bbbbbbbb-0000-0000-0000-000000000002' where id = '11111111-0000-0000-0000-000000000001' $$,
  '42501', null, 'client cannot reassign user_id on update');

select lives_ok(
  $$ update public.products set price_cents = 800 where id = '11111111-0000-0000-0000-000000000001' $$,
  'pro user can update own product');
select is((select price_cents from public.products where id = '11111111-0000-0000-0000-000000000001'), 800,
  'own update took effect');

select throws_ok($$ insert into public.profiles (id) values (gen_random_uuid()) $$, '42501', null,
  'client cannot insert profiles');
select throws_ok($$ delete from public.profiles $$, '42501', null, 'client cannot delete profiles');
select throws_ok($$ update public.trends set score = 99 $$, '42501', null, 'client cannot write trends');
select throws_ok($$ insert into public.cons (external_id, name, starts_at, ends_at) values ('x', 'x', now(), now()) $$,
  '42501', null, 'client cannot write cons');
select throws_ok($$ select * from public.ai_usage $$, '42501', null, 'client cannot read ai_usage');
select throws_ok($$ select * from public.signals_raw $$, '42501', null, 'client cannot read signals_raw');

select lives_ok(
  $$ insert into storage.objects (bucket_id, name, owner) values ('photos', 'aaaaaaaa-0000-0000-0000-000000000001/x.jpg', 'aaaaaaaa-0000-0000-0000-000000000001') $$,
  'pro user can upload into own photo folder');
select is(pg_temp.visible_objects(), 1, 'pro user sees own photo');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('photos', 'bbbbbbbb-0000-0000-0000-000000000002/x.jpg') $$,
  '42501', null, 'pro user cannot upload into another user folder');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('other', 'aaaaaaaa-0000-0000-0000-000000000001/x.jpg') $$,
  '42501', null, 'pro user cannot upload into a different bucket');

-- ---- seed a row owned by free user B (as superuser) ----
reset role;
insert into public.products (id, user_id, name, price_cents)
values ('11111111-0000-0000-0000-0000000000b1', 'bbbbbbbb-0000-0000-0000-000000000002', 'B keychain', 500);

-- ---- user B (free) ----
select pg_temp.act_as('bbbbbbbb-0000-0000-0000-000000000002');

select is((select count(*)::int from public.products where user_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B cannot see A products');
select is((select count(*)::int from public.sales), 0, 'B cannot see A sales');
select is((select count(*)::int from public.profiles), 1, 'B sees only own profile');

select throws_ok(
  $$ insert into public.products (id, name, price_cents) values ('11111111-0000-0000-0000-000000000002', 'Frog pin', 1200) $$,
  '42501', null, 'free user cannot write sync tables');


select is((select count(*)::int from public.product_stock), 0, 'B cannot see A stock through the view');
select is(pg_temp.visible_objects(), 0, 'B cannot see A photos');

select is_empty(
  $$ with u as (update public.products set name = 'hacked' where id = '11111111-0000-0000-0000-000000000001' returning 1) select * from u $$,
  'B update of A row matches no rows');
select is_empty(
  $$ with d as (delete from public.products where id = '11111111-0000-0000-0000-000000000001' returning 1) select * from d $$,
  'B delete of A row matches no rows');
select is_empty(
  $$ with d as (delete from storage.objects where name like 'aaaaaaaa-%' returning 1) select * from d $$,
  'B delete of A photo matches no rows');

select is((select count(*)::int from public.products), 1, 'free user can still read own rows');
select throws_ok(
  $$ update public.products set name = 'edited' where id = '11111111-0000-0000-0000-0000000000b1' $$,
  '42501', null, 'free user cannot update own rows');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('photos', 'bbbbbbbb-0000-0000-0000-000000000002/x.jpg') $$,
  '42501', null, 'free user cannot upload into own photo folder');
select lives_ok($$ delete from public.products where id = '11111111-0000-0000-0000-0000000000b1' $$,
  'free user can delete own rows');
select is((select count(*)::int from public.products), 0, 'own delete took effect');

select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('photos', 'aaaaaaaa-0000-0000-0000-000000000001/x.jpg') $$,
  '42501', null, 'B cannot upload into A photo folder');

-- ---- anon ----
select pg_temp.act_as_anon();

select throws_ok($$ select * from public.products $$, '42501', null, 'anon cannot read products');
select throws_ok($$ select * from public.profiles $$, '42501', null, 'anon cannot read profiles');
select throws_ok($$ insert into public.products (id, name, price_cents) values (gen_random_uuid(), 'x', 1) $$,
  '42501', null, 'anon cannot insert products');
select throws_ok($$ select * from public.product_stock $$, '42501', null, 'anon cannot read the stock view');
select throws_ok($$ insert into public.trends (id, keyword, niche, score, velocity, title, why, snapshot_version) values ('x', 'x', 'x', 1, 1, 'x', 'x', 'x') $$,
  '42501', null, 'anon cannot write trends');
select is(pg_temp.visible_objects(), 0, 'anon sees no photos');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('photos', 'aaaaaaaa-0000-0000-0000-000000000001/y.jpg') $$,
  '42501', null, 'anon cannot upload photos');
select lives_ok($$ select * from public.trends $$, 'anon can read trends');
select lives_ok($$ select * from public.cons $$, 'anon can read cons');

-- ---- back to superuser to check B's update/delete did nothing ----
reset role;
select is((select name from public.products where id = '11111111-0000-0000-0000-000000000001'), 'Cat sticker',
  'B update on A row affected nothing');

-- ---- lapsed Pro: read yes, write no ----
update public.profiles set pro_expires_at = now() - interval '1 day' where id = 'aaaaaaaa-0000-0000-0000-000000000001';
select pg_temp.act_as('aaaaaaaa-0000-0000-0000-000000000001');
select throws_ok(
  $$ insert into public.products (id, name, price_cents) values ('11111111-0000-0000-0000-000000000003', 'Late', 100) $$,
  '42501', null, 'lapsed pro cannot insert');
select throws_ok(
  $$ update public.products set price_cents = 900 where id = '11111111-0000-0000-0000-000000000001' $$,
  '42501', null, 'lapsed pro cannot update');
select is((select count(*)::int from public.products), 1, 'lapsed pro can still read and export');
select lives_ok($$ delete from public.products where id = '11111111-0000-0000-0000-000000000001' $$,
  'lapsed pro can still delete own rows');

select * from finish();
rollback;
