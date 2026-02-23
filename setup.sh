#!/bin/bash
# ============================================================
# OpenClaw Claims Processing — Setup Script
# ============================================================
# Target: Ubuntu/Debian (clean machine)
# Auth:   Anthropic via Claude setup-token (not API key)
# DB:     System PostgreSQL (not Docker)
# Channel: Telegram
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh --telegram-token "BOT_TOKEN" --telegram-user "USER_ID"
#
# Or run interactively (will prompt for values):
#   ./setup.sh
# ============================================================

set -euo pipefail

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

# --- Parse arguments ---
TELEGRAM_TOKEN=""
TELEGRAM_USER_ID=""
SETUP_TOKEN=""
SKIP_DEPS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --telegram-token)  TELEGRAM_TOKEN="$2"; shift 2 ;;
    --telegram-user)   TELEGRAM_USER_ID="$2"; shift 2 ;;
    --setup-token)     SETUP_TOKEN="$2"; shift 2 ;;
    --skip-deps)       SKIP_DEPS=true; shift ;;
    -h|--help)
      echo "Usage: ./setup.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --telegram-token TOKEN   Telegram bot token from @BotFather"
      echo "  --telegram-user ID       Your Telegram numeric user ID"
      echo "  --setup-token TOKEN      Anthropic setup-token (from 'claude setup-token')"
      echo "  --skip-deps              Skip system dependency installation"
      echo "  -h, --help               Show this help"
      exit 0
      ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Prompt for missing values ---
if [ -z "$TELEGRAM_TOKEN" ]; then
  echo ""
  read -rp "$(echo -e "${CYAN}Telegram bot token (from @BotFather):${NC} ")" TELEGRAM_TOKEN
  if [ -z "$TELEGRAM_TOKEN" ]; then
    err "Telegram bot token is required."
    exit 1
  fi
fi

if [ -z "$TELEGRAM_USER_ID" ]; then
  echo ""
  read -rp "$(echo -e "${CYAN}Your Telegram user ID (numeric, get via @userinfobot):${NC} ")" TELEGRAM_USER_ID
  if [ -z "$TELEGRAM_USER_ID" ]; then
    err "Telegram user ID is required."
    exit 1
  fi
fi

# --- Determine script directory (where this repo was cloned) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Starting OpenClaw Claims setup..."
info "Config source: $SCRIPT_DIR"
echo ""

# ============================================================
# Step 1: System Dependencies
# ============================================================
if [ "$SKIP_DEPS" = false ]; then
  log "Step 1/8: Installing system dependencies..."

  sudo apt-get update -qq

  # --- Node.js 22 ---
  if command -v node &>/dev/null && [[ "$(node -v | cut -d. -f1 | tr -d 'v')" -ge 22 ]]; then
    info "Node.js $(node -v) already installed, skipping."
  else
    log "Installing Node.js 22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
    log "Node.js $(node -v) installed."
  fi

  # --- PostgreSQL ---
  if command -v psql &>/dev/null; then
    info "PostgreSQL already installed, skipping."
  else
    log "Installing PostgreSQL..."
    sudo apt-get install -y -qq postgresql postgresql-contrib
    log "PostgreSQL installed."
  fi

  # --- Ensure Postgres is running ---
  sudo systemctl enable postgresql
  sudo systemctl start postgresql

  # --- Other utilities ---
  sudo apt-get install -y -qq jq curl
else
  warn "Skipping dependency installation (--skip-deps)."
fi

echo ""

# ============================================================
# Step 2: Install OpenClaw
# ============================================================
log "Step 2/8: Installing OpenClaw..."

if command -v openclaw &>/dev/null; then
  info "OpenClaw already installed: $(openclaw --version 2>/dev/null || echo 'unknown version')"
  info "Upgrading to latest..."
fi

sudo npm install -g openclaw@latest
log "OpenClaw installed: $(openclaw --version 2>/dev/null || echo 'done')"
echo ""

