import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { jsonResponse, mockFetch } from "../testing.ts";
import { PinterestTrendsConnector } from "./pinterest.ts";

const at = new Date("2026-01-01T00:00:00Z");
const w = { from: at, to: at };

Deno.test("PinterestTrendsConnector keeps growing keywords and sends the bearer token", async () => {
  const { fetch, calls } = mockFetch(() =>
    jsonResponse({
      trends: [
        { keyword: "frog pin", pct_growth_wow: 40 },
        { keyword: "shrinking", pct_growth_wow: -5 },
        { keyword: "no growth field" },
      ],
    })
  );
  const out = await new PinterestTrendsConnector("TOKEN", "US", fetch, () => at).fetch(w);
  assertEquals(out, [{ keyword: "frog pin", value: 40, observedAt: at }]);
  assertEquals(calls[0].headers.get("authorization"), "Bearer TOKEN");
  assertEquals(calls[0].url.pathname, "/v5/trends/keywords/US/top/growing");
});

Deno.test("PinterestTrendsConnector throws on an API error", async () => {
  const { fetch } = mockFetch(() => new Response("", { status: 401 }));
  await assertRejects(
    () => new PinterestTrendsConnector("T", "US", fetch).fetch(w),
    Error,
    "pinterest 401",
  );
});
