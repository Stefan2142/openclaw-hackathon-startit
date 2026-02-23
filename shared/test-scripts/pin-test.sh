#!/bin/bash
# ============================================================
# Pin-Test Harness for OpenClaw Agent Isolation Testing
# ============================================================
# "Pin Input" = freeze the DB state to a known point, then run
# a single agent against it. Like N810's pin feature.
#
# Usage: source this file from per-agent test scripts.
#
# Requires:
#   - OpenClaw gateway running on VPS (openclaw start)
#   - PostgreSQL accessible
#   - jq installed on VPS
# ============================================================

# --- VPS Connection ---
VPS_HOST="${VPS_HOST:?Set VPS_HOST env var}"
VPS_USER="${VPS_USER:-root}"
VPS_PASS="${VPS_PASS:?Set VPS_PASS env var}"

# Remote command helper (uses sshpass for non-interactive)
vps() {
  sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "$@"
}

# Remote file copy helper
vps_put() {
  sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no "$1" "$VPS_USER@$VPS_HOST:$2"
}

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step()  { echo -e "\n${YELLOW}=== $1 ===${NC}"; }

# --- DB Helpers (run on VPS) ---
# Note: db.sh relies on .pgpass which may be stale, so we always set PGPASSWORD

DB_PASS="${DB_PASS:?Set DB_PASS env var}"

# Run db.sh with explicit password
db() {
  vps "PGPASSWORD=$DB_PASS bash /shared/scripts/db.sh $*"
}

# Delete a test claim if it exists
delete_claim() {
  local claim_id="$1"
  vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"DELETE FROM claims WHERE claim_id = '$claim_id';\""
}

# Seed a claim from a JSON file (copies to VPS, inserts via python3+json)
seed_claim() {
  local claim_id="$1"
  local seed_file="$2"
  local channel="${3:-telegram}"
  local user_id="${4:-test-user}"

  log_step "SEED: $claim_id from $(basename $seed_file)"

  # Read seed JSON
  if [ ! -f "$seed_file" ]; then
    log_fail "Seed file not found: $seed_file"
    return 1
  fi

  # Extract metadata locally
  local policy_id
  policy_id=$(jq -r '.claimant.policy_id' "$seed_file")
  local target_status
  target_status=$(jq -r '.status' "$seed_file")

  # Delete existing claim
  delete_claim "$claim_id"

  # Copy seed file to VPS
  local vps_tmp="/tmp/pin-test-seed-$$.json"
  vps_put "$seed_file" "$vps_tmp"

  # Insert via python3 (handles JSON escaping cleanly)
  log_info "Creating claim $claim_id..."
  vps "python3 << 'PYEOF'
import json, subprocess

with open('$vps_tmp') as f:
    data = json.load(f)

# Escape single quotes for SQL
json_str = json.dumps(data).replace(\"'\", \"''\")

sql = f\"INSERT INTO claims (claim_id, status, channel, user_id, policy_id, claim_data) VALUES ('$claim_id', 'FNOL_RECEIVED', '$channel', '$user_id', '$policy_id', '{json_str}'::jsonb);\"

result = subprocess.run(
    ['psql', '-h', 'localhost', '-U', 'openclaw', '-d', 'openclaw_claims', '-t', '-A', '-c', sql],
    env={'PGPASSWORD': '$DB_PASS', 'PATH': '/usr/bin:/usr/local/bin'},
    capture_output=True, text=True
)
if result.returncode == 0:
    print('INSERT OK')
else:
    print(f'ERROR: {result.stderr}')
PYEOF" 2>&1

  # Clean up VPS temp file
  vps "rm -f $vps_tmp" 2>/dev/null

  # If target status is not FNOL_RECEIVED, update it
  if [ "$target_status" != "FNOL_RECEIVED" ]; then
    log_info "Setting status to $target_status..."
    vps "PGPASSWORD=$DB_PASS bash /shared/scripts/db.sh update-status '$claim_id' '$target_status'" > /dev/null 2>&1
  fi

  # Verify the seed
  local db_status
  db_status=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT status FROM claims WHERE claim_id = '$claim_id';\"")

  if [ "$db_status" = "$target_status" ]; then
    log_ok "Claim seeded: $claim_id (status=$target_status)"
  else
    log_fail "Seed failed. DB status: '$db_status', expected: '$target_status'"
    return 1
  fi
}

# Invoke a specific agent via openclaw agent CLI
invoke_agent() {
  local agent_id="$1"
  local message="$2"
  local timeout="${3:-300}"

  log_step "INVOKE: $agent_id"
  log_info "Message: ${message:0:120}..."
  log_info "Timeout: ${timeout}s"

  # Use openclaw agent CLI on VPS (synchronous - waits for agent to finish)
  # --json gives structured output, --timeout caps the run
  local response
  log_info "Running: openclaw agent --agent $agent_id --timeout $timeout --json ..."
  response=$(vps "openclaw agent --agent '$agent_id' --message '$message' --timeout $timeout --json 2>&1" 2>&1)

  echo ""
  log_info "Agent response (first 40 lines):"
  echo "$response" | head -40

  # Check if agent wrote its pipeline section to DB
  local step_name="${agent_id//-/_}"
  local claim_data
  claim_data=$(vps "bash /shared/scripts/db.sh get-claim '$CLAIM_ID'" 2>/dev/null)
  if [ -n "$claim_data" ] && [ "$claim_data" != "" ]; then
    local completed
    completed=$(echo "$claim_data" | jq -r ".pipeline.${step_name}.completed_at // empty" 2>/dev/null)
    if [ -n "$completed" ] && [ "$completed" != "null" ]; then
      log_ok "Agent completed at $completed"
      return 0
    fi
  fi

  log_warn "Agent may not have written to DB. Check response above."
  return 1
}

