import { assert, assertEquals } from "jsr:@std/assert@1";
import { MIN_K, OptInSalesConnector } from "./opt_in_sales.ts";

const at = new Date("2026-01-01T00:00:00Z");
const w = { from: at, to: at };
const users = (n: number, keyword: string, units = 1) =>
  Array.from({ length: n }, (_, i) => ({ userId: `u${i}`, keyword, units }));

Deno.test("OptInSalesConnector hides keywords below the k threshold", async () => {
  const c = new OptInSalesConnector(
    () => Promise.resolve(users(MIN_K - 1, "frog")),
    MIN_K,
    () => at,
  );
  assertEquals(await c.fetch(w), []);
});

Deno.test("OptInSalesConnector emits the total once k distinct vendors contribute", async () => {
  const c = new OptInSalesConnector(
    () => Promise.resolve(users(MIN_K, "Frogs", 2)),
    MIN_K,
    () => at,
  );
  const out = await c.fetch(w);
  assertEquals(out.length, 1);
  assertEquals(out[0].keyword, "frog");
  assertEquals(out[0].value, MIN_K * 2);
});

Deno.test("OptInSalesConnector counts distinct vendors, not rows", async () => {
  const rows = Array.from({ length: 20 }, () => ({ userId: "same", keyword: "frog", units: 1 }));
  assertEquals(
    await new OptInSalesConnector(() => Promise.resolve(rows), MIN_K, () => at).fetch(w),
    [],
  );
});

Deno.test("OptInSalesConnector never lets k fall below the privacy floor", () => {
  assert(new OptInSalesConnector(() => Promise.resolve([]), 1).k >= MIN_K);
  assertEquals(new OptInSalesConnector(() => Promise.resolve([]), 12).k, 12);
});

Deno.test("OptInSalesConnector output carries no user ids", async () => {
  const c = new OptInSalesConnector(() => Promise.resolve(users(MIN_K, "frog")), MIN_K, () => at);
  const text = JSON.stringify(await c.fetch(w));
  assert(!text.includes("u0"));
});
