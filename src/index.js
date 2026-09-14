// Worker do PsiControl: serve os arquivos estáticos do site normalmente
// e cuida da rota /api/ia (proxy seguro para a API da Anthropic — a
// chave fica guardada como variável de ambiente secreta no Cloudflare,
// nunca aparece no navegador).
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/ia' && request.method === 'POST') {
      let body;
      try {
        body = await request.json();
      } catch (e) {
        return new Response(JSON.stringify({ error: 'JSON inválido' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const prompt = body?.prompt;
      if (!prompt || typeof prompt !== 'string') {
        return new Response(JSON.stringify({ error: 'Campo "prompt" é obrigatório' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      if (!env.ANTHROPIC_API_KEY) {
        return new Response(JSON.stringify({ error: 'ANTHROPIC_API_KEY não configurada no Cloudflare' }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-6',
          max_tokens: body.max_tokens || 1000,
          messages: [{ role: 'user', content: prompt }],
        }),
      });

      const data = await resp.text();
      return new Response(data, {
        status: resp.status,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Tudo que não for /api/* continua sendo servido como arquivo estático normal
    return env.ASSETS.fetch(request);
  },
};
