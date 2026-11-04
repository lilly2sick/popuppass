# Pop-Up Pass app (Flutter)

Spec: [../docs/SPEC.md](../docs/SPEC.md). Backend: [../supabase](../supabase).

## First run

Platform folders (`ios/`, `android/`) are committed. Fetch packages, generate Drift code and run:

```sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift; *.g.dart is gitignored
flutter test
flutter run            # USE_FAKES defaults to true: sample shop, no keys
```

Toolchain used in CI and when the branch was built: Flutter 3.47.9, Dart 3.13.7 (SDK floor
`>=3.9.0`). Major versions of the dependencies are pinned in `pubspec.yaml`; `pubspec.lock` is
committed.

## Checks

Run in this order. Format comes before `build_runner` because Drift writes an unformatted
`database.g.dart` that is gitignored.

```sh
flutter pub get
dart format --set-exit-if-changed .
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

`flutter test` also renders each tab at 390x844 (3x) with real fonts into
`../docs/screenshots/`. If rendering differs on your machine the PNGs change; commit them or
`git checkout ../docs/screenshots`. Strings live in `lib/l10n/app_en.arb`; run `flutter gen-l10n`
after editing it.

## Running against a backend

```sh
flutter run --dart-define=USE_FAKES=false \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=RC_APPLE_KEY=... --dart-define=RC_GOOGLE_KEY=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=... --dart-define=SQUARE_APP_ID=... \
  --dart-define=META_APP_ID=...
```

`SUPABASE_ANON_KEY` takes the project's publishable key. `META_APP_ID` is optional: without it
Instagram and Facebook sharing falls back to the system share sheet. Never commit these values.

Platform setup that needs accounts (Sign in with Apple capability, Google client ids, RevenueCat
products for the `pro` entitlement, Square application) is listed in the pull request checklist.
Permission strings for photos and camera and the Android permissions are already in the
manifests.

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
