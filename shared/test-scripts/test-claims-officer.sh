#!/bin/bash
# ============================================================
# Pin-Test: Claims Officer (Stage 1)
# ============================================================
# Seeds: front_desk completed (FNOL_RECEIVED)
# Expects: Claims Officer verifies coverage, checks exclusions
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/claims-officer.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-001"
rm "$TMP_SEED"

# Phase 2: INVOKE (mirrors Router's task message template)
TASK_MSG="Verify coverage for claim $CLAIM_ID. Policy: POL-AUT-10001, file: /shared/policies/POL-AUT-10001.json. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. Regulatory: denial must be communicated within regulatory window; document all exclusions per FCSP; ambiguity favors insured. Steps: read claim, read policy, verify active on incident date, determine coverage type, check exclusions, write results via db.sh, announce."

invoke_agent "claims-officer" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Claims Officer Output"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.claims_officer.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_field "$CLAIM_ID" ".pipeline.claims_officer.covered" "true" "covered" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.claims_officer.policy_status" "policy_status" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.claims_officer.coverage_type" "coverage_type" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_non_empty_array "$CLAIM_ID" ".pipeline.claims_officer.exclusions_checked" "exclusions_checked" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "claims_officer"

# Summary
print_summary "Claims Officer" "$PASS" "$TOTAL"

# Cleanup (comment out to inspect DB state)
# cleanup "$CLAIM_ID"

log_info "Claim $CLAIM_ID left in DB for inspection. Run: delete_claim $CLAIM_ID"
