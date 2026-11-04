import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";
import type { WatchItem } from "./watchlist.ts";

/** Hand-picked list maintained by the team. Day-one source, no network. */
export class CuratedConnector extends SignalConnector {
  readonly id = "curated";

  constructor(private items: WatchItem[], private now: () => Date = () => new Date()) {
    super();
  }

  fetch(_w: TimeWindow): Promise<RawSignal[]> {
    const observedAt = this.now();
    return Promise.resolve(
      this.items.map((i) => ({ keyword: i.keyword, niche: i.niche, value: i.weight, observedAt })),
    );
  }
}
