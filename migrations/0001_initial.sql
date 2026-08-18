-- Initial schema for your D1 database.
-- Apply with:  npm run db:migrate   (or paste into the D1 console — safe to
-- run more than once: the seed row is only inserted if the table is empty).

CREATE TABLE IF NOT EXISTS notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  body       TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO notes (body)
SELECT 'Welcome to your first D1 database!'
WHERE NOT EXISTS (SELECT 1 FROM notes);
