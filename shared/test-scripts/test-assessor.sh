#!/bin/bash
# ============================================================
# Pin-Test: Assessor (Stage 2)
# ============================================================
# Seeds: front_desk + claims_officer completed (COVERAGE_CHECKED)
# Expects: Assessor estimates damage, checks total loss
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/assessor.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-001"
rm "$TMP_SEED"

# Phase 2: INVOKE
TASK_MSG="Assess damage for claim $CLAIM_ID. Coverage confirmed: type=collision. Read claim: bash /shared/scripts/db.sh get-claim-assessor $CLAIM_ID. IMPORTANT: Use get-claim-assessor (not get-claim) to enforce separation of duties — you must not see policy financial data. Regulatory: Ohio 100% ACV for total loss; OEM vs aftermarket per professional judgment. Steps: read claim, verify Claims Officer complete, estimate repair costs, determine total loss vs repairable, write results via db.sh, announce."

invoke_agent "assessor" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Assessor Output"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.assessor.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_positive_number "$CLAIM_ID" ".pipeline.assessor.repair_estimate_usd" "repair_estimate_usd" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.assessor.total_loss" "total_loss" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.assessor.parts_recommendation" "OEM" "aftermarket" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.assessor.labor_hours" "labor_hours" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.assessor.rental_days" "rental_days" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "assessor"

# Summary
print_summary "Assessor" "$PASS" "$TOTAL"

log_info "Claim $CLAIM_ID left in DB for inspection."
