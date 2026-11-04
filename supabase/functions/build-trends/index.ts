import { Aggregator, SupabaseSignalStore } from "../_shared/aggregator.ts";
import { admin } from "../_shared/auth.ts";
import { buildConnectors } from "../_shared/connectors/registry.ts";
import { anthropicClient } from "../_shared/llm.ts";
import { createHandler } from "./handler.ts";

const db = admin();
Deno.serve(createHandler({
  db,
  llm: anthropicClient(Deno.env.get("ANTHROPIC_API_KEY")),
  aggregator: new Aggregator(
    buildConnectors((k) => Deno.env.get(k)),
    new SupabaseSignalStore(db),
  ),
  cronSecret: Deno.env.get("CRON_SECRET"),
}));
