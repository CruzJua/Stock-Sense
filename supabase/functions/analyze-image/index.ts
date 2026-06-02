import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const VALID_CATEGORIES = new Set([
  "produce", "dairy", "meat", "bakery", "frozen", "pantry", "beverage", "snack", "other",
]);

// Shared helper: calls GPT-4o Vision and normalises the returned items.
async function callGPT4oVision(imageBase64: string, prompt: string, mode: string) {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY secret is not set. Add it to supabase/functions/.env for local dev.");

  const body = {
    model: "gpt-4o",
    response_format: { type: "json_object" },
    messages: [{
      role: "user",
      content: [
        { type: "text", text: prompt },
        { type: "image_url", image_url: { url: `data:image/jpeg;base64,${imageBase64}` } },
      ],
    }],
    max_tokens: 1500,
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 120_000);

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
    signal: controller.signal,
  });
  clearTimeout(timeout);

  const data = await res.json();

  if (!res.ok || !data.choices) {
    const msg = data.error?.message ?? JSON.stringify(data);
    throw new Error(`OpenAI API error (${res.status}): ${msg}`);
  }

  const parsed = JSON.parse(data.choices[0].message.content);

  // Safeguard: ensure every item has a valid category; fall back to "other"
  const items = (parsed.items ?? []).map((item: any) => ({
    name: item.name ?? "Unknown item",
    quantity: typeof item.quantity === "number" ? item.quantity : 1,
    unit: item.unit ?? "each",
    category: VALID_CATEGORIES.has(item.category) ? item.category : "other",
  }));

  return { mode, items };
}

// ── Receipt mode ─────────────────────────────────────────────────────────────

const RECEIPT_PROMPT = `You are a grocery receipt parser. Extract every food/grocery item from this receipt image.
Return ONLY a JSON object in this exact format:
{
  "items": [
    { "name": "string", "quantity": number, "unit": "string", "category": "string" }
  ]
}
Categories must be one of: produce, dairy, meat, bakery, frozen, pantry, beverage, snack, other.
If quantity or unit cannot be determined, use 1 and "each".`;

// ── Fridge / Pantry mode ─────────────────────────────────────────────────────
// GPT-4o is used here instead of Google Vision because Vision returns generic
// labels like "Shelf" or "Ingredient" with no way to guide it. GPT-4o can
// identify specific food items and assign categories from a single image.

const FRIDGE_PANTRY_PROMPT = `You are a smart kitchen inventory scanner. Look at this photo of a fridge or pantry shelf and identify every distinct food or beverage item you can see.

Return ONLY a JSON object in this exact format:
{
  "items": [
    { "name": "string", "quantity": number, "unit": "string", "category": "string" }
  ]
}

Rules:
- Use specific product names (e.g. "Whole Milk", "Cheddar Cheese", "Greek Yogurt") — never generic labels like "Food", "Ingredient", or "Shelf".
- Estimate quantity from visible containers/packages. If unclear, use 1.
- Use natural units: "bottle", "carton", "can", "bag", "box", "bunch", "each", etc.
- Categories must be one of: produce, dairy, meat, bakery, frozen, pantry, beverage, snack, other.
- Skip non-food items (shelves, containers, condiment packets that aren't identifiable).
- If the image is too blurry or unclear to identify any items, return { "items": [] }.`;

// ── Request handler ───────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
  
  try {
    const { imageBase64, mode } = await req.json();

    let result;
    if (mode === "receipt") {
      result = await callGPT4oVision(imageBase64, RECEIPT_PROMPT, "receipt");
    } else {
      // Both "fridge" and "pantry" use the same GPT-4o vision prompt
      result = await callGPT4oVision(imageBase64, FRIDGE_PANTRY_PROMPT, mode);
    }

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

