import { assertEquals } from "jsr:@std/assert@1";
import { bearer, jsonResponse, mockFetch, testDb } from "../_shared/testing.ts";
import { createHandler } from "./handler.ts";

const NOW = new Date("2026-02-01T00:00:00Z");
const post = (headers: HeadersInit = bearer("cron")) =>
  new Request("http://fn", { method: "POST", headers });

Deno.test("requires the cron secret", async () => {
  const { fetch } = mockFetch();
  const h = createHandler({ db: testDb(fetch), cronSecret: "cron" });
  assertEquals((await h(post({}))).status, 401);
  assertEquals((await h(post(bearer("x")))).status, 401);
});

Deno.test("runs one cheap query against the database", async () => {
  const { fetch, calls } = mockFetch((
    r,
  ) => (r.url.pathname === "/rest/v1/cons" ? jsonResponse([]) : undefined));
  const res = await createHandler({ db: testDb(fetch), cronSecret: "cron", now: () => NOW })(
    post(),
  );
  assertEquals(await res.json(), { ok: true, at: NOW.toISOString() });
  assertEquals(calls.length, 1);
  assertEquals(calls[0].url.searchParams.get("limit"), "1");
});

Deno.test("reports 503 when the database is unreachable", async () => {
  const { fetch } = mockFetch(() => jsonResponse({ message: "down" }, 500));
  assertEquals(
    (await createHandler({ db: testDb(fetch), cronSecret: "cron" })(post())).status,
    503,
  );
});
