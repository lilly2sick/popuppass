import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { SupabaseSignalStore } from "./aggregator.ts";
import { jsonResponse, mockFetch, testDb } from "./testing.ts";

Deno.test("SupabaseSignalStore.save inserts rows into signals_raw", async () => {
  const { fetch, calls } = mockFetch((r) =>
    r.url.pathname === "/rest/v1/signals_raw" && r.method === "POST"
      ? new Response(null, { status: 201 })
      : undefined
  );
  await new SupabaseSignalStore(testDb(fetch)).save([
    {
      source: "curated",
      keyword: "frog",
      niche: "cottagecore",
      value: 8,
      observedAt: new Date("2026-01-01T00:00:00Z"),
    },
  ]);
  const body = JSON.parse(calls[0].body);
  assertEquals(body, [{
    source: "curated",
    keyword: "frog",
    niche: "cottagecore",
    value: 8,
    observed_at: "2026-01-01T00:00:00.000Z",
    meta: {},
  }]);
});

Deno.test("SupabaseSignalStore.save throws on a database error", async () => {
  const { fetch } = mockFetch(() => jsonResponse({ message: "nope" }, 400));
  await assertRejects(
    () =>
      new SupabaseSignalStore(testDb(fetch)).save([
        { source: "s", keyword: "k", niche: "n", value: 1, observedAt: new Date() },
      ]),
    Error,
    "signals_raw insert",
  );
});

Deno.test("SupabaseSignalStore.since filters by observed_at", async () => {
  const { fetch, calls } = mockFetch((r) =>
    r.url.pathname === "/rest/v1/signals_raw" && r.method === "GET"
      ? jsonResponse([{
        source: "a",
        keyword: "k",
        niche: "n",
        value: 1,
        observed_at: "2026-01-02T00:00:00Z",
      }])
      : undefined
  );
  const rows = await new SupabaseSignalStore(testDb(fetch)).since(new Date("2026-01-01T00:00:00Z"));
  assertEquals(rows.length, 1);
  assertEquals(calls[0].url.searchParams.get("observed_at"), "gte.2026-01-01T00:00:00.000Z");
});
