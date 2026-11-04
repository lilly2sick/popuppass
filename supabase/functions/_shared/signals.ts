// Base aggregator for trend signals. A new source = one SignalConnector subclass.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

export type TimeWindow = { from: Date; to: Date };
export type RawSignal = { keyword: string; value: number; observedAt: Date; niche?: string; meta?: Record<string, unknown> };
export type Signal = RawSignal & { source: string; niche: string };

const SYNONYMS: Record<string, string> = { frogs: "frog", mushrooms: "mushroom", kitty: "cat", kitten: "cat" };
const NICHE_HINTS: Record<string, string> = {
  frog: "cottagecore", mushroom: "cottagecore", cat: "cute", strawberry: "cute", y2k: "y2k",
};

export abstract class SignalConnector {
  abstract readonly id: string;
  abstract fetch(window: TimeWindow): Promise<RawSignal[]>;

  normalize(raw: RawSignal): Signal {
    const k = raw.keyword.toLowerCase().trim().replace(/\s+/g, " ");
    const keyword = SYNONYMS[k] ?? k;
    return { ...raw, keyword, source: this.id, niche: raw.niche ?? NICHE_HINTS[keyword] ?? "general" };
  }

  /** Fetch, normalize, store. Failures stay inside this connector. */
  async collect(db: SupabaseClient, window: TimeWindow): Promise<{ id: string; count: number; error?: string }> {
    try {
      const signals = (await this.fetch(window)).map((r) => this.normalize(r));
      if (signals.length) {
        await db.from("signals_raw").insert(signals.map((s) => ({
          source: s.source, keyword: s.keyword, niche: s.niche, value: s.value,
          observed_at: s.observedAt.toISOString(), meta: s.meta ?? {},
        })));
      }
      return { id: this.id, count: signals.length };
    } catch (e) {
      return { id: this.id, count: 0, error: String(e) };
    }
  }
}

export type ScoredTrend = { keyword: string; niche: string; score: number; velocity: number; sources: string[] };

/** velocity = this week's mean / prior 4-week mean; score blends velocity and source agreement. */
export class Aggregator {
  constructor(private db: SupabaseClient) {}

  async score(now = new Date()): Promise<ScoredTrend[]> {
    const weekAgo = new Date(now.getTime() - 7 * 864e5);
    const fiveWeeksAgo = new Date(now.getTime() - 35 * 864e5);
    const { data } = await this.db.from("signals_raw").select("source, keyword, niche, value, observed_at")
      .gte("observed_at", fiveWeeksAgo.toISOString());

    const byKey = new Map<string, { niche: string; recent: number[]; base: number[]; sources: Set<string> }>();
    for (const r of data ?? []) {
      const e = byKey.get(r.keyword) ?? { niche: r.niche, recent: [], base: [], sources: new Set<string>() };
      (new Date(r.observed_at) >= weekAgo ? e.recent : e.base).push(r.value);
      e.sources.add(r.source);
      byKey.set(r.keyword, e);
    }
    const mean = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
    return [...byKey.entries()]
      .map(([keyword, e]) => {
        const velocity = mean(e.recent) / Math.max(mean(e.base), 1e-6);
        const agreement = Math.min(e.sources.size / 3, 1);
        return { keyword, niche: e.niche, velocity, score: Math.tanh(velocity - 1) * 0.7 + agreement * 0.3, sources: [...e.sources] };
      })
      .filter((t) => t.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 60);
  }
}
