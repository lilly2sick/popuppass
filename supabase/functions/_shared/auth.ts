import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

export type AdminOptions = { url?: string; key?: string; fetch?: typeof fetch };

/** Service-role client. Never returned to callers; secrets live in function env. */
export const admin = (opts: AdminOptions = {}): SupabaseClient =>
  createClient(
    opts.url ?? Deno.env.get("SUPABASE_URL")!,
    opts.key ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false }, global: opts.fetch ? { fetch: opts.fetch } : undefined },
  );

/** Compares in time that does not depend on where the strings differ. */
export function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

/**
 * True when the request carries `Authorization: Bearer <secret>`. An unset or
 * empty secret never matches, so a missing env var cannot open a function.
 */
export function hasBearerSecret(req: Request, secret: string | undefined): boolean {
  if (!secret) return false;
  const header = req.headers.get("authorization");
  if (!header) return false;
  return timingSafeEqual(header, `Bearer ${secret}`);
}

/** Verifies the caller's JWT and returns the user, or null. */
export async function requireUser(req: Request, db: SupabaseClient): Promise<User | null> {
  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await db.auth.getUser(token);
  return error ? null : data.user;
}

export async function isPro(db: SupabaseClient, userId: string): Promise<boolean> {
  const { data } = await db.from("profiles").select("is_pro, pro_expires_at").eq("id", userId)
    .single();
  if (!data?.is_pro) return false;
  return !data.pro_expires_at || new Date(data.pro_expires_at) > new Date();
}
