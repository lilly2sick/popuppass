import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { jsonResponse, mockFetch } from "../testing.ts";
import { AniListConnector } from "./anilist.ts";

const at = new Date("2026-01-01T00:00:00Z");
const w = { from: at, to: at };

Deno.test("AniListConnector maps trending media, preferring the english title", async () => {
  const { fetch, calls } = mockFetch(() =>
    jsonResponse({
      data: {
        Page: {
          media: [
            { title: { english: "Frieren", romaji: "Sousou no Frieren" }, trending: 120 },
            { title: { english: null, romaji: "Dandadan" }, trending: 90 },
          ],
        },
      },
    })
  );
  const out = await new AniListConnector(fetch, () => at).fetch(w);
  assertEquals(out.map((s) => [s.keyword, s.value, s.niche]), [["Frieren", 120, "anime"], [
    "Dandadan",
    90,
    "anime",
  ]]);
  assertEquals(calls[0].url.href, "https://graphql.anilist.co/");
  assertEquals(calls[0].method, "POST");
});

Deno.test("AniListConnector throws on a non-2xx response", async () => {
  const { fetch } = mockFetch(() => new Response("", { status: 500 }));
  await assertRejects(() => new AniListConnector(fetch).fetch(w), Error, "anilist 500");
});
