import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";
import { anthropicClient, LlmBusyError, LlmUpstreamError } from "./llm.ts";
import { jsonResponse, mockFetch } from "./testing.ts";

const message = (text: string, stop = "end_turn") => ({
  id: "msg_1",
  type: "message",
  role: "assistant",
  model: "m",
  content: [{ type: "text", text }],
  stop_reason: stop,
  stop_sequence: null,
  usage: { input_tokens: 1, output_tokens: 1 },
});

const opts = { system: "SYS", user: "USER", maxTokens: 10, effort: "low" as const };

Deno.test("anthropicClient sends system, user and effort and returns trimmed text", async () => {
  const { fetch, calls } = mockFetch((
    r,
  ) => (r.url.pathname.endsWith("/v1/messages") ? jsonResponse(message("  hello  ")) : undefined));
  const out = await anthropicClient("k", fetch).complete(opts);
  assertEquals(out, { text: "hello", refused: false });
  const body = JSON.parse(calls[0].body);
  assertEquals(body.system, "SYS");
  assertEquals(body.messages, [{ role: "user", content: "USER" }]);
  assertEquals(body.output_config.effort, "low");
  assert(!("format" in body.output_config));
});

Deno.test("anthropicClient passes a JSON schema as structured output", async () => {
  const { fetch, calls } = mockFetch(() => jsonResponse(message("{}")));
  await anthropicClient("k", fetch).complete({ ...opts, schema: { type: "object" } });
  assertEquals(JSON.parse(calls[0].body).output_config.format, {
    type: "json_schema",
    schema: { type: "object" },
  });
});

Deno.test("anthropicClient reports refusals", async () => {
  const { fetch } = mockFetch(() => jsonResponse(message("", "refusal")));
  assertEquals((await anthropicClient("k", fetch).complete(opts)).refused, true);
});

const errorBody = { type: "error", error: { type: "rate_limit_error", message: "slow down" } };

Deno.test("anthropicClient maps 429 to LlmBusyError", async () => {
  const { fetch } = mockFetch(() => jsonResponse(errorBody, 429, { "retry-after": "0" }));
  await assertRejects(() => anthropicClient("k", fetch).complete(opts), LlmBusyError);
});

Deno.test("anthropicClient maps other API errors to LlmUpstreamError", async () => {
  const { fetch } = mockFetch(() =>
    jsonResponse({ type: "error", error: { type: "invalid_request_error", message: "bad" } }, 400)
  );
  const err = await assertRejects(
    () => anthropicClient("k", fetch).complete(opts),
    LlmUpstreamError,
  );
  assertEquals((err as LlmUpstreamError).status, 400);
});
