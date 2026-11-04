// Test helpers only. Never imported by a function entrypoint.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { admin } from "./auth.ts";

export type Recorded = { method: string; url: URL; headers: Headers; body: string };
export type Responder = (req: Recorded) => Response | Promise<Response> | undefined;

/**
 * A fetch stand-in. Each responder may return a Response for requests it
 * recognises; the first match wins. Unmatched requests throw so a test can
 * never reach the network by accident.
 */
export function mockFetch(...responders: Responder[]) {
  const calls: Recorded[] = [];
  const fn = async (input: Request | URL | string, init?: RequestInit): Promise<Response> => {
    const req = new Request(input, init);
    const rec: Recorded = {
      method: req.method,
      url: new URL(req.url),
      headers: req.headers,
      body: await req.text(),
    };
    calls.push(rec);
    for (const r of responders) {
      const res = await r(rec);
      if (res) return res;
    }
    throw new Error(`unexpected fetch ${rec.method} ${rec.url}`);
  };
  return { fetch: fn as typeof fetch, calls };
}

export const jsonResponse = (body: unknown, status = 200, headers: HeadersInit = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...headers },
  });

/** Service-role Supabase client whose HTTP goes through the given fetch. */
export const testDb = (fetchFn: typeof fetch): SupabaseClient =>
  admin({ url: "http://supabase.test", key: "service-key", fetch: fetchFn });

export const USER_ID = "aaaaaaaa-0000-0000-0000-000000000001";

/** Auth-server response for GET /auth/v1/user (what db.auth.getUser calls). */
export const authUser = (id = USER_ID) =>
  jsonResponse({
    id,
    aud: "authenticated",
    role: "authenticated",
    email: "a@test.local",
    app_metadata: {},
    user_metadata: {},
    created_at: "2026-01-01T00:00:00Z",
  });

export const bearer = (token: string) => ({ authorization: `Bearer ${token}` });

/** True for any emoji or pictograph in the string. */
export const hasEmoji = (s: string) => /\p{Extended_Pictographic}/u.test(s);
