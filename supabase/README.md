# Pop-Up Pass backend (Supabase)

Optional by design: the app is offline-first and free users never send data here. This folder holds
the Postgres schema with row level security, pgTAP tests, and the Edge Functions.

| Path | What lives there |
|---|---|
| `migrations/` | Schema, RLS policies, storage policies, views. Applied in filename order |
| `tests/` | pgTAP tests (`rls_test.sql`): user A vs user B, anon, storage, views, lapsed Pro |
| `functions/` | Deno Edge Functions, see [../docs/BACKEND_FUNCTIONS.md](../docs/BACKEND_FUNCTIONS.md) |
| `config.toml` | Local stack config; `verify_jwt` is off only for cron and webhook functions |

Row level security is a hard requirement. Never weaken a policy to make a test pass.

## Local development

Needs the [Supabase CLI](https://supabase.com/docs/guides/cli) (3.0.0 used here) and docker.

```sh
supabase start
supabase db reset        # applies migrations/, seeding is disabled
supabase test db         # pgTAP
supabase db lint --fail-on error
supabase functions serve --env-file supabase/functions/.env   # .env is never committed
supabase stop
```

Without docker, `scripts/pgtap-local.sh` runs the same pgTAP files against a throwaway embedded
Postgres. See [../docs/LOCAL_DB_TESTS.md](../docs/LOCAL_DB_TESTS.md). CI uses the real CLI.

## Edge Function checks

```sh
cd supabase/functions
deno task check && deno lint && deno fmt --check && deno task test
```

Tests inject fakes and mocked `fetch`; no network, no keys.

## Secrets

Set with `supabase secrets set NAME=value` on the cloud project. `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` are provided by the platform.

| Secret | Used by | Required |
|---|---|---|
| `ANTHROPIC_API_KEY` | `ai` | for Pro AI |
| `CRON_SECRET` | `build-trends`, `fetch-cons`, `keep-alive` | yes |
| `REVENUECAT_WEBHOOK_SECRET` | `revenuecat-webhook` | yes |
| `SQUARE_APP_ID`, `SQUARE_APP_SECRET`, `SQUARE_ENV` | `square-token` | for Square |
| `ANIMECONS_FEED_URL` | `fetch-cons` | when AnimeCons provides a feed |
| `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET` | trend connector | optional, needs approval |
| `ETSY_API_KEY` | trend connector | optional, needs approval |
| `PINTEREST_ACCESS_TOKEN`, `PINTEREST_REGION` | trend connector | optional, needs approval |
| `GOOGLE_TRENDS_API_KEY` | trend connector | optional, placeholder |

## Cloud deploy

```sh
supabase link --project-ref <ref>
supabase db push
supabase functions deploy
```

Then create the daily cron jobs described in the scheduling section of
[../docs/BACKEND_FUNCTIONS.md](../docs/BACKEND_FUNCTIONS.md) so the free tier does not pause.
