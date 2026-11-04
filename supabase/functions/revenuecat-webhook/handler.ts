// The only writer of profiles.is_pro. RevenueCat app_user_id = Supabase user id.
// RevenueCat sends the Authorization header configured in its dashboard; we
// compare it with REVENUECAT_WEBHOOK_SECRET.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { hasBearerSecret, json } from "../_shared/auth.ts";

export const GRANT = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "TRANSFER",
]);
export const REVOKE = new Set(["EXPIRATION", "BILLING_ISSUE"]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

type Event = {
  type?: string;
  app_user_id?: string;
  entitlement_ids?: string[] | null;
  expiration_at_ms?: number | null;
};

export function createHandler(deps: { db: SupabaseClient; secret: string | undefined }) {
  return async (req: Request): Promise<Response> => {
    if (!hasBearerSecret(req, deps.secret)) return json({ error: "unauthorized" }, 401);
    let event: Event | undefined;
    try {
      event = (await req.json()).event;
    } catch {
      return json({ error: "bad_request" }, 400);
    }
    const userId = event?.app_user_id;
    if (!event || !userId || !UUID.test(userId)) return json({ ok: true, skipped: "anonymous" });
    if (!(event.entitlement_ids ?? []).includes("pro")) {
      return json({ ok: true, skipped: "other_entitlement" });
    }

    let patch: Record<string, unknown> | null = null;
    if (event.type && GRANT.has(event.type)) {
      patch = {
        is_pro: true,
        pro_expires_at: event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null,
      };
    } else if (event.type && REVOKE.has(event.type)) {
      patch = { is_pro: false };
    }
    // CANCELLATION keeps access until expiration; EXPIRATION revokes it.
    if (patch) {
      const { error } = await deps.db.from("profiles").update(patch).eq("id", userId);
      if (error) return json({ error: "update_failed" }, 500);
    }
    return json({ ok: true });
  };
}
