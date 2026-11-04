// Which sources run. Sources that need an approved account stay off until their
// credentials are present in the function environment.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { SignalConnector } from "../signals.ts";
import { AniListConnector } from "./anilist.ts";
import { CuratedConnector } from "./curated.ts";
import { EtsyListingsConnector } from "./etsy.ts";
import { GoogleTrendsConnector } from "./google_trends.ts";
import { type Contribution, MIN_K, OptInSalesConnector } from "./opt_in_sales.ts";
import { PinterestTrendsConnector } from "./pinterest.ts";
import { RedditConnector } from "./reddit.ts";
import { CURATED_ITEMS } from "./watchlist.ts";

export type Env = (key: string) => string | undefined;

export function buildConnectors(
  env: Env,
  db: SupabaseClient,
  fetchFn: typeof fetch = fetch,
): SignalConnector[] {
  const list: SignalConnector[] = [
    new CuratedConnector(CURATED_ITEMS),
    new AniListConnector(fetchFn),
  ];

  const redditId = env("REDDIT_CLIENT_ID");
  const redditSecret = env("REDDIT_CLIENT_SECRET");
  if (redditId && redditSecret) {
    list.push(
      new RedditConnector(
        { clientId: redditId, clientSecret: redditSecret },
        CURATED_ITEMS,
        undefined,
        fetchFn,
      ),
    );
  }

  const etsyKey = env("ETSY_API_KEY");
  if (etsyKey) list.push(new EtsyListingsConnector(etsyKey, CURATED_ITEMS, fetchFn));

  const pinterestToken = env("PINTEREST_ACCESS_TOKEN");
  if (pinterestToken) {
    list.push(
      new PinterestTrendsConnector(pinterestToken, env("PINTEREST_REGION") ?? "US", fetchFn),
    );
  }

  const googleKey = env("GOOGLE_TRENDS_API_KEY");
  if (googleKey) list.push(new GoogleTrendsConnector(googleKey));

  if (env("OPT_IN_SALES") === "true") {
    list.push(
      new OptInSalesConnector(
        (w) => loadContributions(db, w),
        Number(env("OPT_IN_MIN_K") ?? MIN_K),
      ),
    );
  }
  return list;
}

async function loadContributions(
  db: SupabaseClient,
  w: { from: Date; to: Date },
): Promise<Contribution[]> {
  const { data, error } = await db.from("trend_contributions")
    .select("user_id, keyword, niche, units")
    .gte("contributed", w.from.toISOString().slice(0, 10));
  if (error) throw new Error(`trend_contributions select: ${error.message}`);
  return (data ?? []).map((r) => ({
    userId: r.user_id,
    keyword: r.keyword,
    niche: r.niche ?? undefined,
    units: r.units,
  }));
}
