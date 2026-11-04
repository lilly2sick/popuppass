import { assertEquals } from "jsr:@std/assert@1";
import { GoogleTrendsConnector } from "./google_trends.ts";

Deno.test("GoogleTrendsConnector is an inert placeholder that returns nothing", async () => {
  const at = new Date();
  assertEquals(await new GoogleTrendsConnector("KEY").fetch({ from: at, to: at }), []);
});
