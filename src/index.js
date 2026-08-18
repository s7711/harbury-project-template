// Worker entry point.
//
// Anything under /api/* is handled here. Everything else is served as a static
// file from ./public via the ASSETS binding.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/api/hello") {
      return Response.json({
        message: "Hello from your Worker!",
        time: new Date().toISOString(),
      });
    }

    if (url.pathname === "/api/notes") {
      if (!env.DB) {
        return Response.json(
          { error: "No database is bound. Fill in database_id in wrangler.toml and redeploy — see the README." },
          { status: 500 }
        );
      }
      try {
        const { results } = await env.DB.prepare(
          "SELECT id, body, created_at FROM notes ORDER BY id DESC LIMIT 50"
        ).all();
        return Response.json(results);
      } catch (err) {
        return Response.json(
          { error: "Database query failed: " + err.message + ". Have you loaded the schema? See 'Load your database schema' in the README." },
          { status: 500 }
        );
      }
    }

    // Not an API route — serve the static front-end.
    return env.ASSETS.fetch(request);
  },
};
