-- RLS tests. Run with: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

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

-- ---- user B (free) ----
select pg_temp.act_as('bbbbbbbb-0000-0000-0000-000000000002');

select is((select count(*)::int from public.products), 0, 'B cannot see A products');
select is((select count(*)::int from public.sales), 0, 'B cannot see A sales');
select is((select count(*)::int from public.profiles), 1, 'B sees only own profile');

select throws_ok(
  $$ insert into public.products (id, name, price_cents) values ('11111111-0000-0000-0000-000000000002', 'Frog pin', 1200) $$,
  '42501', null, 'free user cannot write sync tables');

update public.products set name = 'hacked' where id = '11111111-0000-0000-0000-000000000001';
delete from public.products where id = '11111111-0000-0000-0000-000000000001';

select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('photos', 'aaaaaaaa-0000-0000-0000-000000000001/x.jpg') $$,
  '42501', null, 'B cannot upload into A photo folder');

-- ---- anon ----
select pg_temp.act_as_anon();

select throws_ok($$ select * from public.products $$, '42501', null, 'anon cannot read products');
select throws_ok($$ select * from public.profiles $$, '42501', null, 'anon cannot read profiles');
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
  '42501', null, 'lapsed pro cannot write, but rows remain readable');

select * from finish();
rollback;
