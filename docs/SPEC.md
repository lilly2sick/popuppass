# Pop-Up Pass — Technical Spec

Status: approved direction, pre-build. Source of truth for the autonomous build.
Last updated: 2026-11-03.

## 1. Product

Phone-first toolkit for convention artists and pop-up vendors: price work, track stock and
sales at the table, see what sells and what profits, make posts and flyers at every platform
size, and get restock ideas from trend data.

Platforms: **iOS and Android** (Flutter). The marketing landing page stays a plain web site
(`codespace/`). Windows and Flutter web are out of scope for v1.

Hard rules:
- Offline first. The on-device SQLite database is the source of truth. No screen ever blocks
  on the network.
- No emojis anywhere: UI copy, templates, AI output (prompts forbid them), notifications. Use
  the icon set.
- No shared/group stock (the old "Collective" plan is dropped).
- Free tier never sends user data to our backend.

## 2. Tiers

| Capability | Free (no login) | Pro (subscription) |
|---|---|---|
| Events, products, BOM, time to make, inventory, sales, payment methods | Yes, on device | Yes, plus cloud backup and multi-device restore |
| Profit analytics, per-product breakdowns, local summaries | Yes | Yes |
| Post and flyer templates, all sizes, PNG export | Yes, manual caption (local templates) | Yes, plus AI caption, hashtags |
| AI event summary, AI restock ideas, trend alerts | No | Yes |
| Public trend feed, swipe deck (ranked on device) | Yes | Yes |
| Nearby cons (AnimeCons feed), ICS import/export | Yes | Yes |
| Square connector | Yes (tokens on device) | Yes |
| Exports | CSV, PNG | CSV, PNG, branded PDF, XLSX |

Free users only fetch two public static feeds: `events` (cons) and `trends`. They have no
backend identity.

## 3. Identity, purchases, entitlements

- **iOS:** Sign in with Apple. **Android:** Google Sign-In (Credential Manager). Both go to
  Supabase Auth via `signInWithIdToken`; identities are linked to one Supabase user so a person
  who switches platforms keeps one account.
- Sign-in is only offered when a user starts Pro (or restores on a new device). No email and
  password, no custom passkeys or 2FA: the platform account already provides biometric and 2FA.
- **RevenueCat** for App Store and Play subscriptions. Entitlement id: `pro`.
  After sign-in call `Purchases.logIn(supabaseUserId)`. "Restore purchases" is always available.
- RevenueCat webhook (Edge Function) is the only writer of `profiles.is_pro` / `pro_expires_at`.
- App store requirements: in-app **Delete account** (cascades all cloud data and storage
  folder). If any third-party login is offered on iOS, Sign in with Apple must be offered too.

## 4. Architecture

```
Flutter app (iOS, Android)
  app/         router, PPScaffold (base template), theme from design tokens
  design/      tokens + shared components
  data/        Drift (SQLite) tables, repositories
  domain/      PricingService, AnalyticsService, RecommendationService
  connectors/  Connector<TRaw,TModel> base + payment / events / trends / ai / csv
  services/    Auth, Purchases, Haptics, JobRunner (ai_jobs), SyncService (sync_outbox), Export
  features/    home, shop, sell, create, insights, events, settings
  render/      PostTemplate -> PNG at each format

Supabase (free tier for now)
  Auth (Apple, Google), Postgres + RLS, Storage (private photos), Edge Functions, pg_cron
  functions: ai, square-token, revenuecat-webhook, fetch-cons, build-trends
```

State/DI: Riverpod. Routing: go_router. The code is object oriented: abstract base classes for
repositories, connectors, exporters, templates; concrete subclasses per source. Every connector
has a `Fake*` implementation backed by sample data so the app runs fully offline with no keys.

Packages: flutter_riverpod, go_router, drift, drift_flutter, freezed, json_serializable, dio,
flutter_secure_storage, supabase_flutter, sign_in_with_apple, google_sign_in, purchases_flutter,
connectivity_plus, share_plus, image_picker, fl_chart, flutter_card_swiper, csv, excel, pdf,
printing, uuid, path_provider.

Supabase free-tier note: projects pause after 7 days of inactivity. Confirm the daily cron keeps
it active or add a keep-alive ping.

## 5. Offline-first data flow

- IDs are UUIDv7, generated on device. Every syncable row has `updated_at`, `device_id`,
  `deleted` (soft delete).
- Sales and inventory changes are **append-only ledgers** (`sales`, `sale_lines`,
  `inventory_moves`). Stock = sum of moves. Ledgers never conflict across devices.