# Read claim from VPS DB and return JSON
get_claim() {
  local claim_id="$1"
  vps "PGPASSWORD=$DB_PASS bash /shared/scripts/db.sh get-claim '$claim_id'" 2>/dev/null
}

# --- Verification Helpers ---

verify_not_null() {
  local claim_id="$1"
  local jq_path="$2"
  local label="${3:-$jq_path}"

  local claim_data
  claim_data=$(get_claim "$claim_id")
  local value
  value=$(echo "$claim_data" | jq -r "$jq_path" 2>/dev/null)

  if [ -n "$value" ] && [ "$value" != "null" ] && [ "$value" != "" ]; then
    log_ok "$label = $value"
    return 0
  else
    log_fail "$label is null/empty"
    return 1
  fi
}

verify_field() {
  local claim_id="$1"
  local jq_path="$2"
  local expected="$3"
  local label="${4:-$jq_path}"

  local claim_data
  claim_data=$(get_claim "$claim_id")
  local actual
  actual=$(echo "$claim_data" | jq -r "$jq_path" 2>/dev/null)

  if [ "$actual" = "$expected" ]; then
    log_ok "$label = $actual"
    return 0
  else
    log_fail "$label: expected '$expected', got '$actual'"
    return 1
  fi
}

verify_positive_number() {
  local claim_id="$1"
  local jq_path="$2"
  local label="${3:-$jq_path}"

  local claim_data
  claim_data=$(get_claim "$claim_id")
  local value
  value=$(echo "$claim_data" | jq -r "$jq_path" 2>/dev/null)

  if [ -n "$value" ] && [ "$value" != "null" ] && [ "$(echo "$value > 0" | bc 2>/dev/null)" = "1" ]; then
    log_ok "$label = $value (positive number)"
    return 0
  else
    log_fail "$label is not a positive number (got: '$value')"
    return 1
  fi
}

verify_in_set() {
  local claim_id="$1"
  local jq_path="$2"
  shift 2
  local label="$jq_path"
  local valid_values=("$@")

  local claim_data
  claim_data=$(get_claim "$claim_id")
  local actual
  actual=$(echo "$claim_data" | jq -r "$jq_path" 2>/dev/null)

  for v in "${valid_values[@]}"; do
    if [ "$actual" = "$v" ]; then
      log_ok "$label = $actual (valid)"
      return 0
    fi
  done

  log_fail "$label = '$actual' (expected one of: ${valid_values[*]})"
  return 1
}

verify_non_empty_array() {
  local claim_id="$1"
  local jq_path="$2"
  local label="${3:-$jq_path}"

  local claim_data
  claim_data=$(get_claim "$claim_id")
  local length
  length=$(echo "$claim_data" | jq "$jq_path | length" 2>/dev/null)

  if [ -n "$length" ] && [ "$length" -gt 0 ] 2>/dev/null; then
    log_ok "$label has $length entries"
    return 0
  else
    log_fail "$label is empty or not an array"
    return 1
  fi
}

# Dump the full pipeline section for an agent
dump_agent_output() {
  local claim_id="$1"
  local agent_step="$2"

  log_step "OUTPUT: pipeline.$agent_step"
  local claim_data
  claim_data=$(get_claim "$claim_id")
  echo "$claim_data" | jq ".pipeline.$agent_step" 2>/dev/null
}

# Cleanup
cleanup() {
  local claim_id="$1"
  log_step "CLEANUP"
  delete_claim "$claim_id"
  log_ok "Deleted $claim_id"
}

# Summary
print_summary() {
  local agent="$1"
  local pass_count="$2"
  local total_count="$3"

  echo ""
  echo "============================================"
  if [ "$pass_count" -eq "$total_count" ]; then
    echo -e "${GREEN}  $agent: ALL $total_count CHECKS PASSED${NC}"
  else
    echo -e "${RED}  $agent: $pass_count/$total_count CHECKS PASSED${NC}"
  fi
  echo "============================================"
}

# Check prerequisites
check_prereqs() {
  log_step "PREREQUISITES"

  # Check sshpass
  if ! command -v sshpass &> /dev/null; then
    log_fail "sshpass not installed. Run: brew install hudochenkov/sshpass/sshpass"
    return 1
  fi
  log_ok "sshpass available"

  # Check jq
  if ! command -v jq &> /dev/null; then
    log_fail "jq not installed. Run: brew install jq"
    return 1
  fi
  log_ok "jq available"

  # Check VPS connectivity
  if ! vps "echo ok" &>/dev/null; then
    log_fail "Cannot connect to VPS $VPS_HOST"
    return 1
  fi
  log_ok "VPS reachable"

  # Check gateway
  local gw_status
  gw_status=$(vps "timeout 5 openclaw gateway status 2>&1 | grep -c 'RPC probe'" 2>/dev/null)
  if [ "$gw_status" -ge 1 ] 2>/dev/null; then
    log_ok "Gateway running"
  else
    log_warn "Gateway may not be running - check manually"
  fi

  return 0
}

log_info "Pin-Test harness loaded. Source this from your test scripts."
