import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ─────────────────────────────────────────────────────────────────────────────
// send-notifications Edge Function
//
// Called daily by pg_cron (cloud Supabase only) at 08:00 UTC.
// See: supabase/migrations/20260528000002_add_notifications_infrastructure.sql
//      for the cron.schedule() setup instructions.
//
// What it does:
//   1. Queries items expiring within the next 3 days.
//   2. Queries items with quantity ≤ 2 (low stock).
//   3. Looks up FCM device tokens for the affected users.
//   4. Dispatches push notifications via Firebase Cloud Messaging HTTP v1 API.
//
// Required Supabase secrets (set via `supabase secrets set`):
//   FIREBASE_PROJECT_ID       — your Firebase project ID
//   FIREBASE_SERVICE_ACCOUNT  — full service account JSON (from Firebase console)
// ─────────────────────────────────────────────────────────────────────────────

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";
const corsHeaders = {
    'Access-Control-Allow-Origin': 'https://stocksense.juancruzdev.com',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (_req: Request) => {
  // Handle CORS preflight
  if (_req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders,
    });
  }
  
  try {
    // Use the service-role key so we can read all users' items.
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const today           = new Date();
    const threeDaysFromNow = new Date(today);
    threeDaysFromNow.setDate(today.getDate() + 3);

    // ── 1. Find expiring items ─────────────────────────────────────────────
    const { data: expiringItems, error: expErr } = await supabase
      .from("items")
      .select("id, item_name, user_id, expiry_date")
      .lte("expiry_date", threeDaysFromNow.toISOString())
      .gte("expiry_date", today.toISOString());

    if (expErr) throw new Error("Expiring query failed: " + expErr.message)

    // ── 2. Find low-stock items ────────────────────────────────────────────
    const { data: lowStockItems, error: lowErr } = await supabase
      .from("items")
      .select("id, item_name, user_id, quantity")
      .lte("quantity", 2);

    if (lowErr) throw new Error("Low stock query failed: " + lowErr.message);

    // ── 3. Collect affected user IDs ───────────────────────────────────────
    const userMessages: Map<string, string[]> = new Map();

    for (const item of (expiringItems ?? [])) {
      const msgs = userMessages.get(item.user_id) ?? [];
      msgs.push(`🗓️ ${item.item_name} is expiring soon`);
      userMessages.set(item.user_id, msgs);
    }

    for (const item of (lowStockItems ?? [])) {
      const msgs = userMessages.get(item.user_id) ?? [];
      msgs.push(`📦 ${item.item_name} is running low (qty: ${item.quantity})`);
      userMessages.set(item.user_id, msgs);
    }

    if (userMessages.size === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: {...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("🗓️ Expiring items found:", expiringItems?.length ?? 0, expiringItems?.map(i => i.item_name));
    console.log("📦 Low stock items found:", lowStockItems?.length ?? 0, lowStockItems?.map(i => i.item_name));

    // ── 4. Look up device tokens ───────────────────────────────────────────
    const userIds = [...userMessages.keys()];
    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .in("user_id", userIds);

    // ── 5. Get a Firebase access token ────────────────────────────────────
    // NOTE: Getting an OAuth2 access token from a service account in Deno
    // requires signing a JWT with the service account's private key.
    // For simplicity this scaffold calls a helper — in production you would
    // use the google-auth-library or implement JWT signing via the Web Crypto API.
    let firebaseAccessToken = "";
    if (FIREBASE_SERVICE_ACCOUNT_JSON) {
      firebaseAccessToken = await getFirebaseAccessToken(FIREBASE_SERVICE_ACCOUNT_JSON);
    } else {
      console.error("❌ FIREBASE_SERVICE_ACCOUNT secret is missing!");
    }
    if (!firebaseAccessToken) {
      console.error("❌ Failed to get Firebase access token! Check FIREBASE_SERVICE_ACCOUNT secret.");
      return new Response(JSON.stringify({ 
        sent: 0, 
        alerts: userMessages.size,
        error: "Firebase access token is empty — check secrets"
      }), { headers: {...corsHeaders, "Content-Type": "application/json" } });
    }

    // ── 6. Dispatch FCM notifications ─────────────────────────────────────
    let sent = 0;
    for (const { user_id, token } of (tokens ?? [])) {
      const messages = userMessages.get(user_id);
      if (!messages || !firebaseAccessToken) continue;

      const body = messages.length === 1
        ? messages[0]
        : `You have ${messages.length} inventory alerts`;

      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${firebaseAccessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: "🛒 StockSense Alert",
                body,
              },
            },
          }),
        }
      );

      if (fcmRes.ok) {
        sent++;
      } else {
        const errBody = await fcmRes.text();
        console.error(`❌ FCM send failed [${fcmRes.status}]: ${errBody}`);
        
        // If the token is old/unregistered, delete it from the database
        if (errBody.includes("UNREGISTERED") || errBody.includes("INVALID_ARGUMENT")) {
          console.log(`🗑️ Deleting dead token for user ${user_id}`);
          await supabase.from("device_tokens").delete().eq("token", token);
        }
      }
    }

    return new Response(JSON.stringify({ sent, alerts: userMessages.size }), {
      headers: {...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: {...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Firebase OAuth2 helper
//
// Exchanges a service account JSON for a short-lived access token using
// the Web Crypto API (no external dependencies needed in Deno).
//
// TODO: Replace with a full JWT signing implementation for production.
//       See: https://developers.google.com/identity/protocols/oauth2/service-account
// ─────────────────────────────────────────────────────────────────────────────
async function getFirebaseAccessToken(serviceAccountJson: string): Promise<string> {
  try {
    const sa = JSON.parse(serviceAccountJson);
    const now = Math.floor(Date.now() / 1000);

    const header  = { alg: "RS256", typ: "JWT" };
    const payload = {
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    };

    const encode = (obj: object) =>
      btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");

    const signingInput = `${encode(header)}.${encode(payload)}`;

    // Import the RSA private key from the service account.
    const pemBody = sa.private_key
      .replace(/-----BEGIN PRIVATE KEY-----/, "")
      .replace(/-----END PRIVATE KEY-----/, "")
      .replace(/\s/g, "");
    const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      keyBytes,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      new TextEncoder().encode(signingInput)
    );

    const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "")}`;

    // Exchange the JWT for an access token.
    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenData = await tokenRes.json();
    return tokenData.access_token ?? "";
  } catch {
    return "";
  }
}
