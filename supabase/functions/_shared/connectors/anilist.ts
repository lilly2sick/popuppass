import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";

const ENDPOINT = "https://graphql.anilist.co";
const QUERY =
  `query { Page(perPage: 30) { media(type: ANIME, sort: TRENDING_DESC) { title { english romaji } trending } } }`;

type Media = { title: { english?: string | null; romaji: string }; trending: number };

/** Trending anime this season. Fan-art demand follows airing shows. Free, public API. */
export class AniListConnector extends SignalConnector {
  readonly id = "anilist";

  constructor(private fetchFn: typeof fetch = fetch, private now: () => Date = () => new Date()) {
    super();
  }

  async fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const res = await this.fetchFn(ENDPOINT, {
      method: "POST",
      headers: { "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({ query: QUERY }),
    });
    if (!res.ok) throw new Error(`anilist ${res.status}`);
    const media = (await res.json()).data.Page.media as Media[];
    const observedAt = this.now();
    return media.map((m) => ({
      keyword: m.title.english ?? m.title.romaji,
      value: m.trending,
      observedAt,
      niche: "anime",
    }));
  }
}
