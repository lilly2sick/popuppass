// Required by both app stores. Deleting the auth user cascades every table;
// storage objects are removed explicitly first.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { json, requireUser } from "../_shared/auth.ts";

const PAGE = 1000;
const MAX_PAGES = 50;

export function createHandler(deps: { db: SupabaseClient }) {
  const { db } = deps;
  return async (req: Request): Promise<Response> => {
    const user = await requireUser(req, db);
    if (!user) return json({ error: "unauthorized" }, 401);

    for (let page = 0; page < MAX_PAGES; page++) {
      const { data: files, error } = await db.storage.from("photos").list(user.id, { limit: PAGE });
      if (error) return json({ error: "delete_failed" }, 500);
      if (!files?.length) break;
      const { error: rmError } = await db.storage.from("photos")
        .remove(files.map((f) => `${user.id}/${f.name}`));
      if (rmError) return json({ error: "delete_failed" }, 500);
      if (files.length < PAGE) break;
    }

    const { error } = await db.auth.admin.deleteUser(user.id);
    if (error) return json({ error: "delete_failed" }, 500);
    return json({ ok: true });
  };
}
