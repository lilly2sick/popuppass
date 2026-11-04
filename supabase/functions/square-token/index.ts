import { createHandler } from "./handler.ts";

Deno.serve(createHandler({
  fetchFn: fetch,
  config: {
    appId: Deno.env.get("SQUARE_APP_ID"),
    appSecret: Deno.env.get("SQUARE_APP_SECRET"),
    production: Deno.env.get("SQUARE_ENV") === "production",
  },
}));
