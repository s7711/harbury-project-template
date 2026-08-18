#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Harbury Builders Club — Project Setup (advanced CLI path)
#
# This is the OPTIONAL command-line path. Most members should use the dashboard
# path in the README instead (no tools to install, no token, no script).
# Windows members: run this in Git Bash (installed with Git for Windows) or in
# the devcontainer / GitHub Codespaces. Mac and Linux: any terminal.
#
# This script, run from the project root, will:
#   1. Ask for your project name
#   2. Check Node/npm, and install wrangler locally if it's missing
#   3. Log you in to Cloudflare (browser, one click)
#   4. Create (or reuse) a D1 database for your project
#   5. Write your project name + database id into wrangler.toml
#   6. Apply your database migrations
#   7. Deploy your Worker and print its live URL
#   8. Commit and push the updated config, so push-to-deploy uses it too
#
# It needs NO Cloudflare API token and NO GitHub secrets — your `wrangler login`
# session authorises everything. It is safe to re-run: it reuses your existing
# database and only updates the three settings it owns in wrangler.toml, so
# anything else you've added there (KV, crons, vars) is preserved.
# ─────────────────────────────────────────────────────────────────────────────

echo "🚢 Harbury Builders Club — Project Setup"
echo "─────────────────────────────────────────"

# ── 1. Project name ──────────────────────────────────────────────────────────
read -r -p "Enter your project name (lowercase, hyphens, e.g. alice-todo): " RAW
RAW="${RAW#harbury-}"                       # strip a harbury- prefix if they typed one
PROJECT="harbury-${RAW}"

if [[ ! "$PROJECT" =~ ^harbury-[a-z][a-z0-9-]*$ ]]; then
  echo "❌ Invalid name. It must start with a letter and use only lowercase"
  echo "   letters, numbers and hyphens (e.g. alice-todo)."
  exit 1
fi
DB_NAME="${PROJECT}-db"
echo "  Project:  $PROJECT"
echo "  Database: $DB_NAME"

# ── 2. Required tools ────────────────────────────────────────────────────────
echo ""
echo "Checking required tools..."
for tool in node npm; do
  if ! command -v "$tool" &>/dev/null; then
    echo "❌ $tool is not installed. Install Node.js from https://nodejs.org"
    exit 1
  fi
  echo "  ✅ $tool found"
done

if [[ ! -e node_modules/.bin/wrangler ]]; then
  echo "  ℹ️  wrangler not installed yet — running npm install (one-off)..."
  npm install
fi
echo "  ✅ wrangler found"
WRANGLER="npx wrangler"

# ── 3. Cloudflare login ──────────────────────────────────────────────────────
echo ""
echo "Checking Cloudflare login..."
if ! $WRANGLER whoami &>/dev/null; then
  echo "Opening your browser to log in to Cloudflare..."
  $WRANGLER login
else
  echo "  ✅ Already logged in"
fi

# ── 4. Create (or reuse) the D1 database ─────────────────────────────────────
echo ""
echo "Creating D1 database: $DB_NAME ..."
UUID_RE='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

# Try to create; if it already exists, fall back to looking it up. Parsing a raw
# UUID is stable across wrangler versions (the surrounding text changes, the id
# format does not).
CREATE_OUT="$($WRANGLER d1 create "$DB_NAME" 2>&1 || true)"
DB_ID="$(printf '%s' "$CREATE_OUT" | grep -oE "$UUID_RE" | head -1 || true)"

if [[ -z "$DB_ID" ]]; then
  echo "  ℹ️  Database may already exist — looking it up..."
  DB_ID="$($WRANGLER d1 info "$DB_NAME" 2>&1 | grep -oE "$UUID_RE" | head -1 || true)"
fi

if [[ -z "$DB_ID" ]]; then
  echo "❌ Could not determine the database id. Output was:"
  echo "$CREATE_OUT"
  exit 1
fi
echo "  ✅ Database id: $DB_ID"

# ── 5. Update wrangler.toml ──────────────────────────────────────────────────
# Patch the three settings in place (via node, so it works the same on Mac,
# Windows/Git Bash and Linux) instead of regenerating the file — any other
# config you've added to wrangler.toml is left untouched.
echo ""
echo "Updating wrangler.toml ..."
node -e '
const fs = require("fs");
const [, project, dbName, dbId] = process.argv;
let toml = fs.readFileSync("wrangler.toml", "utf8");
const patch = (re, line) => {
  if (!re.test(toml)) {
    console.error("❌ Could not find `" + line.split(" ")[0] + "` in wrangler.toml");
    process.exit(1);
  }
  toml = toml.replace(re, line);
};
patch(/^name\s*=.*$/m, `name = "${project}"`);
patch(/^database_name\s*=.*$/m, `database_name = "${dbName}"`);
patch(/^database_id\s*=.*$/m, `database_id = "${dbId}"`);
fs.writeFileSync("wrangler.toml", toml);
' "$PROJECT" "$DB_NAME" "$DB_ID"
echo "  ✅ wrangler.toml updated"

# ── 6. Apply migrations ──────────────────────────────────────────────────────
echo ""
echo "Applying database migrations..."
$WRANGLER d1 migrations apply "$DB_NAME" --remote
echo "  ✅ Migrations applied"

# ── 7. Deploy ────────────────────────────────────────────────────────────────
echo ""
echo "Deploying your Worker..."
DEPLOY_OUT="$($WRANGLER deploy 2>&1)"
echo "$DEPLOY_OUT"
LIVE_URL="$(printf '%s' "$DEPLOY_OUT" | grep -oE 'https://[a-z0-9.-]+\.workers\.dev' | head -1 || true)"

# ── 8. Commit and push the config ────────────────────────────────────────────
# Push-to-deploy (Workers Builds) builds from what is COMMITTED, so the filled-in
# database_id must land on GitHub — otherwise the auto-deployed site has no
# database. Failures here are warnings, not fatal: the deploy above already went
# out, you just need to commit/push yourself.
echo ""
if git rev-parse --is-inside-work-tree &>/dev/null; then
  if git diff --quiet -- wrangler.toml; then
    echo "  ✅ wrangler.toml already committed — nothing to push"
  else
    echo "Committing and pushing your config..."
    git add wrangler.toml
    if git commit -m "chore: configure $PROJECT (Cloudflare Worker + D1)"; then
      if git push; then
        echo "  ✅ Config pushed to GitHub"
      else
        echo "  ⚠️  Could not push. Run 'git push' yourself — until then,"
        echo "     push-to-deploy will build with an empty database_id."
      fi
    else
      echo "  ⚠️  Could not commit (is your git name/email set?)."
      echo "     Run: git add wrangler.toml && git commit -m 'configure project' && git push"
    fi
  fi
else
  echo "  ⚠️  Not a git repo — commit and push wrangler.toml from your clone."
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
echo "🎉 Setup complete!"
echo "  Project:  $PROJECT"
echo "  Database: $DB_NAME ($DB_ID)"
if [[ -n "$LIVE_URL" ]]; then
  echo "  Live URL: $LIVE_URL"
else
  echo "  Live URL: see the 'Deployed ... workers.dev' line above"
fi
echo ""
echo "To get push-to-deploy: Cloudflare dashboard → Workers & Pages →"
echo "your Worker → Settings → Builds → connect this GitHub repo."
echo "(Don't use 'Import a repository' — that would create a second Worker.)"
echo "─────────────────────────────────────────"
