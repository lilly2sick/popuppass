// Free-tier Supabase projects pause after 7 days without activity (SPEC 4 note).
// A daily cron call to this function runs one cheap query and keeps the project awake.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { hasBearerSecret, json } from "../_shared/auth.ts";

export function createHandler(
  deps: { db: SupabaseClient; cronSecret: string | undefined; now?: () => Date },
) {
  return async (req: Request): Promise<Response> => {
    if (!hasBearerSecret(req, deps.cronSecret)) return json({ error: "unauthorized" }, 401);
    const { error } = await deps.db.from("cons").select("external_id").limit(1);
    if (error) return json({ ok: false, error: "db_unreachable" }, 503);
    return json({ ok: true, at: (deps.now ?? (() => new Date()))().toISOString() });
  };
}
