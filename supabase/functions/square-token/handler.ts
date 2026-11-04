// Exchanges / refreshes Square OAuth tokens. Holds the client secret so the
// app never does. Tokens are returned to the device and NOT stored or logged here.
import { json } from "../_shared/auth.ts";

export const SQUARE_VERSION = "2024-10-17";

export type SquareConfig = {
  appId: string | undefined;
  appSecret: string | undefined;
  production: boolean;
};

export function createHandler(deps: { fetchFn: typeof fetch; config: SquareConfig }) {
  const { fetchFn, config } = deps;
  const base = config.production
    ? "https://connect.squareup.com"
    : "https://connect.squareupsandbox.com";
  return async (req: Request): Promise<Response> => {
    if (req.method !== "POST") return json({ error: "method" }, 405);
    let body: Record<string, string | undefined>;
    try {
      body = await req.json();
    } catch {
      return json({ error: "bad_request" }, 400);
    }
    const { grant_type, code, refresh_token, redirect_uri } = body;
    if (grant_type !== "authorization_code" && grant_type !== "refresh_token") {
      return json({ error: "bad_grant" }, 400);
    }
    if (grant_type === "authorization_code" && !code) return json({ error: "missing_code" }, 400);
    if (grant_type === "refresh_token" && !refresh_token) {
      return json({ error: "missing_refresh_token" }, 400);
    }

    const res = await fetchFn(`${base}/oauth2/token`, {
      method: "POST",
      headers: { "content-type": "application/json", "Square-Version": SQUARE_VERSION },
      body: JSON.stringify({
        client_id: config.appId,
        client_secret: config.appSecret,
        grant_type,
        code,
        refresh_token,
        redirect_uri,
      }),
    });
    const out = await res.json();
    if (!res.ok) return json({ error: "square", detail: out.errors ?? null }, 400);
    return json({
      access_token: out.access_token,
      refresh_token: out.refresh_token,
      expires_at: out.expires_at,
      merchant_id: out.merchant_id,
    });
  };
}
