// Supabase Edge Function: groq-proxy
// Forwards chat-completion requests to Groq so the API key never ships in the app.
// Signed-in users only; models and output size are restricted to what the app uses.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

const ALLOWED_MODELS = new Set(['llama-3.3-70b-versatile', 'llama-3.2-11b-vision-preview']);
const MAX_TOKENS = 2048;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (!(await getUserId(req))) return json({ error: 'Sign in required' }, 401);

    const body = await req.json();
    if (!ALLOWED_MODELS.has(body?.model)) return json({ error: 'Model not allowed' }, 400);
    if (!Array.isArray(body.messages)) return json({ error: 'messages is required' }, 400);

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${requireEnv('GROQ_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: body.model,
        messages: body.messages,
        temperature: body.temperature,
        response_format: body.response_format,
        max_tokens: Math.min(Number(body.max_tokens) || MAX_TOKENS, MAX_TOKENS),
      }),
    });

    return json(await response.json(), response.status);
  } catch (error) {
    return json({ error: (error as Error).message }, 500);
  }
});
