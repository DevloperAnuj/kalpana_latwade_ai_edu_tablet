import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('gm_api_key') ?? ''
const GEMINI_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { imageBase64, mimeType = 'image/png' } = await req.json()

    if (!imageBase64) {
      return new Response(
        JSON.stringify({ error: 'imageBase64 is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const geminiRes = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text:
                  'Extract all handwritten text from this image. ' +
                  'Return only the raw text, no explanations. ' +
                  'Preserve line breaks where clear.',
              },
              {
                inline_data: { mime_type: mimeType, data: imageBase64 },
              },
            ],
          },
        ],
        generationConfig: { maxOutputTokens: 2048, temperature: 0.1 },
      }),
      signal: AbortSignal.timeout(12_000),
    })

    if (!geminiRes.ok) {
      const body = await geminiRes.text()
      return new Response(
        JSON.stringify({ error: `Gemini API error ${geminiRes.status}: ${body}` }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const data = await geminiRes.json()
    const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''

    return new Response(
      JSON.stringify({ text: text.trim() }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
