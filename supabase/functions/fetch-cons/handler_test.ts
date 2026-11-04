import { assert, assertEquals } from "jsr:@std/assert@1";
import { bearer, jsonResponse, mockFetch, testDb } from "../_shared/testing.ts";
import { createHandler, fetchFromFeed, parseCon } from "./handler.ts";

const NOW = new Date("2026-02-01T00:00:00Z");
const good = {
  external_id: "ac-1",
  name: "Anime Expo",
  starts_at: "2026-07-02",
  ends_at: "2026-07-05",
  city: "Los Angeles",
  junk: "dropped",
};
const post = (headers: HeadersInit = bearer("cron")) =>
  new Request("http://fn", { method: "POST", headers });

Deno.test("parseCon keeps known fields, drops unknown ones, rejects malformed records", () => {
  assertEquals(parseCon(good), {
    external_id: "ac-1",
    name: "Anime Expo",
    starts_at: "2026-07-02",
    ends_at: "2026-07-05",
    city: "Los Angeles",
  });
  assertEquals(parseCon({ ...good, starts_at: "not a date" }), null);
  assertEquals(parseCon({ name: "no id" }), null);
  assertEquals(parseCon("string"), null);
  assertEquals(parseCon(null), null);
});

Deno.test("stub: with no feed url it makes no request at all", async () => {
  const { fetch, calls } = mockFetch();
  const { fetch: dbFetch } = mockFetch();
  const res = await createHandler({
    db: testDb(dbFetch),
    fetchFn: fetch,
    feedUrl: undefined,
    cronSecret: "cron",
  })(post());
  assertEquals(await res.json(), { ok: true, count: 0 });
  assertEquals(calls.length, 0);
});

Deno.test("requires the cron secret", async () => {
  const { fetch } = mockFetch();
  const h = createHandler({
    db: testDb(fetch),
    fetchFn: fetch,
    feedUrl: undefined,
    cronSecret: "cron",
  });
  assertEquals((await h(post({}))).status, 401);
  assertEquals((await h(post(bearer("x")))).status, 401);
});

Deno.test("with a feed url it makes exactly one GET to that url and upserts valid rows", async () => {
  const feed = mockFetch(() => jsonResponse([good, { bad: true }]));
  const db = mockFetch((
    r,
  ) => (r.url.pathname === "/rest/v1/cons" ? new Response(null, { status: 201 }) : undefined));
  const res = await createHandler({
    db: testDb(db.fetch),
    fetchFn: feed.fetch,
    feedUrl: "https://feed.example/cons.json",
    cronSecret: "cron",
    now: () => NOW,
  })(post());
  assertEquals(await res.json(), { ok: true, count: 1 });
  assertEquals(feed.calls.length, 1);
  assertEquals(feed.calls[0].method, "GET");
  assertEquals(feed.calls[0].url.href, "https://feed.example/cons.json");
  const rows = JSON.parse(db.calls[0].body);
  assertEquals(rows, [{
    external_id: "ac-1",
    name: "Anime Expo",
    starts_at: "2026-07-02",
    ends_at: "2026-07-05",
    city: "Los Angeles",
    fetched_at: NOW.toISOString(),
  }]);
});

Deno.test("a feed error returns 502 and writes nothing", async () => {
  const feed = mockFetch(() => new Response("", { status: 500 }));
  const db = mockFetch();
  const res = await createHandler({
    db: testDb(db.fetch),
    fetchFn: feed.fetch,
    feedUrl: "https://feed.example/x",
    cronSecret: "cron",
  })(post());
  assertEquals(res.status, 502);
  assertEquals(db.calls.length, 0);
});

Deno.test("a non-array feed body is rejected", async () => {
  const feed = mockFetch(() => jsonResponse({ html: "<html>" }));
  let message = "";
  try {
    await fetchFromFeed("https://feed.example/x", feed.fetch);
  } catch (e) {
    message = (e as Error).message;
  }
  assert(message.includes("not a JSON array"));
});
