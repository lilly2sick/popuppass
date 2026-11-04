import { assertEquals } from "jsr:@std/assert@1";
import { mockFetch } from "../testing.ts";
import { buildConnectors, type Env } from "./registry.ts";

const env = (vars: Record<string, string>): Env => (k) => vars[k];
const ids = (vars: Record<string, string>) => {
  const { fetch } = mockFetch();
  return buildConnectors(env(vars), fetch).map((c) => c.id);
};

Deno.test("only free sources run with no configuration", () => {
  assertEquals(ids({}), ["curated", "anilist"]);
});

Deno.test("sources needing approval stay off until their env is present", () => {
  assertEquals(ids({ REDDIT_CLIENT_ID: "x" }), ["curated", "anilist"]);
  assertEquals(ids({ ETSY_API_KEY: "k" }), ["curated", "anilist", "etsy"]);
  assertEquals(ids({ PINTEREST_ACCESS_TOKEN: "t" }), ["curated", "anilist", "pinterest"]);
  assertEquals(ids({ GOOGLE_TRENDS_API_KEY: "g" }), ["curated", "anilist", "google_trends"]);
  assertEquals(ids({ REDDIT_CLIENT_ID: "x", REDDIT_CLIENT_SECRET: "y" }), [
    "curated",
    "anilist",
    "reddit",
  ]);
});
