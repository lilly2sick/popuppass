// Exchanges / refreshes Square OAuth tokens. Holds the client secret so the
// app never does. Tokens are returned to the device and NOT stored here.
import { json } from "../_shared/auth.ts";

const SQUARE = Deno.env.get("SQUARE_ENV") === "production"
  ? "https://connect.squareup.com"
  : "https://connect.squareupsandbox.com";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const { grant_type, code, refresh_token, redirect_uri } = await req.json();
  if (grant_type !== "authorization_code" && grant_type !== "refresh_token") {
    return json({ error: "bad_grant" }, 400);
  }

  const res = await fetch(`${SQUARE}/oauth2/token`, {
    method: "POST",
    headers: { "content-type": "application/json", "Square-Version": "2024-10-17" },
    body: JSON.stringify({
      client_id: Deno.env.get("SQUARE_APP_ID"),
      client_secret: Deno.env.get("SQUARE_APP_SECRET"),
      grant_type,
      code,
      refresh_token,
      redirect_uri,
    }),
  });
  const body = await res.json();
  if (!res.ok) return json({ error: "square", detail: body.errors ?? null }, 400);
  return json({
    access_token: body.access_token,
    refresh_token: body.refresh_token,
    expires_at: body.expires_at,
    merchant_id: body.merchant_id,
  });
});
