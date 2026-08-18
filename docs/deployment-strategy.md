# Member Project Hosting — Deployment Strategy (corrected)

This supersedes the original "Cloudflare Pages Deployment Strategy" handoff. It keeps that
document's goal — let ~15 members host projects free, with a database and push-to-deploy —
but corrects the platform choice and removes the error-prone plumbing. The decision is
recorded as ADR-0001 in the club's ABC hub repo.

## Goal

Each member hosts their own project with: auto-deploy on push, a database for full-stack
work, zero ongoing cost, and the lowest possible setup burden across a wide IT-literacy
range.

## What changed from the original proposal, and why

| Original proposal | Corrected approach | Reason |
|---|---|---|
| Cloudflare **Pages** + D1 | Cloudflare **Workers + Static Assets** + D1 | Cloudflare steers new projects to Workers; Pages is being consolidated into Workers; `pages-action` is deprecated. |
| Deploy via GitHub **Actions** running `wrangler pages deploy` | **Dashboard Git integration (Workers Builds)** by default | Removes the workflow, the API token, and the GitHub secrets entirely. |
| Member creates a **Cloudflare API token** ("Edit Cloudflare Workers" template) and stores it as a GitHub secret | **No API token at all** | The named template lacks `Cloudflare Pages: Edit`, so the original's first deploy would have failed. Workers Builds / `wrangler login` need no token. |
| `*.pages.dev` URL built as `<project>.pages.dev` | `*.workers.dev` URL, namespaced per account | pages.dev subdomains are effectively global and collide for generic names; workers.dev URLs sit under each account's own subdomain. |
| `check_tool` exits if Node/gh/wrangler missing (claimed to "install") | `.devcontainer` ships Node + wrangler; dashboard path needs no local tools | The local-tooling bar was the biggest practical barrier for beginners. |
| `setup.sh` parses `wrangler whoami --json` and `database_id = "..."` | `setup.sh` parses a raw **UUID** and looks the DB up if it already exists | Stable across wrangler versions; idempotent per club automation rules. |
| `setup.sh` regenerates `wrangler.toml` wholesale | `setup.sh` patches only the three settings it owns, via node | Member-added config (KV, crons, vars) survives a re-run; node-based edit behaves identically on Mac/Windows/Linux. |

## Three paths

- **Path A — "Deploy to Cloudflare" button (default).** One click from the README:
  Cloudflare clones the template into the member's GitHub account, auto-provisions the D1
  database from `wrangler.toml` (writing the id back), deploys, and wires up Workers
  Builds. The only remaining member step is loading the schema (one console paste,
  idempotent). Requires the template repo to be **public**.
- **Path B — Dashboard, manual (fallback).** Create a D1 database, paste its id into
  `wrangler.toml`, connect the repo under Workers & Pages → Import a repository. Every
  push auto-deploys. No command line, no token, no secrets.
- **Path C — CLI (advanced).** `./setup.sh` logs in, creates the D1 database, patches the
  config in place, applies migrations, deploys, and commits + pushes the config (so a later
  Workers Builds connection deploys the same settings). Authorised by the member's
  `wrangler login` session. The included devcontainer means even this path needs nothing
  installed locally; on Windows it runs under Git Bash.

Full member instructions are in `../README.md`.

## Account model

- **GitHub:** a club **organisation** holds the template repo (**public**, required by the
  Deploy button). The button clones it into the member's own account automatically; for
  Paths B/C members use "Use this template" (not a fork — forks have Actions disabled by
  default and inherit upstream history we don't want). Each member's repo lives in their
  own account.
- **Cloudflare:** **one account per member.** This is required, not just tidy — D1's free
  tier allows a maximum of **10 databases per account**, so no single shared club account
  could give 15 members a database each. Per-member accounts also avoid credential sharing
  and keep each member inside the free tier.

## Free-tier limits

The Cloudflare numbers (Workers requests/day, D1 storage and daily row limits) are
maintained in one place — the member-facing **`../README.md`**, "Free tier — what to
know" — so they can't drift between documents. Club-lead-only additions:

**GitHub (free):**
- 2,000 Actions minutes/month **per account**. The default (Workers Builds) path uses
  **none** — builds run on Cloudflare. Only relevant if a member opts into an Actions-based
  deploy.

## Progression path

| Stage | Stack | Cost |
|---|---|---|
| Beginner | Static HTML/CSS/JS (GitHub Pages or Workers assets) | Free |
| Intermediate | Front-end + Worker functions | Free |
| Advanced | Full-stack with D1 | Free |
| Beyond free tier | Workers Paid plan | $5/month |

## Open items before rollout

1. **One-member pilot** — validate the Deploy button end-to-end (repo clone, D1
   auto-provisioning writes the id back, Workers Builds auto-deploy, live URL), plus the
   fallback dashboard path and `setup.sh`, on a real free account. Tracked as a GitHub
   issue.
2. Confirm the installed **wrangler v4** command syntax for `d1 create` / `d1 migrations
   apply` / `deploy` against the member's environment (the `setup.sh` UUID parsing is
   version-tolerant, but worth a sanity check during the pilot).
3. Publish this folder to the club GitHub **template repo** — **public**, and mark it as a
   template (public is required by the Deploy button; "template" enables Use-this-template
   for Paths B/C).
