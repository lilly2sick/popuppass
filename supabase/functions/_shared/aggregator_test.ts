import { assertEquals } from "jsr:@std/assert@1";
import { Aggregator, type SignalStore } from "./aggregator.ts";
import { type RawSignal, type Signal, SignalConnector, type TimeWindow } from "./signals.ts";

class FakeConnector extends SignalConnector {
  constructor(readonly id: string, private signals: RawSignal[] | (() => Promise<RawSignal[]>)) {
    super();
  }
  fetch(_w: TimeWindow): Promise<RawSignal[]> {
    return typeof this.signals === "function" ? this.signals() : Promise.resolve(this.signals);
  }
}

class MemoryStore implements SignalStore {
  saved: Signal[] = [];
  save(signals: Signal[]): Promise<void> {
    this.saved.push(...signals);
    return Promise.resolve();
  }
  since(
    _from: Date,
  ): Promise<
    { source: string; keyword: string; niche: string; value: number; observed_at: string }[]
  > {
    return Promise.resolve(
      this.saved.map((s) => ({
        source: s.source,
        keyword: s.keyword,
        niche: s.niche,
        value: s.value,
        observed_at: s.observedAt.toISOString(),
      })),
    );
  }
}

const window = { from: new Date("2026-01-01"), to: new Date("2026-01-02") };

Deno.test("collect normalizes and stores signals per connector", async () => {
  const store = new MemoryStore();
  const agg = new Aggregator(
    [new FakeConnector("a", [{ keyword: "  Frogs ", value: 1, observedAt: new Date() }])],
    store,
  );
  const results = await agg.collect(window);
  assertEquals(results, [{ id: "a", count: 1 }]);
  assertEquals(store.saved[0].keyword, "frog");
  assertEquals(store.saved[0].source, "a");
});

Deno.test("collect isolates a failing connector from the others", async () => {
  const store = new MemoryStore();
  const agg = new Aggregator(
    [
      new FakeConnector("broken", () => Promise.reject(new Error("boom"))),
      new FakeConnector("ok", [{ keyword: "cat", value: 2, observedAt: new Date() }]),
    ],
    store,
  );
  const results = await agg.collect(window);
  assertEquals(results[0], { id: "broken", count: 0, error: "boom" });
  assertEquals(results[1], { id: "ok", count: 1 });
  assertEquals(store.saved.length, 1);
});

Deno.test("score delegates to scoreSignals over the store's rows", async () => {
  const store = new MemoryStore();
  const now = new Date("2026-02-01T00:00:00Z");
  await store.save([
    {
      keyword: "frog",
      value: 10,
      observedAt: new Date(now.getTime() - 864e5),
      source: "a",
      niche: "cottagecore",
    },
    {
      keyword: "frog",
      value: 1,
      observedAt: new Date(now.getTime() - 20 * 864e5),
      source: "a",
      niche: "cottagecore",
    },
  ]);
  const agg = new Aggregator([], store);
  const scored = await agg.score(now);
  assertEquals(scored[0].keyword, "frog");
});
