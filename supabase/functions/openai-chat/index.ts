// Supabase Edge Function: openai-chat
// Secure proxy that forwards chat completion requests to OpenAI without
// exposing the raw API key to the client.

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
const OPENAI_BASE_URL = Deno.env.get('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1';

if (!OPENAI_API_KEY) {
  console.error('[openai-chat] Missing OPENAI_API_KEY environment variable');
}

addEventListener('fetch', (event: FetchEvent) => {
  event.respondWith(handle(event.request));
});

async function handle(req: Request): Promise<Response> {
  const auth = req.headers.get('authorization');
  if (!auth) {
    return json({ error: 'Unauthorized' }, 401);
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const model = body.model ?? 'gpt-4o-mini';
  const messages = Array.isArray(body.messages) ? body.messages : [];
  const temperature = typeof body.temperature === 'number' ? body.temperature : 0.7;

  if (!OPENAI_API_KEY) {
    return json({ error: 'Server not configured' }, 500);
  }

  const upstream = await fetch(`${OPENAI_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, messages, temperature }),
  });

  if (!upstream.ok) {
    const txt = await upstream.text();
    return json({
      error: 'Upstream OpenAI error',
      status: upstream.status,
      body: txt,
    }, 502);
  }

  const data = await upstream.json();
  return json({ data });
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
