import "jsr:@supabase/functions-js/edge-runtime.d.ts";

async function callGPT4oVision(imageBase64: string) {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY secret is not set. Add it to supabase/functions/.env for local dev.");

  const body = {
    model: "gpt-4o",
    response_format: { type: "json_object" },
    messages: [{
      role: "user",
      content: [
        {
          type: "text",
          text: `You are a grocery receipt parser. Extract every food/grocery item from this receipt image.
Return ONLY a JSON object in this exact format:
{
  "items": [
    { "name": "string", "quantity": number, "unit": "string", "category": "string" }
  ]
}
Categories must be one of: produce, dairy, meat, bakery, frozen, pantry, beverage, snack, other.
If quantity or unit cannot be determined, use 1 and "each".`,
        },
        {
          type: "image_url",
          image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
        },
      ],
    }],
    max_tokens: 1500,
  };

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  const data = await res.json();

  // Surface API-level errors (e.g. invalid key, quota exceeded)
  if (!res.ok || !data.choices) {
    const msg = data.error?.message ?? JSON.stringify(data);
    throw new Error(`OpenAI API error (${res.status}): ${msg}`);
  }

  const parsed = JSON.parse(data.choices[0].message.content);
  return { mode: "receipt", items: parsed.items };
}


async function callGoogleVision(imageBase64: string) {
  const apiKey = Deno.env.get("GOOGLE_VISION_API_KEY");
  if (!apiKey) throw new Error("GOOGLE_VISION_API_KEY secret is not set. Add it to supabase/functions/.env for local dev.");

  const url = `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`;

  const body = {
    requests: [{
      image: { content: imageBase64 },
      features: [
        { type: "LABEL_DETECTION", maxResults: 20 },
        { type: "OBJECT_LOCALIZATION", maxResults: 20 },
      ],
    }],
  };

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const data = await res.json();

  // Surface API-level errors (e.g. invalid key, quota exceeded)
  if (!res.ok || !data.responses) {
    const msg = data.error?.message ?? JSON.stringify(data);
    throw new Error(`Google Vision API error (${res.status}): ${msg}`);
  }

  // Normalize into a flat list of detected item names
  const labels = data.responses[0].labelAnnotations?.map((l: any) => l.description) ?? [];
  const objects = data.responses[0].localizedObjectAnnotations?.map((o: any) => o.name) ?? [];
  const items = [...new Set([...labels, ...objects])]; // deduplicate

  return { mode: "fridge", items };
}

Deno.serve(async (req: Request) => {
  try {
    const { imageBase64, mode } = await req.json();

    let result;
    if (mode === "receipt") {
      result = await callGPT4oVision(imageBase64);
    } else {
      result = await callGoogleVision(imageBase64);
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
