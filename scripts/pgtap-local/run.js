// Applies stub.sql, every migration, pgTAP and supabase/tests/*_test.sql to a
// scratch database and prints TAP. Invoked by scripts/pgtap-local.sh.
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const port = Number(process.env.PGPORT || 54329);
const host = process.env.PGHOST || '127.0.0.1';
const repo = path.resolve(__dirname, '..', '..');
const pgtapSql = process.env.PGTAP_SQL;
const migrations = path.join(repo, 'supabase', 'migrations');
const tests = path.join(repo, 'supabase', 'tests');

const connect = async (database) => {
  const c = new Client({ host, port, user: 'postgres', database });
  await c.connect();
  return c;
};

(async () => {
  const admin = await connect('postgres');
  await admin.query('drop database if exists pp_test with (force)');
  await admin.query('create database pp_test');
  await admin.end();

  const c = await connect('pp_test');
  // Roles are cluster wide: drop and recreate so reruns are clean.
  for (const r of ['anon', 'authenticated', 'service_role']) {
    await c.query(
      `do $$ begin if exists (select 1 from pg_roles where rolname = '${r}') then
         execute 'drop owned by ${r}'; execute 'drop role ${r}'; end if; end $$`,
    );
  }
  await c.query(fs.readFileSync(path.join(__dirname, 'stub.sql'), 'utf8'));
  for (const f of fs.readdirSync(migrations).filter((n) => n.endsWith('.sql')).sort()) {
    await c.query(fs.readFileSync(path.join(migrations, f), 'utf8'));
    console.log(`# applied ${f}`);
  }
  await c.query('set search_path = extensions, public');
  await c.query(fs.readFileSync(pgtapSql, 'utf8'));
  await c.query("set search_path = public, extensions");

  let failed = false;
  for (const f of fs.readdirSync(tests).filter((n) => n.endsWith('_test.sql')).sort()) {
    console.log(`# ${f}`);
    // pgTAP is preloaded above, so drop the create extension line the CLI needs.
    const sql = fs.readFileSync(path.join(tests, f), 'utf8')
      .replace(/create extension if not exists pgtap with schema extensions;/, '');
    const res = await c.query({ text: sql, rowMode: 'array' });
    for (const r of Array.isArray(res) ? res : [res]) {
      for (const row of r.rows || []) {
        const line = row[0];
        if (typeof line === 'string' && /^(ok|not ok|1\.\.|#)/.test(line)) {
          console.log(line);
          if (line.startsWith('not ok')) failed = true;
        }
      }
    }
  }
  await c.end();
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error('ERROR', e.message, e.position || '');
  process.exit(1);
});
