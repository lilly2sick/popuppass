import { admin } from "../_shared/auth.ts";
import { createHandler } from "./handler.ts";

Deno.serve(createHandler({
  db: admin(),
  fetchFn: fetch,
  feedUrl: Deno.env.get("ANIMECONS_FEED_URL"),
  cronSecret: Deno.env.get("CRON_SECRET"),
}));
