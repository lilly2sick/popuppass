import { assert, assertEquals } from "jsr:@std/assert@1";
import { Aggregator, type SignalStore } from "../_shared/aggregator.ts";
import type { CompleteOptions, Completion, LlmClient } from "../_shared/llm.ts";
import type { SignalRow } from "../_shared/scoring.ts";
import { type Signal, SignalConnector, type TimeWindow } from "../_shared/signals.ts";
import { bearer, hasEmoji, mockFetch, type Responder, testDb } from "../_shared/testing.ts";
import { CARD_SCHEMA, createHandler, SYSTEM } from "./handler.ts";

const NOW = new Date("2026-02-01T00:00:00Z");
const iso = (daysAgo: number) => new Date(NOW.getTime() - daysAgo * 864e5).toISOString();

class StubConnector extends SignalConnector {
  readonly id = "stub";
  fetch(_w: TimeWindow) {
    return Promise.resolve([{ keyword: "frog", value: 10, observedAt: NOW }]);
  }
}

class MemoryStore implements SignalStore {
  constructor(private rows: SignalRow[]) {}
  save(_s: Signal[]) {
    return Promise.resolve();
  }
  since() {
    return Promise.resolve(this.rows);
  }
}

class FakeLlm implements LlmClient {
  calls: CompleteOptions[] = [];
  constructor(private result: Completion) {}
  complete(o: CompleteOptions) {
    this.calls.push(o);
    return Promise.resolve(this.result);
  }
}

const growing: SignalRow[] = [
  { source: "stub", keyword: "frog", niche: "cottagecore", value: 10, observed_at: iso(1) },
  { source: "stub", keyword: "frog", niche: "cottagecore", value: 1, observed_at: iso(20) },
];
const cards = (...keywords: string[]) => ({
  text: JSON.stringify({
    cards: keywords.map((k) => ({
      keyword: k,
      title: `T ${k}`,
      why: "Because.",
      item_idea: "Pin",
    })),
  }),
  refused: false,
});
const trendsRest = (status = 201): Responder => (r) =>
  r.url.pathname === "/rest/v1/trends" ? new Response(null, { status }) : undefined;

function setup(opts: { rows?: SignalRow[]; llm?: FakeLlm; trends?: Responder } = {}) {
  const { fetch, calls } = mockFetch(opts.trends ?? trendsRest());
  const llm = opts.llm ?? new FakeLlm(cards("frog"));
  const handler = createHandler({
    db: testDb(fetch),
    llm,
    aggregator: new Aggregator([new StubConnector()], new MemoryStore(opts.rows ?? growing)),
    cronSecret: "cron",
    now: () => NOW,
  });
  return { handler, llm, calls };
}
const run = (handler: (r: Request) => Promise<Response>, headers: HeadersInit = bearer("cron")) =>
  handler(new Request("http://fn", { method: "POST", headers }));

Deno.test("prompt forbids emojis and the schema is strict", () => {
  assert(SYSTEM.includes("No emojis"));
  assert(!hasEmoji(SYSTEM));
  assertEquals(CARD_SCHEMA.additionalProperties, false);
});

Deno.test("requires the cron secret", async () => {
  const { handler } = setup();
  assertEquals((await run(handler, {})).status, 401);
  assertEquals((await run(handler, bearer("nope"))).status, 401);
});

Deno.test("publishes a new snapshot then removes the old one", async () => {
  const { handler, calls, llm } = setup();
  const res = await run(handler);
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.trends, 1);
  assertEquals(body.collected, [{ id: "stub", count: 1 }]);

  const upsert = calls.find((c) => c.method === "POST");
  const rows = JSON.parse(upsert!.body);
  assertEquals(rows[0].id, "frog");
  assertEquals(rows[0].title, "T frog");
  assertEquals(rows[0].sources, ["stub"]);
  assertEquals(rows[0].snapshot_version, NOW.toISOString());

  const del = calls.find((c) => c.method === "DELETE");
  assertEquals(del!.url.searchParams.get("snapshot_version"), `neq.${NOW.toISOString()}`);
  assert(calls.indexOf(upsert!) < calls.indexOf(del!), "upsert happens before delete");
  assertEquals(llm.calls[0].schema, CARD_SCHEMA);
});

Deno.test("returns trends 0 and skips the model when nothing is trending", async () => {
  const { handler, llm } = setup({ rows: [] });
  assertEquals(await (await run(handler)).json(), {
    ok: true,
    collected: [{ id: "stub", count: 1 }],
    trends: 0,
  });
  assertEquals(llm.calls.length, 0);
});

Deno.test("a model refusal publishes nothing", async () => {
  const { handler, calls } = setup({ llm: new FakeLlm({ text: "", refused: true }) });
  assertEquals((await run(handler)).status, 422);
  assertEquals(calls.length, 0);
});

Deno.test("invalid model output and cards for unknown keywords publish nothing", async () => {
  const bad = setup({ llm: new FakeLlm({ text: "not json", refused: false }) });
  assertEquals((await run(bad.handler)).status, 502);
  const unknown = setup({ llm: new FakeLlm(cards("something else")) });
  assertEquals((await run(unknown.handler)).status, 502);
  assertEquals(unknown.calls.length, 0);
});

Deno.test("a failed upsert keeps the previous snapshot", async () => {
  const { handler, calls } = setup({
    trends: (
      r,
    ) => (r.url.pathname === "/rest/v1/trends"
      ? new Response(JSON.stringify({ message: "x" }), {
        status: 400,
        headers: { "content-type": "application/json" },
      })
      : undefined),
  });
  assertEquals((await run(handler)).status, 500);
  assert(!calls.some((c) => c.method === "DELETE"));
});
