# Pop-Up Pass

Offline-first Flutter app for pop-up shop vendors, with an optional Supabase backend.

| Folder | What it is |
| --- | --- |
| [app/](app) | The Flutter app (see [app/README.md](app/README.md)) |
| [supabase/](supabase) | Postgres schema with RLS, pgTAP tests, Deno Edge Functions (see [supabase/README.md](supabase/README.md)) |
| [codespace/](codespace) | Static HTML/JS/CSS prototype, no build step |
| [docs/](docs) | Spec, backend function reference, design, screenshots |

## Prerequisites

| Tool | Needed for |
| --- | --- |
| Python or Node | Static prototype |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) (CI used 3.47.9, Dart `>=3.9.0`) | The app |
| [Supabase CLI](https://supabase.com/docs/guides/cli) and a free Supabase project | Online backend |
| Docker Desktop | Only for a local Supabase stack (`supabase start`) |
| Deno | Only for Edge Function checks |

## 1. Quickest preview: static prototype

```sh
cd codespace
python -m http.server 8080
```

Open http://localhost:8080. This is not the Flutter app.

## 2. Run the real app with fake data (no backend, no keys)

`USE_FAKES` defaults to true and loads a sample shop.

```sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome      # or -d windows, or an Android emulator
```

Notes:

- Only `ios/` and `android/` are committed. If you want web or Windows and the build asks for it, run
  `flutter create --platforms=windows,web .` inside `app/`. Web support (Drift/SQLite) is untested.
- `flutter test` also regenerates the screenshots in `docs/screenshots/`.

## 3. Run the full system online (Supabase plus app)

1. Create a project at supabase.com, then:
   ```sh
   supabase login
   supabase link --project-ref <ref>
   supabase db push                        # applies supabase/migrations
   supabase secrets set CRON_SECRET=... ANTHROPIC_API_KEY=...
   supabase functions deploy
   ```
   Other secrets (RevenueCat, Square, Reddit, Etsy, Pinterest) are listed in
   [supabase/README.md](supabase/README.md) and only needed for those features.
2. In the Supabase dashboard (Integrations, Cron) create daily HTTP jobs for `keep-alive`,
   `fetch-cons` and `build-trends` with header `Authorization: Bearer <CRON_SECRET>`. See
   [docs/BACKEND_FUNCTIONS.md](docs/BACKEND_FUNCTIONS.md).
3. Point the app at the backend:
   ```sh
   cd app
   flutter run -d chrome --dart-define=USE_FAKES=false \
     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<publishable key>
   ```
   Apple/Google sign-in, RevenueCat (Pro) and Square need accounts and platform setup; skip them for a
   first test. Never commit keys.
4. To host the app on the web: `flutter build web`, then deploy `app/build/web` to Netlify, Vercel or
   Firebase Hosting.

### Local backend instead of cloud

```sh
supabase start
supabase db reset
supabase functions serve --env-file supabase/functions/.env   # .env is never committed
```

Needs Docker. Without Docker, `scripts/pgtap-local.sh` runs only the database tests, on Linux x64 (use WSL).

## Checks

```sh
# app
cd app && dart format --set-exit-if-changed . && flutter analyze && flutter test

# edge functions
cd supabase/functions && deno task check && deno lint && deno fmt --check && deno task test

# database (needs docker)
supabase test db
```

More: [docs/SPEC.md](docs/SPEC.md), [docs/LOCAL_DB_TESTS.md](docs/LOCAL_DB_TESTS.md).
