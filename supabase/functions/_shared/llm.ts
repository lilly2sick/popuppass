// The one place that talks to Anthropic. Handlers depend on the LlmClient
// interface so tests can inject a fake or a mocked fetch.
import Anthropic from "npm:@anthropic-ai/sdk";

export const MODEL = "claude-opus-5-5";

export type Completion = { text: string; refused: boolean };
export type CompleteOptions = {
  system: string;
  user: string;
  maxTokens: number;
  effort: "low" | "medium";
  /** JSON schema for structured output (build-trends). */
  schema?: Record<string, unknown>;
};

export interface LlmClient {
  complete(opts: CompleteOptions): Promise<Completion>;
}

/** Provider is rate limiting us. */
export class LlmBusyError extends Error {}
/** Provider returned another error status. */
export class LlmUpstreamError extends Error {
  constructor(public status: number | undefined) {
    super(`upstream ${status}`);
  }
}

export function anthropicClient(apiKey: string | undefined, fetchFn?: typeof fetch): LlmClient {
  const client = new Anthropic({ apiKey, fetch: fetchFn });
  return {
    async complete(o) {
      try {
        const response = await client.beta.messages.create({
          model: MODEL,
          max_tokens: o.maxTokens,
          output_config: {
            effort: o.effort,
            ...(o.schema ? { format: { type: "json_schema", schema: o.schema } } : {}),
          },
          betas: ["server-side-fallback-2026-07-01"],
          fallbacks: "default",
          system: o.system,
          messages: [{ role: "user", content: o.user }],
        });
        const text = response.content.flatMap((b) => (b.type === "text" ? [b.text] : [])).join("")
          .trim();
        return { text, refused: response.stop_reason === "refusal" };
      } catch (error) {
        if (error instanceof Anthropic.RateLimitError) throw new LlmBusyError();
        if (error instanceof Anthropic.APIError) throw new LlmUpstreamError(error.status);
        throw error;
      }
    },
  };
}