- Editable entities (`events`, `products`, `bom_lines`, `brand`) sync last-write-wins per row.
- Two local queues, both tables:
  - `ai_jobs` (Pro): type, input json, status, result, attempts, next_attempt_at. The UI shows
    the local template result immediately; when the AI result lands it is offered as
    "AI version" and the user chooses. Numbers are always computed locally; AI only writes words.
  - `sync_outbox` (Pro): pending row changes to push.
- `JobRunner` drains queues on app start, on connectivity regained, and on a timer while
  foregrounded. Do not depend on iOS background execution.

## 6. Data model (device; cloud mirrors syncable tables with `user_id`)

- `events`: id, name, starts_at, ends_at, venue, city, lat, lng, booth_fee_cents, booth_label,
  source (`manual|animecons|ics`), external_id
- `products`: id, name, sku, price_cents, unit_cost_cents (derived from BOM if present),
  minutes_to_make, tags[], photo_paths[], low_stock_threshold, square_item_id, archived
- `bom_lines`: id, product_id, material, qty, unit, cost_cents
- `sales`: id, event_id, sold_at, payment_method
  (`cash|card|zelle|venmo|cashapp|paypal|other`), source (`manual|square|csv`), external_id
  (unique per source), total_cents, note
- `sale_lines`: id, sale_id, product_id (nullable until matched), qty, unit_price_cents,
  unit_cost_cents (snapshot at sale time)
- `inventory_moves`: id, product_id, event_id, delta, reason (`restock|sale|adjust|void`),
  sale_line_id, at
- `brand`: shop_name, handle, colors[], logo_path, booth_label
- `price_history`: product_id, price_cents, at
- Local only: `ai_jobs`, `sync_outbox`, `connector_cursors`, `trend_cache`, `swipe_feedback`

Analytics (all local SQL): gross, cost, net profit (+/-), units, per product (units, gross,
cost, profit, margin, sell-through, first/last sold, time-of-day histogram), per payment
method, per event, event vs event comparison. Local rule-based summary text for free;
AI summary for Pro.

## 7. Connectors

### Device (Dart)
```dart
abstract class Connector<TRaw, TModel> {
  String get id;
  Future<List<TRaw>> fetch(SyncCursor since);
  TModel normalize(TRaw raw);
  Future<IngestResult> ingest(); // fetch -> normalize -> dedupe on (source, externalId) -> upsert
}
```
Implementations: `SquareConnector` (payments -> sales), `CsvImportConnector` (products, sales),
`AnimeConsFeed` (events from our public feed), `IcsConnector` (events). Base for payment
providers: `PaymentProvider extends Connector<ExternalPayment, Sale>` adds `connect()`,
`disconnect()`, `isConnected`.

### Server (TypeScript, Edge Functions): trend signals
```ts
abstract class SignalConnector {
  abstract id: string;
  abstract fetch(window: TimeWindow): Promise<RawSignal[]>;
  normalize(raw: RawSignal): Signal; // keyword cleanup, synonym map, niche tags
}
class Aggregator { register(c); run(): Promise<TrendSnapshot> }
```
Each connector runs as its own scheduled invocation (isolated failures) writing to
`signals_raw`; `build-trends` scores velocity (this week vs 4-week baseline), merges across
sources, keeps provenance, has Claude write card copy ("why it fits", item idea; no emojis),
and writes `trends` (public read).

Sources: AniList GraphQL (trending/airing anime), Pinterest API v5 Trends (approval needed),
Reddit API (niche subreddit keyword frequency), Etsy Open API v3 (new-listing growth),
Google Trends API (alpha; apply), curated list (day one), opt-in anonymized user sales
(k-threshold before publishing). Hashtags are labelled "suggested", never "trending on
Instagram" (no API supports that claim).

## 8. Square

- OAuth code flow; `square-token` Edge Function holds the client secret and does exchange and
  refresh. Tokens are returned to the device and kept in secure storage, never stored server-side.
- Import by polling Payments/Orders since the last cursor on app start and every few minutes
  while an event is live. Dedupe on payment id.
- One-time mapping Square catalog item -> product; unmatched lines go to a "match these" list.
- Square sellers must be 18+; under-18 vendors use manual entry.
- v2: Square Mobile Payments SDK (platform channel) to take card payments in-app.

## 9. Events

- `fetch-cons` Edge Function queries AnimeCons daily and caches to public table `cons`.
  Confirm their API/terms (email them) and credit them in the UI. No scraping.
- App downloads the full list and filters by distance **on device**; location never leaves the
  phone.
- ICS import (file/URL) and export (per event or all) via share sheet.

