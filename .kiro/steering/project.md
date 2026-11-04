# Pop-Up Pass: always-on context

- Spec: `docs/SPEC.md` (sections 15 to 18 = order of work and definition of done).
- Design: `docs/design/*.dc.html`, one artboard per screen; `Main.dc.html` is the token sheet.
- Flutter app in `app/` (offline-first, Drift, Riverpod, go_router). Backend in `supabase/`.
- Run on fakes with no keys: `USE_FAKES=true` (default).
- Hard rules: RLS is never weakened; free users send nothing to the backend; AI never
  blocks the UI; no emojis anywhere; no secrets in code; never scrape; do not edit
  `codespace/` or `docs/design/`.
- Extend the existing patterns (`Connector`, repositories, `PPScaffold`, design components)
  rather than replacing them.
