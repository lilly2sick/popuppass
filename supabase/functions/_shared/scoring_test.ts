import { assert, assertEquals } from "jsr:@std/assert@1";
import { scoreSignals } from "./scoring.ts";

const DAY = 864e5;
const iso = (now: Date, daysAgo: number) => new Date(now.getTime() - daysAgo * DAY).toISOString();

Deno.test("scoreSignals ranks an accelerating keyword first and drops falling ones", () => {
  const now = new Date("2026-02-01T00:00:00Z");
  const row = (keyword: string, value: number, daysAgo: number) => ({
    source: "a",
    keyword,
    niche: "general",
    value,
    observed_at: iso(now, daysAgo),
  });
  const scored = scoreSignals(
    [
      row("frog", 10, 1),
      row("frog", 1, 20),
      row("flat", 5, 1),
      row("flat", 5, 20),
      row("falling", 1, 1),
      row("falling", 9, 20),
    ],
    now,
  );
  assertEquals(scored[0].keyword, "frog");
  assertEquals(scored.find((s) => s.keyword === "falling"), undefined);
  const flat = scored.find((s) => s.keyword === "flat");
  assertEquals(flat?.velocity, 1);
  assert(flat!.score < scored[0].score, "a flat keyword only earns agreement points");
});

Deno.test("scoreSignals rewards agreement across sources", () => {
  const now = new Date("2026-02-01T00:00:00Z");
  const rowsFor = (sources: string[]) =>
    sources.map((s) => ({
      source: s,
      keyword: "k",
      niche: "general",
      value: 10,
      observed_at: iso(now, 1),
    }))
      .concat(
        sources.map((s) => ({
          source: s,
          keyword: "k",
          niche: "general",
          value: 5,
          observed_at: iso(now, 20),
        })),
      );

  const one = scoreSignals(rowsFor(["a"]), now)[0];
  const three = scoreSignals(rowsFor(["a", "b", "c"]), now)[0];
  assert(three.score > one.score, "more agreeing sources scores higher at equal velocity");
});

Deno.test("scoreSignals ignores signals older than the baseline window", () => {
  const now = new Date("2026-02-01T00:00:00Z");
  const rows = [
    { source: "a", keyword: "ancient", niche: "general", value: 1000, observed_at: iso(now, 400) },
  ];
  assertEquals(scoreSignals(rows, now), []);
});

Deno.test("scoreSignals caps output at 60 and sorts by score descending", () => {
  const now = new Date("2026-02-01T00:00:00Z");
  const rows = Array.from({ length: 80 }, (_, i) => [
    { source: "a", keyword: `k${i}`, niche: "general", value: 10 + i, observed_at: iso(now, 1) },
    { source: "a", keyword: `k${i}`, niche: "general", value: 1, observed_at: iso(now, 20) },
  ]).flat();
  const scored = scoreSignals(rows, now);
  assertEquals(scored.length, 60);
  for (let i = 1; i < scored.length; i++) assert(scored[i - 1].score >= scored[i].score);
});
