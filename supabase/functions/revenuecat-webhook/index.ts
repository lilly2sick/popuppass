import { admin } from "../_shared/auth.ts";
import { createHandler } from "./handler.ts";

Deno.serve(createHandler({ db: admin(), secret: Deno.env.get("REVENUECAT_WEBHOOK_SECRET") }));
