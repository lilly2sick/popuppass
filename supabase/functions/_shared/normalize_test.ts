import { assertEquals } from "jsr:@std/assert@1";
import { nicheFor, normalizeKeyword, trendId } from "./normalize.ts";

Deno.test("normalizeKeyword lowercases, trims and collapses whitespace", () => {
  assertEquals(normalizeKeyword("  Black   Cat  "), "black cat");
});

Deno.test("normalizeKeyword maps known synonyms", () => {
  assertEquals(normalizeKeyword("Frogs"), "frog");
  assertEquals(normalizeKeyword("kitten"), "cat");
});

Deno.test("nicheFor prefers the given hint", () => {
  assertEquals(nicheFor("frog", "anime"), "anime");
});

Deno.test("nicheFor falls back to the hint table, then general", () => {
  assertEquals(nicheFor("frog"), "cottagecore");
  assertEquals(nicheFor("something new"), "general");
});

Deno.test("trendId slugifies and trims dashes", () => {
  assertEquals(trendId("Black Cat!"), "black-cat");
  assertEquals(trendId("!leading and trailing!"), "leading-and-trailing");
});
