-- Opt-in aggregate sales contributions (SPEC 14). One row per user and keyword
-- per day, no amounts, no event or location. Written and read only by Edge
-- Functions with the service role; the SignalConnector reports a keyword only
-- when at least K distinct users contributed it.
create table public.trend_contributions (
  id           bigint generated always as identity primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  keyword      text not null,
  niche        text,
  units        integer not null check (units > 0),
  contributed  date not null default current_date,
  unique (user_id, keyword, contributed)
);
create index trend_contributions_keyword_day on public.trend_contributions (keyword, contributed);

revoke all on public.trend_contributions from anon, authenticated;
alter table public.trend_contributions enable row level security;
alter table public.trend_contributions force row level security;
