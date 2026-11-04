import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";
import type { WatchItem } from "./watchlist.ts";

/**
 * Active Etsy listing count per keyword (Open API v3). The Aggregator turns the
 * daily counts into growth. Needs an approved API key (ETSY_API_KEY); see registry.ts.
 */
export class EtsyListingsConnector extends SignalConnector {
  readonly id = "etsy";

  constructor(
    private apiKey: string,
    private watch: WatchItem[],
    private fetchFn: typeof fetch = fetch,
    private now: () => Date = () => new Date(),
  ) {
    super();
  }

  async fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const observedAt = this.now();
    const out: RawSignal[] = [];
    for (const w of this.watch) {
      const url = new URL("https://openapi.etsy.com/v3/application/listings/active");
      url.searchParams.set("keywords", w.keyword);
      url.searchParams.set("limit", "1");
      const res = await this.fetchFn(url, { headers: { "x-api-key": this.apiKey } });
      if (!res.ok) throw new Error(`etsy ${res.status}`);
      const count = (await res.json()).count as number;
      out.push({ keyword: w.keyword, niche: w.niche, value: count, observedAt });
    }
    return out;
  }
}