## 10. Posts and flyers

`PostTemplate` (abstract) lays out named slots (image, title, price, cta, brand frame) for any
`PostFormat`. One shared brand frame (shop name, handle, colors, booth label) on every template.

| Format | Size (px) |
|---|---|
| Instagram feed portrait | 1080x1350 |
| Instagram / Facebook square | 1080x1080 |
| Story / Reels cover | 1080x1920 |
| Facebook link | 1200x630 |
| LinkedIn | 1200x627 |
| Shopify / Etsy listing | 2048x2048 |
| Printable flyer (letter, 300 dpi) | 2550x3300 |

Rendered with `RepaintBoundary.toImage`, exported PNG, shared via share sheet.

## 11. Exports (all on device)

```dart
abstract class Exporter {
  ExportFormat get format; // csv, xlsx, pdf, png
  Future<File> export(ExportRequest req); // what: report|sales|inventory|products|chart; range
}
```
CSV (`csv`), XLSX (`excel`: sheets Sales, Per product, Inventory, Summary), PDF (`pdf` +
`printing`: branded post-event report with charts), PNG (widget capture of any chart/stat card).
CSV re-imports through `CsvImportConnector`.

## 12. UI system

Design (source of truth for look and behavior): the artboards in
[docs/design/](design/), one `.dc.html` file per screen (HTML + inline styles + a small
logic class; read the markup for layout and colors, the script for behavior). `Main.dc.html`
is the token sheet. Live canvas for humans: https://claude.ai/artifact/YYJdMPdVQHFCAeMmgM9vRF
(private). If this section and an artboard disagree, the artboard wins for visuals and
this spec wins for behavior.

