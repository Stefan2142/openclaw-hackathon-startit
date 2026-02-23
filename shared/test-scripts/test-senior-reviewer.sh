#!/bin/bash
# ============================================================
# Pin-Test: Senior Reviewer (Stage 4)
# ============================================================
# Seeds: All stages through fraud_analyst completed (FRAUD_ANALYZED)
# Expects: Senior Reviewer makes APPROVED/DENIED/CONDITIONAL/ESCALATE decision
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"
SEED_FILE="$SCRIPT_DIR/seed-data/senior-reviewer.json"

# Update claim_id in seed data
SEED_JSON=$(cat "$SEED_FILE" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-001"
rm "$TMP_SEED"

# Phase 2: INVOKE
TASK_MSG="Review and decide claim $CLAIM_ID. Fraud: score=8/100, level=low, rec=CLEAR. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. Regulatory: FCSP decision within regulatory window; Ohio bad faith = compensatory damages + attorney fees. Steps: read claim, verify Fraud Analyst complete, review ALL stages, check FCSP timeline, decide (APPROVED/DENIED/CONDITIONAL/ESCALATE_HUMAN), write results via db.sh, announce."

invoke_agent "senior-reviewer" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Senior Reviewer Output"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.senior_reviewer.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.senior_reviewer.decision" "APPROVED" "DENIED" "CONDITIONAL" "ESCALATE_HUMAN" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.senior_reviewer.decision_reasoning" "decision_reasoning" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.senior_reviewer.fcsp_timeline_check" "fcsp_timeline_check" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "senior_reviewer"

# Summary
print_summary "Senior Reviewer" "$PASS" "$TOTAL"

log_info "Claim $CLAIM_ID left in DB for inspection."
