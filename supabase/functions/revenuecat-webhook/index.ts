// The only writer of profiles.is_pro. RevenueCat app_user_id = Supabase user id.
import { admin, json } from "../_shared/auth.ts";

const GRANT = new Set(["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE", "TRANSFER"]);
const REVOKE = new Set(["EXPIRATION", "BILLING_ISSUE"]);

Deno.serve(async (req) => {
  if (req.headers.get("authorization") !== `Bearer ${Deno.env.get("REVENUECAT_WEBHOOK_SECRET")}`) {
    return json({ error: "unauthorized" }, 401);
  }
  const { event } = await req.json();
  const userId: string | undefined = event?.app_user_id;
  if (!userId || !/^[0-9a-f-]{36}$/.test(userId)) return json({ ok: true, skipped: "anonymous" });
  if (!(event.entitlement_ids ?? []).includes("pro")) return json({ ok: true, skipped: "other_entitlement" });

  let patch: Record<string, unknown> | null = null;
  if (GRANT.has(event.type)) {
    patch = { is_pro: true, pro_expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null };
  } else if (REVOKE.has(event.type)) {
    patch = { is_pro: false };
  }
  // CANCELLATION keeps access until expiration; EXPIRATION revokes it.
  if (patch) await admin().from("profiles").update(patch).eq("id", userId);
  return json({ ok: true });
});
