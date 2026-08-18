// Unit tests for the Worker. Run with: npm test
// No dependencies needed — uses Node's built-in test runner and fetch types.

import test from "node:test";
import assert from "node:assert/strict";
import worker from "../src/index.js";

const req = (path) => new Request("https://example.com" + path);

test("/api/hello returns a JSON greeting", async () => {
  const res = await worker.fetch(req("/api/hello"), {});
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.ok(body.message.includes("Hello"));
});

test("/api/notes returns rows from the DB binding", async () => {
  const rows = [{ id: 1, body: "hi", created_at: "2026-01-01" }];
  const env = {
    DB: { prepare: () => ({ all: async () => ({ results: rows }) }) },
  };
  const res = await worker.fetch(req("/api/notes"), env);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), rows);
});

test("/api/notes explains a missing DB binding instead of crashing", async () => {
  const res = await worker.fetch(req("/api/notes"), {});
  assert.equal(res.status, 500);
  const body = await res.json();
  assert.ok(body.error.includes("wrangler.toml"));
});

test("/api/notes explains a failed query (e.g. schema not loaded)", async () => {
  const env = {
    DB: {
      prepare: () => ({
        all: async () => {
          throw new Error("no such table: notes");
        },
      }),
    },
  };
  const res = await worker.fetch(req("/api/notes"), env);
  assert.equal(res.status, 500);
  const body = await res.json();
  assert.ok(body.error.includes("no such table"));
});

test("other paths fall through to static assets", async () => {
  const env = { ASSETS: { fetch: async () => new Response("static!") } };
  const res = await worker.fetch(req("/anything.html"), env);
  assert.equal(await res.text(), "static!");
});