# ============================================================
# Step 3: PostgreSQL Database Setup
# ============================================================
log "Step 3/8: Setting up PostgreSQL database..."

DB_NAME="openclaw_claims"
DB_USER="openclaw"
DB_PASS="${DB_PASS:-openclaw_hackathon}"

# Create user and database (idempotent)
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER'" | grep -q 1 \
  || sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 \
  || sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

# Grant permissions
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Configure pg_hba.conf for password auth (if not already set)
PG_HBA=$(sudo -u postgres psql -t -A -c "SHOW hba_file;")
if ! sudo grep -q "openclaw" "$PG_HBA" 2>/dev/null; then
  # Add password auth line for our user before the first existing rule
  sudo sed -i "1s|^|local   $DB_NAME   $DB_USER   md5\n|" "$PG_HBA" 2>/dev/null || true
  sudo systemctl reload postgresql
fi

# Run the schema
log "Applying database schema..."
PGPASSWORD="$DB_PASS" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/shared/scripts/db-setup.sql"

# Grant table permissions (needed after schema creation)
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"

log "Database '$DB_NAME' ready (user: $DB_USER)."
echo ""

# ============================================================
# Step 4: Initialize OpenClaw + Copy Our Workspaces
# ============================================================
log "Step 4/8: Initializing OpenClaw and setting up workspaces..."

OPENCLAW_DIR="$HOME/.openclaw"

# --- Run OpenClaw's own initialization first ---
# This creates ~/.openclaw/, the default workspace/, and base config.
# We do NOT skip this — it sets up internal state OpenClaw expects.
if [ ! -d "$OPENCLAW_DIR/workspace" ]; then
  log "  Running OpenClaw initial setup..."
  openclaw setup 2>/dev/null || true
  info "  Default workspace created at $OPENCLAW_DIR/workspace/ (untouched)"
else
  info "  OpenClaw already initialized, default workspace/ exists (untouched)"
fi

# --- Back up existing openclaw.json if present ---
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
  cp "$OPENCLAW_DIR/openclaw.json" "$OPENCLAW_DIR/openclaw.json.bak"
  info "  Backed up existing config to openclaw.json.bak"
fi

# --- Copy OUR workspace directories (alongside the default, not replacing it) ---
# Repo uses workspaces/X/ but OpenClaw expects workspace-X/ in ~/.openclaw/
AGENTS=("router" "claims-officer" "assessor" "fraud-analyst" "senior-reviewer" "finance")

for agent in "${AGENTS[@]}"; do
  SRC="$SCRIPT_DIR/workspaces/$agent"
  DST="$OPENCLAW_DIR/workspace-$agent"
  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DST"
    log "  Copied workspaces/$agent → workspace-$agent"
  else
    warn "  Missing workspace: workspaces/$agent"
  fi
done

info "  Default workspace/ is preserved — our agents use separate folders"

# --- Copy shared directory ---
sudo mkdir -p /shared/uploads
sudo mkdir -p /shared/policies
sudo mkdir -p /shared/scripts

if [ -d "$SCRIPT_DIR/shared/scripts" ]; then
  sudo cp "$SCRIPT_DIR/shared/scripts/db.sh" /shared/scripts/db.sh
  sudo cp "$SCRIPT_DIR/shared/scripts/db-setup.sql" /shared/scripts/db-setup.sql
  sudo chmod +x /shared/scripts/db.sh
  log "  Copied shared scripts"
fi

if [ -d "$SCRIPT_DIR/shared/policies" ]; then
  sudo cp "$SCRIPT_DIR/shared/policies/"*.json /shared/policies/
  log "  Copied policies"
fi

if [ -d "$SCRIPT_DIR/shared/schemas" ]; then
  sudo mkdir -p /shared/schemas
  sudo cp "$SCRIPT_DIR/shared/schemas/"*.json /shared/schemas/
  log "  Copied schemas"
fi

