# Overnight build prompt

Paste everything below the line into Kiro.

---

You are building Pop-Up Pass, a phone-first toolkit for convention artists and pop-up
vendors. You will work unattended overnight. No one will answer questions, so make
reasonable decisions, write them down, and keep going.

## Read first, in this order

1. `docs/SPEC.md`: the full spec. Sections 15 to 18 define the order of work and what
   "done" means.
2. `docs/design/*.dc.html`: one artboard per screen. Visual source of truth. `Main.dc.html`
   is the token sheet. Match these screens.
3. `app/README.md`, then the code in `app/` and `supabase/`.

## Where to work

- Start from the `app-skeleton` branch of the upstream repo `lilly2sick/popuppass`. If this
  fork does not have that branch, fetch it from upstream first. Do not start from `main`.
- Create a working branch from it, for example `kiro/overnight-build`.
- Commit in small, logical steps with clear messages. Push often so progress is never lost.
- When finished (or when you run out of time), open one pull request to
  `lilly2sick/popuppass` with base `app-skeleton`.

## Important context

- The existing code has **never been compiled or run**. Expect analyzer errors, stale
  package versions and API drift. Getting it building and tested is the first job, before
  adding anything.
- The app is offline-first. The on-device SQLite database is the source of truth; the
  backend is optional. `USE_FAKES=true` (the default) must always run with no keys.
- Free users never send data to our backend. AI is Pro-only and must never block the UI.
- Supabase row level security is a hard requirement. Never weaken a policy to make a test
  pass. If a test is wrong, fix the test and explain why in the PR.

## Rules

- Follow the spec's build order (section 15). Do not skip ahead while the build is red.
- Do not invent product features. If something is ambiguous, pick the simplest option
  consistent with the spec and record it under "Decisions" in the PR description.
- No emojis anywhere: UI copy, code comments, sample data, tests, AI prompts.
- Never commit secrets or real keys. Use `--dart-define` and function env vars only.
- Do not modify `codespace/` (the marketing site) or `docs/design/`.
- Do not scrape any website. AnimeCons stays a stub until they provide a feed.
- You cannot create Apple, Google, RevenueCat, Square, Meta or Supabase cloud accounts.
  Write the integration code behind config, test it with fakes or mocked HTTP, and list
  what a human must set up in the PR.
- Keep the existing architecture: `Connector` base class for every data source,
  repositories over Drift, Riverpod providers, `PPScaffold` on every tab, shared
  components from `app/lib/design/`. Extend these; do not replace them.
- Prefer deleting dead code over leaving it commented out.

## Definition of done

Spec section 18. In short: `flutter analyze` clean, `flutter test` green with the listed
coverage, `supabase test db` green, `deno check` and `deno test` green, a GitHub Actions
workflow running all of it, and every screen matching its artboard on fakes.

If you cannot reach all of it, stop at a green build. Never leave the branch red.

## Pull request description

Include:

1. What was done, by spec section.
2. Test results (paste the summary lines).
3. Decisions you made where the spec was unclear.
4. What is stubbed and why.
5. A checklist of human setup still needed: accounts, keys, store configuration, Meta app
   id for direct Instagram/Facebook sharing, AnimeCons feed.
6. Screenshots of each tab running on fakes, if your environment can produce them.
