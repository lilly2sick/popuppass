// A new trend source is one SignalConnector subclass. The Aggregator (aggregator.ts)
// runs them all; one failing source never stops the others.
import { nicheFor, normalizeKeyword } from "./normalize.ts";

export type TimeWindow = { from: Date; to: Date };
export type RawSignal = {
  keyword: string;
  value: number;
  observedAt: Date;
  niche?: string;
  meta?: Record<string, unknown>;
};
export type Signal = RawSignal & { source: string; niche: string };

export abstract class SignalConnector {
  abstract readonly id: string;
  abstract fetch(window: TimeWindow): Promise<RawSignal[]>;

  normalize(raw: RawSignal): Signal {
    const keyword = normalizeKeyword(raw.keyword);
    return { ...raw, keyword, source: this.id, niche: nicheFor(keyword, raw.niche) };
  }
}

export type CollectResult = { id: string; count: number; error?: string };
