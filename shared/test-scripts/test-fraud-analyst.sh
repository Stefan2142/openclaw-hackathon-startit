#!/bin/bash
# ============================================================
# Pin-Test: Fraud Analyst (Stage 3)
# ============================================================
# Seeds: front_desk + claims_officer + assessor completed (ASSESSED)
# Expects: Fraud Analyst evaluates 7 patterns, scores risk
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/fraud-analyst.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-001"
rm "$TMP_SEED"

# Phase 2: INVOKE
TASK_MSG="Analyze fraud for claim $CLAIM_ID, user test-user-001. Assessment: estimate=4500, total_loss=false, pre-existing=[]. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. History: bash /shared/scripts/db.sh list-claims-by-user test-user-001. Regulatory: flag and recommend only, do NOT deny. Steps: read claim, verify Assessor complete, analyze 7 fraud patterns, write results via db.sh, announce."

invoke_agent "fraud-analyst" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Fraud Analyst Output"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.fraud_analyst.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.fraud_analyst.risk_score" "risk_score" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.fraud_analyst.risk_level" "low" "medium" "high" "critical" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.fraud_analyst.recommendation" "CLEAR" "INVESTIGATE" "REFER_SIU" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.fraud_analyst.soft_fraud" "soft_fraud" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "fraud_analyst"

# Summary
print_summary "Fraud Analyst" "$PASS" "$TOTAL"

log_info "Claim $CLAIM_ID left in DB for inspection."
