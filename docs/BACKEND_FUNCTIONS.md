# Edge Functions

All functions live in `supabase/functions/<name>/`. `index.ts` only wires real dependencies into
`createHandler(...)` from `handler.ts`; every behaviour is tested against injected fakes and
mocked `fetch` in `handler_test.ts`.

| Function | Caller | Auth | Purpose |
| --- | --- | --- | --- |
| `ai` | app (Pro) | user JWT, Pro check, 100 per day | captions, hashtags, summaries, restock ideas |
| `build-trends` | cron | `CRON_SECRET` bearer | collect signals, score, write cards, publish `trends` |
| `fetch-cons` | cron | `CRON_SECRET` bearer | refresh `cons` from the AnimeCons feed (stub until a feed exists, never scrapes) |
| `keep-alive` | cron | `CRON_SECRET` bearer | one cheap query so the free tier never pauses |
| `revenuecat-webhook` | RevenueCat | `REVENUECAT_WEBHOOK_SECRET` bearer | only writer of `profiles.is_pro` |
| `square-token` | app | user JWT (gateway) | Square OAuth code exchange and refresh |
| `delete-account` | app | user JWT | removes photos then the auth user |

## Trend sources

`_shared/signals.ts` defines `SignalConnector`; `_shared/aggregator.ts` runs them and
`_shared/scoring.ts` ranks keywords by velocity. One connector per file in `_shared/connectors/`.
`registry.ts` decides what runs; sources that need an approved account stay off until configured.

| Source | Enabled by |
| --- | --- |
| curated, AniList | always |
| Reddit | `REDDIT_CLIENT_ID` and `REDDIT_CLIENT_SECRET` |
| Etsy | `ETSY_API_KEY` |
| Pinterest | `PINTEREST_ACCESS_TOKEN` (optional `PINTEREST_REGION`) |
| Google Trends | `GOOGLE_TRENDS_API_KEY` (inert placeholder until the API shape is known) |

## Scheduling and the free-tier pause

Supabase free projects pause after 7 days of inactivity. In the dashboard (Integrations, Cron)
create daily HTTP jobs with header `Authorization: Bearer <CRON_SECRET>` for `keep-alive`,
`fetch-cons` and `build-trends`. `keep-alive` is the safety net: it touches the database even when
the other two have nothing to do.

## Checks

```sh
cd supabase/functions
deno task check   # type-check every entrypoint, handler and shared module
deno task test    # deno test --allow-env
deno lint && deno fmt --check
```
