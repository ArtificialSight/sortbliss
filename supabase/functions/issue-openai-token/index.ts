// Mock Supabase Edge Function for local development.
// Returns a short-lived, mock OpenAI session token. In production, validate the
// Supabase auth JWT, enforce RBAC, and mint a real ephemeral token or proxy.

export const issueOpenAiToken = async (req: Request): Promise<Response> => {
  // Basic auth check placeholder
  const auth = req.headers.get('authorization');
  if (!auth) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // In real implementation, call provider API or internal service to
  // generate an ephemeral token. Here we just mock it.
  const token = `mock-openai-token-${Date.now()}`;
  return new Response(
    JSON.stringify({ token, expiresIn: 300 }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
};

// Deno / Supabase edge function entrypoint
addEventListener('fetch', (event: FetchEvent) => {
  event.respondWith(issueOpenAiToken(event.request));
});
