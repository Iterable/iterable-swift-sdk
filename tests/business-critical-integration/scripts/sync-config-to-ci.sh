#!/bin/bash
#
# Sync test-config.json values into the repo's GitHub Actions secrets.
#
# Reads the local (gitignored) test-config.json and pushes each relevant
# value to the matching repo secret via `gh secret set`. Use this after
# rotating Iterable keys or migrating BCIT to a new project so CI stays
# in sync with local.
#
# Usage:
#   ./scripts/sync-config-to-ci.sh         # update all 5 BCIT secrets
#   ./scripts/sync-config-to-ci.sh --dry   # show what would change, don't write
#
# Mapping (config key → secret name):
#   projectId      → BCIT_TEST_PROJECT_ID
#   serverApiKey   → BCIT_ITERABLE_SERVER_KEY
#   mobileApiKey   → BCIT_ITERABLE_API_KEY
#   jwtApiKey      → BCIT_JWT_API_KEY
#   jwtSecret      → BCIT_JWT_SECRET
#
# Safety:
#   - Always scopes to the current repo (`gh repo view`), never org/global.
#   - Never echoes secret values; only the secret name + status is logged.
#   - test-config.json is gitignored, so values stay local until you run this.

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry" || "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../integration-test-app/config/test-config.json"

# --- preflight ----------------------------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ test-config.json not found at: $CONFIG_FILE" >&2
    echo "   Run scripts/setup-local-environment.sh first." >&2
    exit 1
fi

for cmd in gh jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ '$cmd' is required but not installed." >&2
        exit 1
    fi
done

if ! gh auth status &>/dev/null; then
    echo "❌ gh is not authenticated. Run: gh auth login" >&2
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# --- mapping ------------------------------------------------------------------

# Each entry: <config_key>:<secret_name>
MAPPINGS=(
    "projectId:BCIT_TEST_PROJECT_ID"
    "serverApiKey:BCIT_ITERABLE_SERVER_KEY"
    "mobileApiKey:BCIT_ITERABLE_API_KEY"
    "jwtApiKey:BCIT_JWT_API_KEY"
    "jwtSecret:BCIT_JWT_SECRET"
)

# --- run ----------------------------------------------------------------------

if $DRY_RUN; then
    echo "🔍 Dry run — showing what would be synced to repo: $REPO"
else
    echo "🔧 Syncing test-config.json → $REPO secrets"
fi
echo ""

for entry in "${MAPPINGS[@]}"; do
    config_key="${entry%%:*}"
    secret_name="${entry##*:}"

    value=$(jq -r --arg k "$config_key" '.[$k] // empty' "$CONFIG_FILE")

    if [[ -z "$value" ]]; then
        echo "⚠️  $config_key missing/empty in test-config.json — skipping $secret_name"
        continue
    fi

    if $DRY_RUN; then
        echo "  $secret_name ← .$config_key (length: ${#value})"
    else
        printf '%s' "$value" | gh secret set "$secret_name" --repo "$REPO"
        echo "  ✅ $secret_name updated"
    fi
done

echo ""
if $DRY_RUN; then
    echo "Dry run complete. Re-run without --dry to apply."
else
    echo "Done. Verify with: gh secret list --repo $REPO"
fi