if [ -d "$SCRIPT_DIR/shared/test-claims" ]; then
  sudo mkdir -p /shared/test-claims
  sudo cp "$SCRIPT_DIR/shared/test-claims/"*.json /shared/test-claims/
  log "  Copied test claims"
fi

# --- Set ownership so agents can write to /shared ---
sudo chown -R "$(whoami):$(whoami)" /shared

echo ""

# ============================================================
# Step 5: Merge Claims Config into OpenClaw (preserve existing settings)
# ============================================================
log "Step 5/8: Merging claims config into openclaw.json..."

# Strategy: We MERGE our agent/channel/binding config into the existing
# openclaw.json. This preserves the gateway auth token, wizard metadata,
# port settings, and anything else openclaw setup/onboard wrote.
#
# Only these keys are added/overwritten by us:
#   - agents.list[]           (our 6 agents)
#   - bindings[]              (telegram → router)
#   - tools.agentToAgent      (enable inter-agent comms)
#   - session.agentToAgent    (max 1 ping-pong turn)
#   - channels.telegram       (bot token + allowlist)
#   - logging                 (info level)
#
# Everything else (gateway, wizard, auth, models, etc.) is KEPT as-is.

# Write our claims-specific settings to a temp file
CLAIMS_CONFIG=$(mktemp)
cat > "$CLAIMS_CONFIG" << CLAIMSEOF
{
  "agents": {
    "list": [
      {
        "id": "router",
        "name": "Claims Router",
        "default": true,
        "workspace": "$OPENCLAW_DIR/workspace-router",
        "model": "anthropic/claude-opus-4-6",
        "identity": { "name": "OpenClaw Claims" },
        "tools": {
          "allow": ["read", "write", "exec", "sessions_send"],
          "deny": ["browser", "gateway", "cron", "sessions_spawn"]
        }
      },
      {
        "id": "claims-officer",
        "name": "Claims Officer",
        "workspace": "$OPENCLAW_DIR/workspace-claims-officer",
        "model": "anthropic/claude-sonnet-4-5",
        "identity": { "name": "Claims Officer" },
        "tools": {
          "allow": ["read", "write", "exec"],
          "deny": ["browser", "gateway", "cron", "sessions_send", "sessions_spawn"]
        }
      },
      {
        "id": "assessor",
        "name": "Damage Assessor",
        "workspace": "$OPENCLAW_DIR/workspace-assessor",
        "model": "anthropic/claude-sonnet-4-5",
        "identity": { "name": "Damage Assessor" },
        "tools": {
          "allow": ["read", "write", "exec"],
          "deny": ["browser", "gateway", "cron", "sessions_send", "sessions_spawn"]
        }
      },
      {
        "id": "fraud-analyst",
        "name": "Fraud Analyst",
        "workspace": "$OPENCLAW_DIR/workspace-fraud-analyst",
        "model": "anthropic/claude-opus-4-6",
        "identity": { "name": "Fraud Analyst" },
        "tools": {
          "allow": ["read", "write", "exec"],
          "deny": ["browser", "gateway", "cron", "sessions_send", "sessions_spawn"]
        }
      },
      {
        "id": "senior-reviewer",
        "name": "Senior Reviewer",
        "workspace": "$OPENCLAW_DIR/workspace-senior-reviewer",
        "model": "anthropic/claude-opus-4-6",
        "identity": { "name": "Senior Reviewer" },
        "tools": {
          "allow": ["read", "write", "exec"],
          "deny": ["browser", "gateway", "cron", "sessions_send", "sessions_spawn"]
        }
      },
      {
        "id": "finance",
        "name": "Finance Agent",
        "workspace": "$OPENCLAW_DIR/workspace-finance",
        "model": "anthropic/claude-sonnet-4-5",
        "identity": { "name": "Finance Agent" },
        "tools": {
          "allow": ["read", "write", "exec"],
          "deny": ["browser", "gateway", "cron", "sessions_send", "sessions_spawn"]
        }
      }
    ]
  },
  "bindings": [
    { "agentId": "router", "match": { "channel": "telegram" } }
  ],
  "tools": {
    "agentToAgent": {
      "enabled": true,
      "allow": ["router", "claims-officer", "assessor", "fraud-analyst", "senior-reviewer", "finance"]
    }
  },
  "session": {
    "agentToAgent": {
      "maxPingPongTurns": 1
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_TOKEN",
      "dmPolicy": "allowlist",
      "allowFrom": ["$TELEGRAM_USER_ID"]
    }
  },
  "logging": {
    "level": "info"
  }
}
CLAIMSEOF

