# Running the database tests locally without docker

CI runs the real thing: `supabase db reset` then `supabase test db` (docker on the runner).
On a machine without docker, `scripts/pgtap-local.sh` gives the same pgTAP proofs against a
throwaway Postgres.

```sh
scripts/pgtap-local.sh
```

What it does, in order:

1. Installs `@embedded-postgres/linux-x64` and `pg` from npm into `.pgtap-local/` (gitignored).
2. Clones pgTAP (`PGTAP_REF`, default `v1.3.3`) and generates its plain-SQL install file.
3. Starts a scratch Postgres on port 54329 (`PGPORT` to change).
4. Applies `scripts/pgtap-local/stub.sql` (roles `anon`, `authenticated`, `service_role`,
   minimal `auth.users`, `auth.uid()`, `storage.buckets`, `storage.objects`), then every file in
   `supabase/migrations/` in order.
5. Runs `supabase/tests/*_test.sql` and prints TAP. Exit code is non-zero on any `not ok`.

Limits: the auth and storage schemas are stubs, so a migration that depends on other Supabase
internals (vault, pg_cron, real storage triggers) needs stub additions. The Supabase CLI run in
CI remains the source of truth. The runner is Linux x64 only and refuses to run as root, so it
re-runs itself as `PGTAP_USER` (default `ecs-user`) when started as root.
