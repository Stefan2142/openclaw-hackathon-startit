#!/bin/bash
# ============================================================
# Pin-Test: Finance Agent (Stage 5)
# ============================================================
# Seeds: All stages through senior_reviewer completed (REVIEWED, decision=APPROVED)
# Expects: Finance calculates and issues payment
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/finance.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-001"
rm "$TMP_SEED"

# Phase 2: INVOKE
TASK_MSG="Process payment for claim $CLAIM_ID. Approval: decision=APPROVED, conditions=none, estimate=4500, deductible=500, limit=null, total_loss=false. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. Steps: read claim, VERIFY decision is APPROVED/CONDITIONAL, calculate payment (estimate - deductible - depreciation, capped at limit), write results via db.sh, announce."

invoke_agent "finance" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Finance Output"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.finance.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_positive_number "$CLAIM_ID" ".pipeline.finance.payment_amount_usd" "payment_amount_usd" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.finance.deductible_applied_usd" "deductible_applied_usd" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.finance.payment_method" "payment_method" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.finance.payment_reference" "payment_reference" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "finance"

# Summary
print_summary "Finance" "$PASS" "$TOTAL"

log_info "Claim $CLAIM_ID left in DB for inspection."
