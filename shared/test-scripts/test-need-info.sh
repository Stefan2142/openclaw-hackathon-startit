#!/bin/bash
# ============================================================
# Pin-Test: Claims Officer NEED_INFO Response
# ============================================================
# Seeds: claim with policy_id POL-FAKE-99999 (does not exist)
# Expects: CO announces NEED_INFO (not SUCCESS or ERROR)
#          CO does NOT write completed_at (hasn't finished)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-NI-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/need-info.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-needinfo"
rm "$TMP_SEED"

# Phase 2: INVOKE CO with fake policy
# The policy file POL-FAKE-99999.json does NOT exist in /shared/policies/
TASK_MSG="Verify coverage for claim $CLAIM_ID. Policy: POL-FAKE-99999, file: /shared/policies/POL-FAKE-99999.json. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. Regulatory: denial must be communicated within regulatory window; document all exclusions per FCSP; ambiguity favors insured. Steps: read claim, read policy, verify active on incident date, determine coverage type, check exclusions, write results via db.sh, announce."

log_step "INVOKE: claims-officer (expecting NEED_INFO)"
log_info "Message: ${TASK_MSG:0:120}..."

# Capture full response for NEED_INFO check
RESPONSE=$(vps "openclaw agent --agent 'claims-officer' --message '$TASK_MSG' --timeout 180 2>&1" 2>&1)

echo ""
log_info "Agent response (first 40 lines):"
echo "$RESPONSE" | head -40

# Phase 3: VERIFY
log_step "VERIFY: NEED_INFO Behavior"
PASS=0
TOTAL=0

# Check 1: Response contains NEED_INFO
TOTAL=$((TOTAL + 1))
if echo "$RESPONSE" | grep -qi "NEED_INFO"; then
  log_ok "Response contains NEED_INFO"
  PASS=$((PASS + 1))
else
  log_fail "Response does NOT contain NEED_INFO"
  log_warn "Response may contain ERROR or SUCCESS instead"
fi

# Check 2: CO did NOT write completed_at (should still be null)
TOTAL=$((TOTAL + 1))
CLAIM_DATA=$(get_claim "$CLAIM_ID")
COMPLETED=$(echo "$CLAIM_DATA" | jq -r '.pipeline.claims_officer.completed_at // empty' 2>/dev/null)
if [ -z "$COMPLETED" ] || [ "$COMPLETED" = "null" ]; then
  log_ok "completed_at is null (CO did not finish — correct for NEED_INFO)"
  PASS=$((PASS + 1))
else
  log_fail "completed_at = $COMPLETED (CO should NOT have completed during NEED_INFO)"
fi

# Check 3: Status is still FNOL_RECEIVED (not advanced)
TOTAL=$((TOTAL + 1))
STATUS=$(echo "$CLAIM_DATA" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "FNOL_RECEIVED" ]; then
  log_ok "Status still FNOL_RECEIVED (pipeline not advanced — correct)"
  PASS=$((PASS + 1))
else
  log_fail "Status = $STATUS (expected FNOL_RECEIVED)"
fi

# Check 4: Response mentions policy or policy_id issue
TOTAL=$((TOTAL + 1))
if echo "$RESPONSE" | grep -qi "policy\|POL-FAKE\|not found\|cannot find\|does not exist\|missing"; then
  log_ok "Response references the policy issue"
  PASS=$((PASS + 1))
else
  log_warn "Response may not clearly explain the policy issue"
fi

# Summary
print_summary "Claims Officer NEED_INFO" "$PASS" "$TOTAL"

# Cleanup
cleanup "$CLAIM_ID"
