import { admin } from "../_shared/auth.ts";
import { anthropicClient } from "../_shared/llm.ts";
import { createHandler } from "./handler.ts";

Deno.serve(createHandler({ db: admin(), llm: anthropicClient(Deno.env.get("ANTHROPIC_API_KEY")) }));
