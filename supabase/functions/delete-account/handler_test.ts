import { assertEquals } from "jsr:@std/assert@1";
import {
  authUser,
  bearer,
  jsonResponse,
  mockFetch,
  type Responder,
  testDb,
  USER_ID,
} from "../_shared/testing.ts";
import { createHandler } from "./handler.ts";

const user: Responder = (r) => (r.url.pathname === "/auth/v1/user" ? authUser() : undefined);
const req = (headers: HeadersInit = bearer("jwt")) =>
  new Request("http://fn", { method: "POST", headers });

Deno.test("requires a valid JWT", async () => {
  const { fetch } = mockFetch((
    r,
  ) => (r.url.pathname === "/auth/v1/user" ? jsonResponse({}, 401) : undefined));
  assertEquals((await createHandler({ db: testDb(fetch) })(req())).status, 401);
  assertEquals((await createHandler({ db: testDb(fetch) })(req({}))).status, 401);
});

Deno.test("removes the user's photos, then deletes the auth user", async () => {
  let listed = 0;
  const { fetch, calls } = mockFetch(
    user,
    (r) => {
      if (r.url.pathname === "/storage/v1/object/list/photos") {
        return jsonResponse(listed++ === 0 ? [{ name: "a.jpg" }, { name: "b.jpg" }] : []);
      }
    },
    (
      r,
    ) => (r.url.pathname === "/storage/v1/object/photos" && r.method === "DELETE"
      ? jsonResponse([])
      : undefined),
    (
      r,
    ) => (r.url.pathname === `/auth/v1/admin/users/${USER_ID}` && r.method === "DELETE"
      ? jsonResponse({})
      : undefined),
  );
  const res = await createHandler({ db: testDb(fetch) })(req());
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { ok: true });

  const list = calls.find((c) => c.url.pathname.includes("/object/list/"));
  assertEquals(JSON.parse(list!.body).prefix, USER_ID);
  const remove = calls.find((c) =>
    c.method === "DELETE" && c.url.pathname === "/storage/v1/object/photos"
  );
  assertEquals(JSON.parse(remove!.body).prefixes, [`${USER_ID}/a.jpg`, `${USER_ID}/b.jpg`]);
  assertEquals(calls.at(-1)!.url.pathname, `/auth/v1/admin/users/${USER_ID}`);
});

Deno.test("works for an account with no photos", async () => {
  const { fetch, calls } = mockFetch(
    user,
    (r) => (r.url.pathname.includes("/object/list/") ? jsonResponse([]) : undefined),
    (r) => (r.url.pathname.startsWith("/auth/v1/admin/users/") ? jsonResponse({}) : undefined),
  );
  assertEquals((await createHandler({ db: testDb(fetch) })(req())).status, 200);
  assertEquals(
    calls.some((c) => c.method === "DELETE" && c.url.pathname === "/storage/v1/object/photos"),
    false,
  );
});

Deno.test("a failing auth delete returns 500", async () => {
  const { fetch } = mockFetch(
    user,
    (r) => (r.url.pathname.includes("/object/list/") ? jsonResponse([]) : undefined),
    (
      r,
    ) => (r.url.pathname.startsWith("/auth/v1/admin/users/")
      ? jsonResponse({ message: "x" }, 500)
      : undefined),
  );
  const res = await createHandler({ db: testDb(fetch) })(req());
  assertEquals(res.status, 500);
  assertEquals((await res.json()).error, "delete_failed");
});

Deno.test("a failing storage cleanup stops before deleting the user", async () => {
  const { fetch, calls } = mockFetch(
    user,
    (
      r,
    ) => (r.url.pathname.includes("/object/list/")
      ? jsonResponse({ message: "x" }, 500)
      : undefined),
  );
  assertEquals((await createHandler({ db: testDb(fetch) })(req())).status, 500);
  assertEquals(calls.some((c) => c.url.pathname.startsWith("/auth/v1/admin/users/")), false);
});
