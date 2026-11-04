import { assertEquals } from "jsr:@std/assert@1";
import { bearer, jsonResponse, mockFetch, testDb, USER_ID } from "../_shared/testing.ts";
import { createHandler } from "./handler.ts";

const SECRET = "rc-secret";
const profiles = (r: { url: URL; method: string }) =>
  r.url.pathname === "/rest/v1/profiles" && r.method === "PATCH"
    ? new Response(null, { status: 204 })
    : undefined;

function setup() {
  const { fetch, calls } = mockFetch(profiles);
  return { handler: createHandler({ db: testDb(fetch), secret: SECRET }), calls };
}
const send = (
  handler: (r: Request) => Promise<Response>,
  event: unknown,
  headers: HeadersInit = bearer(SECRET),
) =>
  handler(new Request("http://fn", { method: "POST", headers, body: JSON.stringify({ event }) }));
const ev = (over: Record<string, unknown>) => ({
  type: "INITIAL_PURCHASE",
  app_user_id: USER_ID,
  entitlement_ids: ["pro"],
  ...over,
});

Deno.test("verifies the Authorization header", async () => {
  const { handler, calls } = setup();
  assertEquals((await send(handler, ev({}), {})).status, 401);
  assertEquals((await send(handler, ev({}), bearer("wrong"))).status, 401);
  assertEquals((await send(handler, ev({}), { authorization: SECRET })).status, 401);
  assertEquals(calls.length, 0);
});

Deno.test("an unset webhook secret rejects everything, including 'Bearer undefined'", async () => {
  const { fetch, calls } = mockFetch(profiles);
  const handler = createHandler({ db: testDb(fetch), secret: undefined });
  assertEquals((await send(handler, ev({}), bearer("undefined"))).status, 401);
  assertEquals(calls.length, 0);
});

Deno.test("a grant sets is_pro and the expiry", async () => {
  const { handler, calls } = setup();
  const exp = Date.parse("2027-01-01T00:00:00Z");
  assertEquals((await send(handler, ev({ expiration_at_ms: exp }))).status, 200);
  assertEquals(JSON.parse(calls[0].body), {
    is_pro: true,
    pro_expires_at: "2027-01-01T00:00:00.000Z",
  });
  assertEquals(calls[0].url.searchParams.get("id"), `eq.${USER_ID}`);
});

Deno.test("every grant type grants, every revoke type revokes", async () => {
  for (
    const type of ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE", "TRANSFER"]
  ) {
    const { handler, calls } = setup();
    await send(handler, ev({ type }));
    assertEquals(JSON.parse(calls[0].body).is_pro, true, type);
  }
  for (const type of ["EXPIRATION", "BILLING_ISSUE"]) {
    const { handler, calls } = setup();
    await send(handler, ev({ type }));
    assertEquals(JSON.parse(calls[0].body), { is_pro: false }, type);
  }
});

Deno.test("CANCELLATION keeps access until expiration", async () => {
  const { handler, calls } = setup();
  assertEquals((await send(handler, ev({ type: "CANCELLATION" }))).status, 200);
  assertEquals(calls.length, 0);
});

Deno.test("anonymous users and other entitlements are skipped", async () => {
  const { handler, calls } = setup();
  assertEquals(await (await send(handler, ev({ app_user_id: "$RCAnonymousID:abc" }))).json(), {
    ok: true,
    skipped: "anonymous",
  });
  assertEquals(await (await send(handler, ev({ entitlement_ids: ["other"] }))).json(), {
    ok: true,
    skipped: "other_entitlement",
  });
  assertEquals(await (await send(handler, ev({ entitlement_ids: null }))).json(), {
    ok: true,
    skipped: "other_entitlement",
  });
  assertEquals(calls.length, 0);
});

Deno.test("malformed bodies return 400 and database errors return 500", async () => {
  const { handler } = setup();
  const res = await handler(
    new Request("http://fn", { method: "POST", headers: bearer(SECRET), body: "{" }),
  );
  assertEquals(res.status, 400);

  const { fetch } = mockFetch(() => jsonResponse({ message: "x" }, 500));
  assertEquals(
    (await send(createHandler({ db: testDb(fetch), secret: SECRET }), ev({}))).status,
    500,
  );
});
