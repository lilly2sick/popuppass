import { type RawSignal, SignalConnector, type TimeWindow } from "./signals.ts";

/** Trending anime this season. Fan-art demand follows airing shows. Free, public. */
export class AniListConnector extends SignalConnector {
  readonly id = "anilist";

  async fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const query = `query { Page(perPage: 30) { media(type: ANIME, sort: TRENDING_DESC) { title { english romaji } trending } } }`;
    const res = await fetch("https://graphql.anilist.co", {
      method: "POST",
      headers: { "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({ query }),
    });
    if (!res.ok) throw new Error(`anilist ${res.status}`);
    const media = (await res.json()).data.Page.media as { title: { english?: string; romaji: string }; trending: number }[];
    const now = new Date();
    return media.map((m) => ({ keyword: m.title.english ?? m.title.romaji, value: m.trending, observedAt: now, niche: "anime" }));
  }
}

/** Hand-picked list maintained by the team. Day-one source. */
export class CuratedConnector extends SignalConnector {
  readonly id = "curated";
  constructor(private items: { keyword: string; niche: string; weight: number }[]) {
    super();
  }
  fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const now = new Date();
    return Promise.resolve(this.items.map((i) => ({ keyword: i.keyword, niche: i.niche, value: i.weight, observedAt: now })));
  }
}

// TODO: PinterestTrendsConnector (API v5 trends, needs app approval)
// TODO: RedditConnector (keyword frequency in niche subreddits, OAuth app)
// TODO: EtsyListingsConnector (Open API v3, new-listing growth per keyword)
// TODO: GoogleTrendsConnector (official API alpha; apply)
