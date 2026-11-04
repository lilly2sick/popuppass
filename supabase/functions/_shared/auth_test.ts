import { assert, assertEquals } from "jsr:@std/assert@1";
import { hasBearerSecret, requireUser } from "./auth.ts";
import { authUser, jsonResponse, mockFetch, testDb } from "./testing.ts";

Deno.test("hasBearerSecret matches an exact bearer token", () => {
  const req = new Request("http://x", { headers: { authorization: "Bearer topsecret" } });
  assert(hasBearerSecret(req, "topsecret"));
});

Deno.test("hasBearerSecret rejects a wrong token", () => {
  const req = new Request("http://x", { headers: { authorization: "Bearer wrong" } });
  assert(!hasBearerSecret(req, "topsecret"));
});

Deno.test("hasBearerSecret rejects when the secret is unset", () => {
  const req = new Request("http://x", { headers: { authorization: "Bearer anything" } });
  assert(!hasBearerSecret(req, undefined));
  assert(!hasBearerSecret(req, ""));
});

Deno.test("hasBearerSecret rejects a missing header", () => {
  const req = new Request("http://x");
  assert(!hasBearerSecret(req, "topsecret"));
});

Deno.test("requireUser returns the user for a valid token", async () => {
  const { fetch } = mockFetch((r) => (r.url.pathname === "/auth/v1/user" ? authUser() : undefined));
  const db = testDb(fetch);
  const req = new Request("http://x", { headers: { authorization: "Bearer good" } });
  const user = await requireUser(req, db);
  assertEquals(user?.id, "aaaaaaaa-0000-0000-0000-000000000001");
});

Deno.test("requireUser returns null without a token", async () => {
  const { fetch } = mockFetch();
  const db = testDb(fetch);
  assertEquals(await requireUser(new Request("http://x"), db), null);
});

Deno.test("requireUser returns null when the auth server rejects the token", async () => {
  const { fetch } = mockFetch((r) =>
    r.url.pathname === "/auth/v1/user" ? jsonResponse({ error: "invalid" }, 401) : undefined
  );
  const db = testDb(fetch);
  const req = new Request("http://x", { headers: { authorization: "Bearer bad" } });
  assertEquals(await requireUser(req, db), null);
});
