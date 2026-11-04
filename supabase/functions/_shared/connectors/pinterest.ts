import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";

type PinterestTrend = { keyword: string; pct_growth_wow?: number };

/**
 * Pinterest Trends (API v5), growing keywords. Needs an approved app and access
 * token (PINTEREST_ACCESS_TOKEN); see registry.ts. Value is week over week growth in percent.
 */
export class PinterestTrendsConnector extends SignalConnector {
  readonly id = "pinterest";

  constructor(
    private accessToken: string,
    private region = "US",
    private fetchFn: typeof fetch = fetch,
    private now: () => Date = () => new Date(),
  ) {
    super();
  }

  async fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const res = await this.fetchFn(
      `https://api.pinterest.com/v5/trends/keywords/${this.region}/top/growing?limit=50`,
      { headers: { authorization: `Bearer ${this.accessToken}` } },
    );
    if (!res.ok) throw new Error(`pinterest ${res.status}`);
    const trends = (await res.json()).trends as PinterestTrend[];
    const observedAt = this.now();
    return trends
      .filter((t) => (t.pct_growth_wow ?? 0) > 0)
      .map((t) => ({ keyword: t.keyword, value: t.pct_growth_wow!, observedAt }));
  }
}
