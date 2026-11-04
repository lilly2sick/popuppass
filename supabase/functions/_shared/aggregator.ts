import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  BASELINE_DAYS,
  DAY_MS,
  type ScoredTrend,
  scoreSignals,
  type SignalRow,
} from "./scoring.ts";
import type { CollectResult, Signal, SignalConnector, TimeWindow } from "./signals.ts";

/** Storage seam so the Aggregator is testable without a database. */
export interface SignalStore {
  save(signals: Signal[]): Promise<void>;
  since(from: Date): Promise<SignalRow[]>;
}

export class SupabaseSignalStore implements SignalStore {
  constructor(private db: SupabaseClient) {}

  async save(signals: Signal[]): Promise<void> {
    const { error } = await this.db.from("signals_raw").insert(signals.map((s) => ({
      source: s.source,
      keyword: s.keyword,
      niche: s.niche,
      value: s.value,
      observed_at: s.observedAt.toISOString(),
      meta: s.meta ?? {},
    })));
    if (error) throw new Error(`signals_raw insert: ${error.message}`);
  }

  async since(from: Date): Promise<SignalRow[]> {
    const { data, error } = await this.db.from("signals_raw")
      .select("source, keyword, niche, value, observed_at")
      .gte("observed_at", from.toISOString());
    if (error) throw new Error(`signals_raw select: ${error.message}`);
    return (data ?? []) as SignalRow[];
  }
}

/** Runs every connector, stores what they return, and scores keywords by velocity. */
export class Aggregator {
  constructor(private connectors: SignalConnector[], private store: SignalStore) {}

  /** Fetch, normalize and store each source. A failing source reports an error and nothing else. */
  async collect(window: TimeWindow): Promise<CollectResult[]> {
    return await Promise.all(this.connectors.map(async (c): Promise<CollectResult> => {
      try {
        const signals = (await c.fetch(window)).map((r) => c.normalize(r));
        if (signals.length) await this.store.save(signals);
        return { id: c.id, count: signals.length };
      } catch (e) {
        return { id: c.id, count: 0, error: e instanceof Error ? e.message : String(e) };
      }
    }));
  }

  async score(now = new Date()): Promise<ScoredTrend[]> {
    const rows = await this.store.since(new Date(now.getTime() - BASELINE_DAYS * DAY_MS));
    return scoreSignals(rows, now);
  }
}