- **Look:** black ground (#0B0B0F) with a very dim light grid and a faint
  iridescent shimmer that drifts along the grid lines. Every box is opaque
  (#15151B / #1C1C24 / #24242E) so the grid never shows behind content.
  Pastel violet #B9A6FF (primary buttons), teal #7FE7D9 (toggles on, profit up),
  pink #FF9AD5 (Sell badge, low stock, down), lilac #D9CCFF (badges, PUP);
  pastel fills always carry #0B0B0F text. Fonts: Ronzino (display, numbers),
  BDO Grotesk (body, labels). Respect reduced motion everywhere.
- **Bottom navigation, five tabs:** Home, Shop, Sell (raised center badge), Create,
  Insights. PUP sits bottom-right on every tab for FAQs.
- **`PPScaffold` base template on every screen:** grid background, event bar
  (mini lanyard pass: event, Live / Day N, booth, today's net with sign,
  Offline / Synced), title with at most one primary action, a slim rounded
  search field directly under the title, then shared components only.
- **Startup:** lanyard loader (PUP's pass swinging) while bootstrap runs; on first
  launch PUP pops up with a greeting and FAQs, then lives in the corner.
- **Home:** built around the landing page: greeting, filled stat tiles (value plus
  small unit so nothing overflows), "almost gone" alert with "!", fan favorites,
  swipe deck of trend ideas, and at the very bottom the ASCII "YOUR POCKET PUP"
  banner with a wagging pup and a walking pup.
- **Shop:** add/edit/delete items; segmented filter All / "!" Low stock /
  "+" Best margin; rows show stock and margin as pills.
- **Sell:** one large card per item, swipe left/right between items; only -1 and
  +1 sold (-1 takes back the latest sale of that item from this session);
  pinch out or tap the grid button for a Photos-style 3-column grid with
  stock, price and sold count; tap a tile or pinch in to return. Payment method
  chips above the card. Search filters the cards.
- **Create:** pick item, pick shape (Post / Story / Wide), edit caption, then one
  "Share or save" bar at the bottom. It opens: Save as PNG (to Photos), Instagram,
  Facebook, LinkedIn, More apps. Each destination exports at its exact pixel size
  for the chosen shape (see section 10). Direct Instagram/Facebook intents need a
  Meta app id; until then social targets open the system share sheet with the
  right-size PNG and caption.
- **Search:** field under every title. Shop, Sell and Create filter in place;
  elsewhere submit opens app-wide results (items jump to the Sell card, events
  open the Events sheet). Local only, works offline.
- Touch targets 56px minimum on Sell, 48px elsewhere. Text contrast 4.5:1 minimum.
- Haptics (`HapticsService`, user toggle + intensity in Settings):

| Event | Pattern |
|---|---|
| +1 sold | medium impact |
| -1 sold (undo) | light impact |
| Low stock | warning |
| Sold out | heavy x2 |
| Swipe card, toggle, page change | selection tick |
| Error / blocked | error |
| Saved / synced | success |

iOS: UIFeedbackGenerator. Android: HapticFeedbackConstants (CONFIRM/REJECT on API 30+, fallback
vibration).

## 13. Backend security (RLS)

- RLS enabled **and forced** on every table. `anon` has no grants except `select` on `cons`
  and `trends`.
- User tables: `user_id uuid not null default auth.uid()` referencing `auth.users` on delete
  cascade; separate select/insert/update/delete policies `to authenticated` using
  `user_id = (select auth.uid())`, `with check` on insert/update.
- Sync writes additionally require `public.is_pro((select auth.uid()))`. Lapsed Pro: read and
  export only.
- `profiles.is_pro`, `pro_expires_at`: no client update grant; written only by the
  service-role webhook, which verifies RevenueCat's Authorization header.
- Storage: private `photos` bucket, policy `(storage.foldername(name))[1] = auth.uid()::text`;
  signed URLs only.
- No SECURITY DEFINER without `set search_path = ''`. Views use `security_invoker = true`.
- Edge Functions verify the JWT; service key only in function secrets; Square tokens never stored.
- Tests: pgTAP in `supabase/tests/` prove user A cannot read/insert/update/delete user B's rows,
  `anon` cannot reach user tables, non-Pro cannot write sync tables, clients cannot set
  `is_pro`. Run Supabase database linter (security advisors) in CI.

## 14. Privacy

Free mode: data stays on the phone, nothing sent to us. Pro: cloud backup in the user's own
RLS-isolated rows; sales data is never sold or shared. Location never leaves the device.
Opt-in aggregate trend contribution only above a k-anonymity threshold.

## 15. Current state and build order

Done (branch `app-skeleton`): design, this spec, Flutter skeleton, Supabase schema + RLS +
pgTAP tests, Edge Functions. **None of it has been compiled or run yet** (no Flutter or
Supabase CLI on the authoring machine). Expect analyzer errors, wrong package versions and
API drift; fixing those is step 1.

1. Make it build: `flutter create` platform folders, `pub get`, upgrade pins, Drift codegen,
   `flutter analyze` clean, `flutter test` green.
2. Make every screen match its artboard in `docs/design/`, running fully on fakes.
3. Supabase: `supabase start`, migrations apply, `supabase test db` green, Edge Functions
   type-check and have unit tests with mocked HTTP.
4. Real connectors behind config, in order: ICS -> AnimeCons feed -> exports -> RevenueCat +
   auth -> sync -> AI proxy -> Square -> trend sources.
5. Recommendation schedule and notifications (section 16).
6. CI (section 18).

## 16. Recommendation schedule

The vendor chooses how often they get fresh post and restock ideas: **off, daily, weekly
(default), every two weeks**, plus a time of day. Setting lives in Settings and on Home's
"Room to experiment" header.

- On schedule, the app builds a small batch on device: top trend cards from the cached feed
  ranked for this shop, plus one "post your best seller" suggestion with a pre-filled Create
  draft (item + shape + template caption). Pro adds the AI caption and restock ideas through
  the job queue.
- Delivered as a local notification (`flutter_local_notifications`); tapping opens Home with
  the new cards on top. No server push needed; works offline from the cached feed.
- The inspiration board is the swipe deck plus a "Saved ideas" list of right-swiped cards,
  each showing its sources.

## 17. Decisions and out of scope

- Language: English only for v1, but all user-facing strings go through Flutter `intl`
  ARB files so Japanese (already on the landing page) can be added without code changes.
- "Embed" post format: out of scope for v1.
- Collective / shared stock: dropped. Landing page (`codespace/`) still mentions it; do not
  edit `codespace/` from this project.
- Windows, Flutter web, social feed, multi-user booths: out of scope.
- No emojis anywhere, including test fixtures, sample data and AI prompts.

## 18. Definition of done (for an automated run)

- `flutter analyze` with zero errors and zero warnings; `dart format` clean.
- `flutter test` green, covering: pricing and break-even, analytics totals and per-product
  rows, sale + undo (-1) keeps stock correct, CSV round trip, ICS round trip, each exporter
  produces a non-empty file, post capture produces exactly the format's pixel width, sync
  value mapping, connector dedupe on `(source, externalId)`, and a widget test per tab that
  pumps on fakes without overflow at 390x844.
- `supabase db reset` applies cleanly; `supabase test db` green; `deno check` and
  `deno test` green for every function.
- GitHub Actions workflow running all of the above on pull requests.
- App runs with `USE_FAKES=true` and no keys; every screen matches its artboard.
