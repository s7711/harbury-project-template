# Harbury Builders Club — Project Template

A starter for hosting your project **free** on Cloudflare, with:

- a static front-end (HTML/CSS/JS),
- a serverless backend (Cloudflare **Worker**),
- a real database (Cloudflare **D1**), and
- **automatic deploy on every push**.

You do not need a credit card, and nothing here costs money for normal club use.

There are three ways to set up. **Most members should use Path A (one click).**

---

## Path A — One-click deploy (recommended)

~5 minutes. You need two free accounts and one button.

1. Create a free **GitHub** account at <https://github.com> (if you don't have one).
2. Create a free **Cloudflare** account at <https://cloudflare.com> (no card needed).
3. Click the button and follow the prompts (sign in to Cloudflare, connect GitHub):

   [![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/harbury-abc-org/project-template)

   Cloudflare will automatically:
   - copy this template into a **new repo in your GitHub account**,
   - **create your D1 database** and fill in its id for you,
   - deploy your Worker and set up **push-to-deploy** — from now on, every
     `git push` redeploys your site.

4. **Load your database schema**: dashboard → **Storage & Databases → D1 →
   your database → Console** → paste the contents of
   `migrations/0001_initial.sql` and run it (safe to run more than once).
5. **You're live** — open the `*.workers.dev` URL shown on your Worker's page
   and click the two buttons to confirm the API and the database both work.

> Your Worker deploys under this template's name. If you'd like your own name,
> edit `name` in `wrangler.toml` (keep the `harbury-` prefix) as your first
> change — ask a club leader if unsure, as renaming creates a fresh Worker.

---

## Path B — Dashboard, step by step (fallback)

Use this if the one-click button doesn't work for you. You'll need the same two
free accounts as Path A, plus your own copy of this repo: open the template on
GitHub and click **"Use this template" → "Create a new repository"** (not
"Fork").

### 1. Create your database

1. In the Cloudflare dashboard, go to **Storage & Databases → D1 → Create**.
2. Name it `harbury-<yourname>-db` (e.g. `harbury-alice-db`) and create it.
3. Copy the **Database ID** shown on the database page.

### 2. Point your repo at the database

In your new GitHub repo, edit **`wrangler.toml`** (use GitHub's pencil/edit button):

- change `name` to `harbury-<yourname>` (e.g. `harbury-alice`),
- change `database_name` to your `harbury-<yourname>-db`,
- paste your Database ID into `database_id = "..."`.

Commit the change.

### 3. Connect the repo to Cloudflare (push-to-deploy)

1. Dashboard → **Workers & Pages → Create → Workers → Import a repository**.
2. Authorise GitHub and pick your repo.
3. Cloudflare detects `wrangler.toml` and sets up **Workers Builds**. Click **Deploy**.

From now on, **every push to `main` redeploys automatically.** No API token, no secrets.

### 4. Load your database schema

Same as Path A step 4: **D1 → your database → Console** → paste
`migrations/0001_initial.sql` → run.

### 5. You're live

Open your `*.workers.dev` URL and click the two buttons to confirm the API and
the database both work.

---

## Path C — Command line (advanced)

For members comfortable with a terminal, or using the included devcontainer
(GitHub Codespaces / VS Code), which already has Node + wrangler installed.
First create your repo copy with **"Use this template"** (see Path B intro) and
clone it.

Works on **Mac and Windows**: on Windows, run these commands in **Git Bash**
(installed with Git for Windows) or use Codespaces — not plain Command Prompt.

```bash
npm install
./setup.sh
```

The script logs you in to Cloudflare, creates your D1 database, updates
`wrangler.toml`, applies your migrations, does the first deploy, and commits and
pushes the config — then prints your live URL. It needs **no API token and no
GitHub secrets**, and it's safe to re-run.

To also get push-to-deploy: dashboard → **Workers & Pages → your Worker →
Settings → Builds → connect this GitHub repo**. (Don't use Path B step 3's
"Import a repository" — the script already created your Worker, and importing
would create a second one.)

Handy commands afterwards:

```bash
npm run dev            # run locally at http://localhost:8787
npm run deploy         # deploy manually
npm run db:migrate     # apply new migrations to your live database
npm test               # run the Worker unit tests
```

---

## What's in here

| Path | What it is |
|---|---|
| `public/` | Your static front-end (served automatically) |
| `src/index.js` | Your Worker — handles `/api/*`, serves everything else from `public/` |
| `migrations/` | Database schema, applied to D1 |
| `wrangler.toml` | Project + database config |
| `setup.sh` | Optional one-shot CLI setup (Path C) |
| `tests/` | Worker unit tests — run with `npm test` |
| `.devcontainer/` | Preinstalled Node + wrangler for Codespaces / VS Code |

---

## Free tier — what to know

- **Workers**: 100,000 requests/day free. Your URL is `*.workers.dev` (namespaced to your
  account, so it won't clash with other members).
- **D1** (per account): 5 GB total, 500 MB per database, **up to 10 databases**,
  **5M rows read/day**, **100k rows written/day**. Limits reset at **00:00 UTC each day**
  (daily, not monthly) — heavy testing can hit the daily write cap, which frees up the next
  day.

None of these will be a problem for normal club projects.
