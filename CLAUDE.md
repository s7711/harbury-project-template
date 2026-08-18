# CLAUDE.md
Scope: projects/club-project-template/

The **club project template** — the starter members copy to host their own projects free
on Cloudflare. This is the source of truth that gets published to the club's GitHub
template repo; members create their own repo from it via "Use this template".

## What this is

A minimal full-stack starter:

- **Cloudflare Workers + Static Assets** — static front-end in `public/`, served via the
  `ASSETS` binding; serverless code in `src/index.js` handling `/api/*`.
- **Cloudflare D1** — SQLite database, bound as `DB`, schema in `migrations/`.
- **Three onboarding paths** — the "Deploy to Cloudflare" button (default: one click
  clones the repo, provisions D1 from `wrangler.toml`, sets up push-to-deploy), a manual
  dashboard path (fallback), and a `setup.sh` CLI path (advanced). See `README.md`.

## Why Workers (not Pages)

Cloudflare steers new projects to Workers + Static Assets; Pages is being consolidated into
Workers. Workers also gives per-account `*.workers.dev` URLs (no cross-member name clashes)
and lets us drop the API-token + GitHub-secrets + Actions plumbing the original Pages
proposal needed. The club's full decision record (ADR-0001) lives in the ABC hub repo.

## Key files

| File | Purpose |
|---|---|
| `wrangler.toml` | Project name, `[assets]` dir, D1 binding. `database_id` is blank in the template. |
| `src/index.js` | Worker entry: `/api/hello`, `/api/notes` (D1), else serve assets. |
| `public/` | Static front-end. |
| `migrations/0001_initial.sql` | Starter schema + idempotent seed row. |
| `setup.sh` | Advanced CLI path: login → create D1 → patch config → migrate → deploy → commit+push. No token/secrets. |
| `tests/` | Worker unit tests (`npm test`, Node's built-in runner, no deps). Gated in CI by `.github/workflows/template-ci.yml` at the hub-repo root. |
| `.devcontainer/` | Node + wrangler for Codespaces/VS Code so members install nothing. |

## Conventions

- **The published template repo must stay public** — the Deploy button requires a public
  source repo. Never commit secrets here (there are none by design).
- **Project names are prefixed `harbury-`** to avoid clashes and stay identifiable.
- **No secrets in the repo.** Neither deploy path uses API tokens or GitHub secrets;
  auth is the member's `wrangler login` session (CLI) or the dashboard Git connection.
- `setup.sh` must stay **idempotent** (safe to re-run) per the `club/dev/` automation
  rules — it reuses an existing D1 database, and it patches `wrangler.toml` in place
  (never regenerates it) so member-added config survives a re-run.
- **Cross-platform**: members are on Mac and Windows. Shell scripts stay LF
  (`.gitattributes`), npm scripts must not rely on `$VAR` shell expansion, and
  anything platform-specific goes through node.
- Keep `README.md` member-facing and beginner-first: Path A (dashboard) before Path B (CLI).

## Status

Pre-pilot. The end-to-end flow (D1 binding, migrations, Workers Builds auto-deploy, live
URL) must be validated on **one real member account** before club-wide rollout — see the
pilot tracking issue.
