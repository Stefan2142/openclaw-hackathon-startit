#!/bin/bash
# ============================================================
# Test: Single Active Claim Enforcement
# ============================================================
# Seeds: a claim in ASSESSED status for a test user
# Sends: "I had another accident" to Router as the same user
# Expects: Router does NOT create a second claim; references
#          the existing active claim instead
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-SC-$(date +%s | tail -c 6)"
TEST_USER="test-single-claim-user"
PASS=0
TOTAL=0

# Phase 1: Seed an active claim for the test user
log_step "SEED: Active claim for $TEST_USER"

# Create a minimal claim in ASSESSED status (mid-pipeline, definitely active)
SEED_JSON=$(cat <<SEEDEOF
{
  "claim_id": "$CLAIM_ID",
  "status": "ASSESSED",
  "submitted_at": "2026-02-21T08:00:00Z",
  "updated_at": "2026-02-21T09:00:00Z",
  "claimant": {
    "policy_id": "POL-AUT-10001",
    "name": "Active Claim User",
    "contact_phone": "555-000-0001"
  },
  "incident": {
    "date": "2026-02-19",
    "type": "collision",
    "location": "Main St, Columbus OH",
    "description": "Rear-ended at a traffic light"
  },
  "pipeline": {
    "front_desk": {"completed_at": "2026-02-21T08:01:00Z"},
    "claims_officer": {"completed_at": "2026-02-21T08:30:00Z", "covered": true},
    "assessor": {"completed_at": "2026-02-21T09:00:00Z", "repair_estimate_usd": 3500},
    "fraud_analyst": {"completed_at": null},
    "senior_reviewer": {"completed_at": null},
    "finance": {"completed_at": null}
  },
  "audit_log": []
}
SEEDEOF
)

TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "$TEST_USER"
rm "$TMP_SEED"

# Verify get-active-claim returns this claim
log_step "VERIFY: get-active-claim returns seeded claim"
ACTIVE=$(vps "PGPASSWORD=$DB_PASS bash /shared/scripts/db.sh get-active-claim '$TEST_USER'" 2>/dev/null)
TOTAL=$((TOTAL + 1))
if echo "$ACTIVE" | jq -r '.claim_id' 2>/dev/null | grep -q "$CLAIM_ID"; then
  log_ok "get-active-claim returns $CLAIM_ID"
  PASS=$((PASS + 1))
else
  log_fail "get-active-claim did not return $CLAIM_ID"
  log_info "Got: $(echo "$ACTIVE" | head -3)"
fi

# Phase 2: Reset Router and send new claim attempt as same user
log_step "INVOKE: Router with new claim attempt"
vps "openclaw agent --agent router --message '/new' --timeout 30" > /dev/null 2>&1

# Note: The Router needs to know the user_id to check active claims.
# In production, Telegram provides this. In test, we include it in the message context.
NEW_MSG="I had another car accident today on Interstate 70. A truck rear-ended me. My name is Active Claim User, policy POL-AUT-10001, phone 555-000-0001. User ID: $TEST_USER"

RESPONSE=$(vps "openclaw agent --agent 'router' --message '$NEW_MSG' --timeout 120 2>&1" 2>&1)

echo ""
log_info "Router response (first 20 lines):"
echo "$RESPONSE" | head -20

# Phase 3: VERIFY
log_step "VERIFY: Single Claim Enforcement"

# Check 1: Router references the existing claim
TOTAL=$((TOTAL + 1))
if echo "$RESPONSE" | grep -qi "$CLAIM_ID\|active claim\|existing claim\|already\|current claim\|being processed"; then
  log_ok "Router references existing active claim"
  PASS=$((PASS + 1))
else
  log_fail "Router did NOT reference the existing claim"
fi

# Check 2: No second claim created for this user
TOTAL=$((TOTAL + 1))
CLAIM_COUNT=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT count(*) FROM claims WHERE user_id = '$TEST_USER';\"" 2>/dev/null)
if [ "$CLAIM_COUNT" = "1" ]; then
  log_ok "Only 1 claim exists for user (no duplicate created)"
  PASS=$((PASS + 1))
else
  log_fail "Found $CLAIM_COUNT claims for user (expected 1)"
fi

# Check 3: Original claim unchanged
TOTAL=$((TOTAL + 1))
ORIG_STATUS=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT status FROM claims WHERE claim_id = '$CLAIM_ID';\"" 2>/dev/null)
if [ "$ORIG_STATUS" = "ASSESSED" ]; then
  log_ok "Original claim status unchanged (ASSESSED)"
  PASS=$((PASS + 1))
else
  log_fail "Original claim status changed to '$ORIG_STATUS' (expected ASSESSED)"
fi

# Summary
print_summary "Single Active Claim" "$PASS" "$TOTAL"

# Cleanup
cleanup "$CLAIM_ID"
vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"DELETE FROM agent_traces WHERE claim_id = '$CLAIM_ID';\"" > /dev/null 2>&1

log_info "Test complete."
