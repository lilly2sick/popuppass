// Daily (cron): refresh the public `cons` table from the AnimeCons feed.
// STUB until AnimeCons provides a documented feed. Never scrapes: with no
// ANIMECONS_FEED_URL it makes no request at all, and with one it makes exactly
// one GET and accepts only a JSON array of well-formed records.
// Credit "animecons.com" wherever this data is shown.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { hasBearerSecret, json } from "../_shared/auth.ts";

export type Con = {
  external_id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  venue?: string;
  city?: string;
  region?: string;
  country?: string;
  lat?: number;
  lng?: number;
  url?: string;
};

const OPTIONAL_TEXT = ["venue", "city", "region", "country", "url"] as const;
const isText = (v: unknown): v is string => typeof v === "string" && v.length > 0;
const isDate = (v: unknown): v is string => isText(v) && !Number.isNaN(Date.parse(v));

/** Returns a clean Con or null. Unknown fields are dropped, never stored. */
export function parseCon(x: unknown): Con | null {
  if (typeof x !== "object" || x === null) return null;
  const r = x as Record<string, unknown>;
  if (!isText(r.external_id) || !isText(r.name) || !isDate(r.starts_at) || !isDate(r.ends_at)) {
    return null;
  }
  const con: Con = {
    external_id: r.external_id,
    name: r.name,
    starts_at: r.starts_at,
    ends_at: r.ends_at,
  };
  for (const k of OPTIONAL_TEXT) if (isText(r[k])) con[k] = r[k];
  if (typeof r.lat === "number") con.lat = r.lat;
  if (typeof r.lng === "number") con.lng = r.lng;
  return con;
}

export async function fetchFromFeed(
  feedUrl: string | undefined,
  fetchFn: typeof fetch,
): Promise<Con[]> {
  if (!feedUrl) return [];
  const res = await fetchFn(feedUrl, {
    headers: { accept: "application/json", "user-agent": "PopUpPass/0.1 (contact: team)" },
  });
  if (!res.ok) throw new Error(`animecons ${res.status}`);
  const body = await res.json();
  if (!Array.isArray(body)) throw new Error("animecons feed is not a JSON array");
  return body.flatMap((x) => {
    const con = parseCon(x);
    return con ? [con] : [];
  });
}

export function createHandler(
  deps: {
    db: SupabaseClient;
    fetchFn: typeof fetch;
    feedUrl: string | undefined;
    cronSecret: string | undefined;
    now?: () => Date;
  },
) {
  return async (req: Request): Promise<Response> => {
    if (!hasBearerSecret(req, deps.cronSecret)) return json({ error: "unauthorized" }, 401);
    let cons: Con[];
    try {
      cons = await fetchFromFeed(deps.feedUrl, deps.fetchFn);
    } catch (e) {
      return json({ ok: false, error: e instanceof Error ? e.message : "feed" }, 502);
    }
    if (cons.length) {
      const fetchedAt = (deps.now ?? (() => new Date()))().toISOString();
      const { error } = await deps.db.from("cons").upsert(
        cons.map((c) => ({ ...c, fetched_at: fetchedAt })),
      );
      if (error) return json({ ok: false, error: "store_failed" }, 500);
    }
    return json({ ok: true, count: cons.length });
  };
}
