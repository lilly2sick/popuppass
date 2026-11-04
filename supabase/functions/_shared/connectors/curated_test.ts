import { assertEquals } from "jsr:@std/assert@1";
import { CuratedConnector } from "./curated.ts";

Deno.test("CuratedConnector emits each item with its weight and no network", async () => {
  const at = new Date("2026-01-01T00:00:00Z");
  const c = new CuratedConnector([{ keyword: "frog", niche: "cottagecore", weight: 8 }], () => at);
  assertEquals(await c.fetch({ from: at, to: at }), [
    { keyword: "frog", niche: "cottagecore", value: 8, observedAt: at },
  ]);
});
