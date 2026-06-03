import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// ---------------------------------------------------------------------------
// generate-embedding
//
// Accepts: { itemName: string }
// Returns: { embedding: number[] }   (1536-dimensional float array)
// ---------------------------------------------------------------------------
const corsHeaders = {
    'Access-Control-Allow-Origin': 'https://stocksense.juancruzdev.com',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders,
    });
  }

  try {
    const { itemName } = await req.json();
    if (!itemName || typeof itemName !== "string") {
      throw new Error("itemName is required and must be a string");
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) throw new Error("Missing OPENAI_API_KEY");

    const res = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: itemName,
      }),
    });

    const data = await res.json();

    if (!data.data?.[0]?.embedding) {
      throw new Error(`OpenAI embeddings error: ${JSON.stringify(data)}`);
    }

    const embedding: number[] = data.data[0].embedding;

    return new Response(JSON.stringify({ embedding }), {
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
