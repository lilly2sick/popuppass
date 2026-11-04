// Pure velocity scoring. No I/O so it is trivially testable.

export type SignalRow = {
  source: string;
  keyword: string;
  niche: string;
  value: number;
  observed_at: string;
};

export type ScoredTrend = {
  keyword: string;
  niche: string;
  score: number;
  velocity: number;
  sources: string[];
};

export const DAY_MS = 864e5;
export const RECENT_DAYS = 7;
export const BASELINE_DAYS = 35;
export const MAX_TRENDS = 60;

const mean = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);

/**
 * velocity = this week's mean / prior 4-week mean.
 * score = 0.7 * tanh(velocity - 1) + 0.3 * source agreement (3 sources = full).
 * Keywords that are not accelerating (score <= 0) are dropped.
 */
export function scoreSignals(rows: SignalRow[], now = new Date()): ScoredTrend[] {
  const weekAgo = now.getTime() - RECENT_DAYS * DAY_MS;
  const byKey = new Map<
    string,
    { niche: string; recent: number[]; base: number[]; sources: Set<string> }
  >();
  for (const r of rows) {
    const e = byKey.get(r.keyword) ??
      { niche: r.niche, recent: [], base: [], sources: new Set<string>() };
    (new Date(r.observed_at).getTime() >= weekAgo ? e.recent : e.base).push(r.value);
    e.sources.add(r.source);
    byKey.set(r.keyword, e);
  }
  return [...byKey.entries()]
    .map(([keyword, e]) => {
      const velocity = mean(e.recent) / Math.max(mean(e.base), 1e-6);
      const agreement = Math.min(e.sources.size / 3, 1);
      return {
        keyword,
        niche: e.niche,
        velocity,
        score: Math.tanh(velocity - 1) * 0.7 + agreement * 0.3,
        sources: [...e.sources].sort(),
      };
    })
    .filter((t) => t.score > 0)
    .sort((a, b) => b.score - a.score || a.keyword.localeCompare(b.keyword))
    .slice(0, MAX_TRENDS);
}
