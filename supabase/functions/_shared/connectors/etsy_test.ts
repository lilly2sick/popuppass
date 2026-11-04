import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { jsonResponse, mockFetch } from "../testing.ts";
import { EtsyListingsConnector } from "./etsy.ts";

const at = new Date("2026-01-01T00:00:00Z");
const w = { from: at, to: at };
const watch = [{ keyword: "frog", niche: "cottagecore", weight: 1 }, {
  keyword: "mushroom",
  niche: "cottagecore",
  weight: 1,
}];

Deno.test("EtsyListingsConnector reads the listing count per keyword with the api key header", async () => {
  const { fetch, calls } = mockFetch((r) =>
    jsonResponse({ count: r.url.searchParams.get("keywords") === "frog" ? 1200 : 800 })
  );
  const out = await new EtsyListingsConnector("KEY", watch, fetch, () => at).fetch(w);
  assertEquals(out.map((s) => [s.keyword, s.value]), [["frog", 1200], ["mushroom", 800]]);
  assertEquals(calls[0].headers.get("x-api-key"), "KEY");
  assertEquals(calls[0].url.pathname, "/v3/application/listings/active");
});

Deno.test("EtsyListingsConnector throws on an API error", async () => {
  const { fetch } = mockFetch(() => new Response("", { status: 403 }));
  await assertRejects(
    () => new EtsyListingsConnector("KEY", watch, fetch).fetch(w),
    Error,
    "etsy 403",
  );
});
