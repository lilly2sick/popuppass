// Required by both app stores. Deleting the auth user cascades every table;
// storage objects are removed explicitly.
import { admin, json, requireUser } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  const user = await requireUser(req);
  if (!user) return json({ error: "unauthorized" }, 401);
  const db = admin();

  const { data: files } = await db.storage.from("photos").list(user.id, { limit: 1000 });
  if (files?.length) await db.storage.from("photos").remove(files.map((f) => `${user.id}/${f.name}`));

  const { error } = await db.auth.admin.deleteUser(user.id);
  if (error) return json({ error: "delete_failed" }, 500);
  return json({ ok: true });
});
