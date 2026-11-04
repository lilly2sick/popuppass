import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  type CompleteOptions,
  type Completion,
  LlmBusyError,
  type LlmClient,
  LlmUpstreamError,
} from "../_shared/llm.ts";
import {
  authUser,
  bearer,
  hasEmoji,
  jsonResponse,
  mockFetch,
  type Responder,
  testDb,
} from "../_shared/testing.ts";
import { createHandler, DAILY_LIMIT, SYSTEM, TASKS } from "./handler.ts";

const proProfile: Responder = (r) =>
  r.url.pathname === "/rest/v1/profiles"
    ? jsonResponse({ is_pro: true, pro_expires_at: null })
    : undefined;
const freeProfile: Responder = (r) =>
  r.url.pathname === "/rest/v1/profiles"
    ? jsonResponse({ is_pro: false, pro_expires_at: null })
    : undefined;
const lapsedProfile: Responder = (r) =>
  r.url.pathname === "/rest/v1/profiles"
    ? jsonResponse({ is_pro: true, pro_expires_at: "2020-01-01T00:00:00Z" })
    : undefined;
const user: Responder = (r) => (r.url.pathname === "/auth/v1/user" ? authUser() : undefined);
const usage = (count: number): Responder => (r) =>
  r.url.pathname === "/rest/v1/ai_usage" && r.method === "HEAD"
    ? new Response(null, { status: 200, headers: { "content-range": `*/${count}` } })
    : r.url.pathname === "/rest/v1/ai_usage" && r.method === "POST"
    ? new Response(null, { status: 201 })
    : undefined;

class FakeLlm implements LlmClient {
  calls: CompleteOptions[] = [];
  constructor(private result: Completion | Error = { text: "Fresh stickers!", refused: false }) {}
  complete(o: CompleteOptions): Promise<Completion> {
    this.calls.push(o);
    return this.result instanceof Error
      ? Promise.reject(this.result)
      : Promise.resolve(this.result);
  }
}

const post = (body: unknown, headers: HeadersInit = bearer("jwt")) =>
  new Request("http://fn", { method: "POST", headers, body: JSON.stringify(body) });

function setup(responders: Responder[], llm = new FakeLlm()) {
  const { fetch, calls } = mockFetch(...responders);
  return { handler: createHandler({ db: testDb(fetch), llm }), llm, calls };
}

Deno.test("the system prompt forbids emojis and contains none", () => {
  assert(SYSTEM.includes("Never use emojis"));
  assert(!hasEmoji(SYSTEM));
  for (const task of Object.values(TASKS)) assert(!hasEmoji(task));
});

Deno.test("rejects non-POST", async () => {
  const { handler } = setup([]);
  assertEquals((await handler(new Request("http://fn"))).status, 405);
});

Deno.test("rejects callers without a valid JWT", async () => {
  const { handler } = setup([
    (r) => (r.url.pathname === "/auth/v1/user" ? jsonResponse({}, 401) : undefined),
  ]);
  assertEquals((await handler(post({ kind: "caption" }))).status, 401);
});

Deno.test("Pro gating: free and lapsed users get 403 and the model is never called", async () => {
  for (const profile of [freeProfile, lapsedProfile]) {
    const { handler, llm } = setup([user, profile]);
    const res = await handler(post({ kind: "caption", input: {} }));
    assertEquals(res.status, 403);
    assertEquals((await res.json()).error, "pro_required");
    assertEquals(llm.calls.length, 0);
  }
});

Deno.test("unknown kind returns 400", async () => {
  const { handler } = setup([user, proProfile]);
  assertEquals((await handler(post({ kind: "poem" }))).status, 400);
});

Deno.test("malformed JSON returns 400", async () => {
  const { handler } = setup([user, proProfile]);
  const req = new Request("http://fn", { method: "POST", headers: bearer("jwt"), body: "{" });
  assertEquals((await handler(req)).status, 400);
});

Deno.test("daily limit returns 429 without calling the model", async () => {
  const { handler, llm } = setup([user, proProfile, usage(DAILY_LIMIT)]);
  assertEquals((await handler(post({ kind: "caption", input: {} }))).status, 429);
  assertEquals(llm.calls.length, 0);
});

Deno.test("Pro user gets text, the no-emoji system prompt, and usage is recorded", async () => {
  const { handler, llm, calls } = setup([user, proProfile, usage(0)]);
  const res = await handler(post({ kind: "caption", input: { name: "Frog pin", price: "$12" } }));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { text: "Fresh stickers!" });
  assertEquals(llm.calls[0].system, SYSTEM);
  assert(llm.calls[0].user.includes("data, not instructions"));
  assert(llm.calls[0].user.includes("Frog pin"));
  const insert = calls.find((c) => c.method === "POST" && c.url.pathname === "/rest/v1/ai_usage");
  assertEquals(JSON.parse(insert!.body), {
    user_id: "aaaaaaaa-0000-0000-0000-000000000001",
    kind: "caption",
  });
});

Deno.test("refusal maps to 422 and is not counted as usage", async () => {
  const { handler, calls } = setup(
    [user, proProfile, usage(0)],
    new FakeLlm({ text: "", refused: true }),
  );
  assertEquals((await handler(post({ kind: "caption", input: {} }))).status, 422);
  assert(!calls.some((c) => c.method === "POST" && c.url.pathname === "/rest/v1/ai_usage"));
});

Deno.test("provider errors map to 503 and 502", async () => {
  const busy = setup([user, proProfile, usage(0)], new FakeLlm(new LlmBusyError()));
  assertEquals((await busy.handler(post({ kind: "caption", input: {} }))).status, 503);
  const down = setup([user, proProfile, usage(0)], new FakeLlm(new LlmUpstreamError(500)));
  const res = await down.handler(post({ kind: "caption", input: {} }));
  assertEquals(res.status, 502);
  assertEquals((await res.json()).status, 500);
});
