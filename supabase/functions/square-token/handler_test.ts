import { assertEquals } from "jsr:@std/assert@1";
import { jsonResponse, mockFetch } from "../_shared/testing.ts";
import { createHandler, SQUARE_VERSION } from "./handler.ts";

const config = { appId: "APP", appSecret: "SECRET", production: false };
const post = (body: unknown) =>
  new Request("http://fn", { method: "POST", body: JSON.stringify(body) });
const tokenResponse = {
  access_token: "at",
  refresh_token: "rt",
  expires_at: "2026-03-01T00:00:00Z",
  merchant_id: "M1",
  extra: "not returned",
};

Deno.test("rejects non-POST, bad JSON and unsupported grants", async () => {
  const { fetch, calls } = mockFetch();
  const h = createHandler({ fetchFn: fetch, config });
  assertEquals((await h(new Request("http://fn"))).status, 405);
  assertEquals((await h(new Request("http://fn", { method: "POST", body: "{" }))).status, 400);
  assertEquals((await h(post({ grant_type: "password" }))).status, 400);
  assertEquals((await h(post({ grant_type: "authorization_code" }))).status, 400);
  assertEquals((await h(post({ grant_type: "refresh_token" }))).status, 400);
  assertEquals(calls.length, 0);
});

Deno.test("exchanges a code with the server-held secret and returns only the token fields", async () => {
  const { fetch, calls } = mockFetch(() => jsonResponse(tokenResponse));
  const res = await createHandler({ fetchFn: fetch, config })(
    post({ grant_type: "authorization_code", code: "CODE", redirect_uri: "popuppass://square" }),
  );
  assertEquals(await res.json(), {
    access_token: "at",
    refresh_token: "rt",
    expires_at: "2026-03-01T00:00:00Z",
    merchant_id: "M1",
  });
  assertEquals(calls[0].url.href, "https://connect.squareupsandbox.com/oauth2/token");
  assertEquals(calls[0].headers.get("square-version"), SQUARE_VERSION);
  assertEquals(JSON.parse(calls[0].body), {
    client_id: "APP",
    client_secret: "SECRET",
    grant_type: "authorization_code",
    code: "CODE",
    redirect_uri: "popuppass://square",
  });
});

Deno.test("refreshes a token against production when configured", async () => {
  const { fetch, calls } = mockFetch(() => jsonResponse(tokenResponse));
  const res = await createHandler({ fetchFn: fetch, config: { ...config, production: true } })(
    post({ grant_type: "refresh_token", refresh_token: "RT" }),
  );
  assertEquals(res.status, 200);
  assertEquals(calls[0].url.origin, "https://connect.squareup.com");
  assertEquals(JSON.parse(calls[0].body).refresh_token, "RT");
});

Deno.test("Square errors become a 400 without leaking the secret", async () => {
  const { fetch } = mockFetch(() =>
    jsonResponse({ errors: [{ code: "INVALID_REQUEST_ERROR" }] }, 401)
  );
  const res = await createHandler({ fetchFn: fetch, config })(
    post({ grant_type: "authorization_code", code: "bad" }),
  );
  const text = await res.text();
  assertEquals(res.status, 400);
  assertEquals(JSON.parse(text).detail, [{ code: "INVALID_REQUEST_ERROR" }]);
  assertEquals(text.includes("SECRET"), false);
});
