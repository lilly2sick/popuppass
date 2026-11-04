import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { jsonResponse, mockFetch } from "../testing.ts";
import { RedditConnector } from "./reddit.ts";

const at = new Date("2026-01-01T00:00:00Z");
const w = { from: at, to: at };
const creds = { clientId: "id", clientSecret: "secret" };
const watch = [
  { keyword: "frog", niche: "cottagecore", weight: 1 },
  { keyword: "dragon", niche: "fantasy", weight: 1 },
];
const posts = (...titles: string[]) => ({
  data: { children: titles.map((title) => ({ data: { title } })) },
});

Deno.test("RedditConnector authenticates with client credentials and counts keyword hits", async () => {
  const { fetch, calls } = mockFetch(
    (
      r,
    ) => (r.url.pathname === "/api/v1/access_token"
      ? jsonResponse({ access_token: "tok" })
      : undefined),
    (
      r,
    ) => (r.url.pathname === "/r/cottagecore/new"
      ? jsonResponse(posts("My Frog pin", "frog stickers", "tea"))
      : undefined),
    (r) => (r.url.pathname.startsWith("/r/") ? jsonResponse(posts("nothing relevant")) : undefined),
  );
  const out = await new RedditConnector(
    creds,
    watch,
    [{ name: "cottagecore", niche: "cottagecore" }, { name: "kawaii", niche: "cute" }],
    fetch,
    () => at,
  ).fetch(w);
  assertEquals(out, [{ keyword: "frog", niche: "cottagecore", value: 2, observedAt: at }]);
  assertEquals(calls[0].headers.get("authorization"), `Basic ${btoa("id:secret")}`);
  assertEquals(calls[1].headers.get("authorization"), "Bearer tok");
});

Deno.test("RedditConnector throws when auth fails", async () => {
  const { fetch } = mockFetch(() => new Response("", { status: 401 }));
  await assertRejects(
    () => new RedditConnector(creds, watch, undefined, fetch).fetch(w),
    Error,
    "reddit auth 401",
  );
});

Deno.test("RedditConnector throws when a subreddit request fails", async () => {
  const { fetch } = mockFetch(
    (
      r,
    ) => (r.url.pathname === "/api/v1/access_token"
      ? jsonResponse({ access_token: "tok" })
      : undefined),
    () => new Response("", { status: 503 }),
  );
  await assertRejects(
    () => new RedditConnector(creds, watch, [{ name: "x", niche: "n" }], fetch).fetch(w),
    Error,
    "r/x 503",
  );
});