# Use Node.js (already installed in Step 1) to deep-merge configs.
# The existing config may be JSON5 (comments, trailing commas),
# so we strip those before parsing.
node -e "
const fs = require('fs');

// Read existing config (may be JSON5 with comments)
let existing = {};
const configPath = '$OPENCLAW_DIR/openclaw.json';
if (fs.existsSync(configPath)) {
  let raw = fs.readFileSync(configPath, 'utf8');
  // Strip single-line comments and trailing commas for JSON.parse
  raw = raw.replace(/\/\/.*$/gm, '');
  raw = raw.replace(/,(\s*[}\]])/g, '\$1');
  try { existing = JSON.parse(raw); } catch(e) {
    console.error('Warning: could not parse existing config, starting fresh');
    existing = {};
  }
}

// Read our claims config (clean JSON)
const claims = JSON.parse(fs.readFileSync('$CLAIMS_CONFIG', 'utf8'));

// Deep merge: claims settings override, but existing keys not in claims are preserved
function deepMerge(target, source) {
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (
      source[key] && typeof source[key] === 'object' && !Array.isArray(source[key]) &&
      result[key] && typeof result[key] === 'object' && !Array.isArray(result[key])
    ) {
      result[key] = deepMerge(result[key], source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

const merged = deepMerge(existing, claims);
fs.writeFileSync(configPath, JSON.stringify(merged, null, 2) + '\n');

// Report what was preserved
const preserved = [];
if (existing.gateway) preserved.push('gateway (auth token, port, bind)');
if (existing.wizard) preserved.push('wizard metadata');
if (existing.models) preserved.push('model providers');
if (existing.auth) preserved.push('auth profiles');
if (preserved.length > 0) {
  console.log('Preserved from existing config: ' + preserved.join(', '));
} else {
  console.log('No existing config to preserve (fresh install)');
}
"

rm -f "$CLAIMS_CONFIG"

log "Claims config merged into $OPENCLAW_DIR/openclaw.json"
echo ""

# ============================================================
# Step 6: Set Database Environment Variables
# ============================================================
log "Step 6/8: Configuring environment variables..."

# Add DB env vars to .bashrc if not already present
BASHRC="$HOME/.bashrc"
if ! grep -q "OPENCLAW_DB_NAME" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << 'ENVEOF'

# --- OpenClaw Claims Database ---
export OPENCLAW_DB_NAME="openclaw_claims"
export OPENCLAW_DB_USER="openclaw"
export OPENCLAW_DB_HOST="localhost"
export OPENCLAW_DB_PORT="5432"
export PGPASSWORD="$DB_PASS"
ENVEOF
  log "Environment variables added to $BASHRC"
else
  info "Environment variables already in $BASHRC"
fi

# Export for current session too
export OPENCLAW_DB_NAME="openclaw_claims"
export OPENCLAW_DB_USER="openclaw"
export OPENCLAW_DB_HOST="localhost"
export OPENCLAW_DB_PORT="5432"
export PGPASSWORD="$DB_PASS"

echo ""

# ============================================================
# Step 7: Anthropic Auth via Setup-Token
# ============================================================
log "Step 7/8: Anthropic authentication..."
echo ""

if [ -n "$SETUP_TOKEN" ]; then
  # If token was provided via argument, pipe it in
  echo "$SETUP_TOKEN" | openclaw models auth paste-token --provider anthropic
  log "Anthropic setup-token configured."
else
  info "To authenticate with Anthropic (Claude Pro/Max subscription):"
  echo ""
  echo "  1. On ANY machine with Claude Code CLI installed, run:"
  echo "     ${CYAN}claude setup-token${NC}"
  echo ""
  echo "  2. Copy the token output, then on THIS machine run:"
  echo "     ${CYAN}openclaw models auth setup-token --provider anthropic${NC}"
  echo ""
  echo "  3. Paste the token when prompted."
  echo ""
  echo "  4. Verify with:"
  echo "     ${CYAN}openclaw models status${NC}"
  echo ""
  warn "Skipping auth setup for now — run the commands above before starting the gateway."
fi

echo ""

# ============================================================
# Verification
# ============================================================
log "Step 8/8: Running verification checks..."
echo ""

PASS=0
FAIL=0

check() {
  if eval "$2" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $1"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $1"
    FAIL=$((FAIL + 1))
  fi
}

check "Node.js 22+"              "[[ \$(node -v | cut -d. -f1 | tr -d 'v') -ge 22 ]]"
check "PostgreSQL running"        "pg_isready -q"
check "OpenClaw installed"        "command -v openclaw"
check "Database exists"  "PGPASSWORD=$DB_PASS psql -h localhost -U $DB_USER -d $DB_NAME -c 'SELECT 1' -t -A"
check "claims table exists"       "PGPASSWORD=$DB_PASS psql -h localhost -U $DB_USER -d $DB_NAME -c \"SELECT 1 FROM claims LIMIT 0\" -t -A"
check "claim_media table exists"  "PGPASSWORD=$DB_PASS psql -h localhost -U $DB_USER -d $DB_NAME -c \"SELECT 1 FROM claim_media LIMIT 0\" -t -A"
check "openclaw.json exists"      "[ -f $OPENCLAW_DIR/openclaw.json ]"
check "Router workspace"          "[ -f $OPENCLAW_DIR/workspace-router/AGENTS.md ]"
check "Claims Officer workspace"  "[ -f $OPENCLAW_DIR/workspace-claims-officer/AGENTS.md ]"
check "Assessor workspace"        "[ -f $OPENCLAW_DIR/workspace-assessor/AGENTS.md ]"
check "Fraud Analyst workspace"   "[ -f $OPENCLAW_DIR/workspace-fraud-analyst/AGENTS.md ]"
check "Finance workspace"         "[ -f $OPENCLAW_DIR/workspace-finance/AGENTS.md ]"
check "db.sh script"              "[ -x /shared/scripts/db.sh ]"
check "Senior Reviewer workspace" "[ -f $OPENCLAW_DIR/workspace-senior-reviewer/AGENTS.md ]"
check "Policies"                  "[ -f /shared/policies/POL-AUT-10001.json ]"
check "Claim schema"              "[ -f /shared/schemas/claim.schema.json ]"
check "Test claims"               "[ -d /shared/test-claims ]"
check "Default workspace intact"  "[ -d $OPENCLAW_DIR/workspace ]"
check "Config backup exists"      "[ -f $OPENCLAW_DIR/openclaw.json.bak ]"

echo ""
echo -e "  ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo ""

# ============================================================
# Done
# ============================================================
if [ $FAIL -eq 0 ]; then
  log "Setup complete! All checks passed."
else
  warn "Setup complete with $FAIL issue(s). Review the failed checks above."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Set up Anthropic auth (if not done):"
echo "     ${CYAN}openclaw models auth setup-token --provider anthropic${NC}"
echo ""
echo "  2. Verify auth:"
echo "     ${CYAN}openclaw models status${NC}"
echo ""
echo "  3. Validate config:"
echo "     ${CYAN}openclaw doctor${NC}"
echo ""
echo "  4. Start the gateway:"
echo "     ${CYAN}openclaw start${NC}"
echo ""
echo "  5. Send a message to your Telegram bot to test!"
echo ""
echo "  To restore OpenClaw's original config:"
echo "     ${CYAN}cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
