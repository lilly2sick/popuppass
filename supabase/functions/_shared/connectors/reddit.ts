import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";
import type { WatchItem } from "./watchlist.ts";

export type Subreddit = { name: string; niche: string };

export const DEFAULT_SUBREDDITS: Subreddit[] = [
  { name: "cottagecore", niche: "cottagecore" },
  { name: "kawaii", niche: "cute" },
  { name: "y2k", niche: "y2k" },
];

const USER_AGENT = "PopUpPass/0.1 (trend research)";

/**
 * Keyword frequency in recent post titles of niche subreddits. Needs an approved
 * Reddit OAuth app (REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET); see registry.ts.
 */
export class RedditConnector extends SignalConnector {
  readonly id = "reddit";

  constructor(
    private creds: { clientId: string; clientSecret: string },
    private watch: WatchItem[],
    private subreddits: Subreddit[] = DEFAULT_SUBREDDITS,
    private fetchFn: typeof fetch = fetch,
    private now: () => Date = () => new Date(),
  ) {
    super();
  }

  private async token(): Promise<string> {
    const basic = btoa(`${this.creds.clientId}:${this.creds.clientSecret}`);
    const res = await this.fetchFn("https://www.reddit.com/api/v1/access_token", {
      method: "POST",
      headers: {
        authorization: `Basic ${basic}`,
        "content-type": "application/x-www-form-urlencoded",
        "user-agent": USER_AGENT,
      },
      body: "grant_type=client_credentials",
    });
    if (!res.ok) throw new Error(`reddit auth ${res.status}`);
    return (await res.json()).access_token as string;
  }

  async fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const token = await this.token();
    const observedAt = this.now();
    const counts = new Map<string, number>();
    for (const sub of this.subreddits) {
      const res = await this.fetchFn(`https://oauth.reddit.com/r/${sub.name}/new?limit=100`, {
        headers: { authorization: `Bearer ${token}`, "user-agent": USER_AGENT },
      });
      if (!res.ok) throw new Error(`reddit r/${sub.name} ${res.status}`);
      const posts = (await res.json()).data.children as { data: { title: string } }[];
      const titles = posts.map((p) => p.data.title.toLowerCase());
      for (const w of this.watch) {
        const hits = titles.filter((t) => t.includes(w.keyword)).length;
        if (hits) counts.set(w.keyword, (counts.get(w.keyword) ?? 0) + hits);
      }
    }
    return this.watch.flatMap((w) => {
      const value = counts.get(w.keyword);
      return value ? [{ keyword: w.keyword, niche: w.niche, value, observedAt }] : [];
    });
  }
}
