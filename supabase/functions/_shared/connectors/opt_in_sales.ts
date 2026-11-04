import { normalizeKeyword } from "../normalize.ts";
import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";

export type Contribution = { userId: string; keyword: string; niche?: string; units: number };

/** Never report a keyword that fewer than this many distinct vendors contributed (SPEC 14). */
export const MIN_K = 5;

/**
 * Opt-in aggregate sales. Vendors who turned on contribution add (keyword, units);
 * a keyword is emitted only when at least k distinct vendors contributed it, and
 * only the total is kept. No user ids, amounts, events or places leave this class.
 */
export class OptInSalesConnector extends SignalConnector {
  readonly id = "opt_in_sales";
  readonly k: number;

  constructor(
    private load: (w: TimeWindow) => Promise<Contribution[]>,
    k = MIN_K,
    private now: () => Date = () => new Date(),
  ) {
    super();
    this.k = Math.max(k, MIN_K);
  }

  async fetch(w: TimeWindow): Promise<RawSignal[]> {
    const groups = new Map<string, { users: Set<string>; units: number; niche?: string }>();
    for (const c of await this.load(w)) {
      const keyword = normalizeKeyword(c.keyword);
      const g = groups.get(keyword) ?? { users: new Set<string>(), units: 0, niche: c.niche };
      g.users.add(c.userId);
      g.units += c.units;
      groups.set(keyword, g);
    }
    const observedAt = this.now();
    return [...groups.entries()]
      .filter(([, g]) => g.users.size >= this.k)
      .map(([keyword, g]) => ({
        keyword,
        niche: g.niche,
        value: g.units,
        observedAt,
        meta: { contributors: g.users.size },
      }));
  }
}
