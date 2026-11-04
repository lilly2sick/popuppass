# Pop-Up Pass app (Flutter)

Spec: [../docs/SPEC.md](../docs/SPEC.md). Backend: [../supabase](../supabase).

## First run

This folder has `lib/`, `test/`, `assets/` and `pubspec.yaml` only. Generate the
platform folders once, then fetch packages and generate Drift code:

```sh
cd app
flutter create . --platforms=ios,android --org com.popuppass --project-name popup_pass
flutter pub get
flutter pub upgrade --major-versions   # package pins were written by hand
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run                            # USE_FAKES defaults to true: sample shop, no keys
```

With a backend:

```sh
flutter run --dart-define=USE_FAKES=false \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=RC_APPLE_KEY=... --dart-define=RC_GOOGLE_KEY=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=... --dart-define=SQUARE_APP_ID=...
```

Platform setup still to do after `flutter create`: Sign in with Apple capability,
Google Sign-In client ids, Photos permission strings (`NSPhotoLibraryAddUsageDescription`
for saving PNGs), and RevenueCat products for the `pro` entitlement.

## Layout

| Folder | What lives there |
|---|---|
| `app/` | Router, `AppShell` (tabs + PUP corner), `PPScaffold` base template |
| `design/` | Tokens, theme, shared components (grid background, event bar, pills, tiles, PUP, ASCII pups, lanyard loader) |
| `data/` | Drift tables, repositories, sample seed |
| `domain/` | Pricing, analytics, summaries, recommendations (pure Dart) |
| `connectors/` | `Connector` base + payment (Square, fake), events (AnimeCons feed, .ics), trends, AI, CSV |
| `services/` | Auth, purchases, entitlements, haptics, job runner, sync |
| `export/` | CSV, XLSX, PDF, PNG exporters |
| `render/` | Post formats, templates, exact-pixel PNG capture |
| `features/` | Screens |

Fonts (Ronzino, BDO Grotesk, both OFL) are bundled in `assets/fonts` so the app
looks right offline.
