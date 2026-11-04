// Which sources run. Sources that need an approved account stay off until their
// credentials are present in the function environment.
import type { SignalConnector } from "../signals.ts";
import { AniListConnector } from "./anilist.ts";
import { CuratedConnector } from "./curated.ts";
import { EtsyListingsConnector } from "./etsy.ts";
import { GoogleTrendsConnector } from "./google_trends.ts";
import { PinterestTrendsConnector } from "./pinterest.ts";
import { RedditConnector } from "./reddit.ts";
import { CURATED_ITEMS } from "./watchlist.ts";

export type Env = (key: string) => string | undefined;

export function buildConnectors(env: Env, fetchFn: typeof fetch = fetch): SignalConnector[] {
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

  return list;
}
