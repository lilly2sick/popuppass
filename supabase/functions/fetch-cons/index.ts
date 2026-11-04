// Daily (pg_cron): refresh the public `cons` table from AnimeCons.
// BLOCKED on AnimeCons: confirm their API/feed and terms before enabling.
// No scraping. Credit "animecons.com" wherever this data is shown.
import { admin, json } from "../_shared/auth.ts";

type Con = {
  external_id: string; name: string; starts_at: string; ends_at: string;
  venue?: string; city?: string; region?: string; country?: string;
  lat?: number; lng?: number; url?: string;
};

async function fetchFromAnimeCons(): Promise<Con[]> {
  const feed = Deno.env.get("ANIMECONS_FEED_URL");
  if (!feed) return [];
  const res = await fetch(feed, { headers: { "user-agent": "PopUpPass/0.1 (contact: team)" } });
  if (!res.ok) throw new Error(`animecons ${res.status}`);
  // TODO(animecons): map their documented response shape to Con.
  return (await res.json()) as Con[];
}

Deno.serve(async (req) => {
  if (req.headers.get("authorization") !== `Bearer ${Deno.env.get("CRON_SECRET")}`) return json({ error: "unauthorized" }, 401);
  const cons = await fetchFromAnimeCons();
  if (cons.length) await admin().from("cons").upsert(cons.map((c) => ({ ...c, fetched_at: new Date().toISOString() })));
  return json({ ok: true, count: cons.length });
});
