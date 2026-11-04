import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

/** Service-role client. Never returned to callers; secrets live in function env. */
export const admin = (): SupabaseClient =>
  createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

/** Verifies the caller's JWT and returns the user, or null. */
export async function requireUser(req: Request): Promise<User | null> {
  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await admin().auth.getUser(token);
  return error ? null : data.user;
}

export async function isPro(userId: string): Promise<boolean> {
  const { data } = await admin().from("profiles").select("is_pro, pro_expires_at").eq("id", userId).single();
  if (!data?.is_pro) return false;
  return !data.pro_expires_at || new Date(data.pro_expires_at) > new Date();
}
