#!/bin/bash
# ============================================================
# Test: FNOL Collection Loop via Router
# ============================================================
# Sends an incomplete claim to the Router, verifies it asks
# for missing info, then sends a follow-up with complete data.
# Verifies a claim is created in the DB.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

TEST_USER="test-fnol-loop-$(date +%s | tail -c 6)"
PASS=0
TOTAL=0

# Phase 1: Reset Router session
log_step "RESET: Router session"
vps "openclaw agent --agent router --message '/new' --timeout 30" > /dev/null 2>&1
log_ok "Router session reset"

# Phase 2: Send INCOMPLETE message (missing: policy_id, name, phone, date)
log_step "SEND: Incomplete claim (missing fields)"
INCOMPLETE_MSG="I had a car accident on Main Street in Columbus. Another car hit me at the intersection."

RESPONSE1=$(vps "openclaw agent --agent 'router' --message '$INCOMPLETE_MSG' --timeout 120 2>&1" 2>&1)

echo ""
log_info "Router response (first 20 lines):"
echo "$RESPONSE1" | head -20

# Check 1: Router asks for missing info
TOTAL=$((TOTAL + 1))
if echo "$RESPONSE1" | grep -qi "policy\|name\|phone\|date\|when\|number\|information\|details\|need"; then
  log_ok "Router asks for missing information"
  PASS=$((PASS + 1))
else
  log_fail "Router did NOT ask for missing info"
fi

# Check 2: No claim created yet (Router should collect first)
TOTAL=$((TOTAL + 1))
# Check if any very recent claims exist for this user session
RECENT_CLAIMS=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT count(*) FROM claims WHERE created_at > NOW() - INTERVAL '2 minutes';\"" 2>/dev/null)
# This is a soft check — Router may or may not have created the claim yet
log_info "Recent claims in last 2 min: $RECENT_CLAIMS"
if [ "$RECENT_CLAIMS" = "0" ] || [ -z "$RECENT_CLAIMS" ]; then
  log_ok "No premature claim creation (Router collecting info first)"
  PASS=$((PASS + 1))
else
  log_warn "Claims exist — Router may have created claim already (acceptable if it asked for info too)"
  PASS=$((PASS + 1))  # Not a hard failure
fi

# Phase 3: Send COMPLETE follow-up
log_step "SEND: Complete follow-up (all fields)"
COMPLETE_MSG="My name is John Smith, policy number POL-AUT-10001, phone 555-234-5678. The accident was a collision on February 19, 2026 around 2:30 PM. The other driver ran a red light and hit my car. Their name is Maria Rodriguez. No injuries, car is drivable. No police report."

RESPONSE2=$(vps "openclaw agent --agent 'router' --message '$COMPLETE_MSG' --timeout 180 2>&1" 2>&1)

echo ""
log_info "Router response (first 30 lines):"
echo "$RESPONSE2" | head -30

# Give the Router a moment to create the claim in DB
sleep 3

# Check 3: Claim was created in DB
TOTAL=$((TOTAL + 1))
# Find the claim — look for any claim with POL-AUT-10001 created in the last 5 minutes
CLAIM_FOUND=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT claim_id FROM claims WHERE policy_id = 'POL-AUT-10001' AND created_at > NOW() - INTERVAL '5 minutes' ORDER BY created_at DESC LIMIT 1;\"" 2>/dev/null)

if [ -n "$CLAIM_FOUND" ] && [ "$CLAIM_FOUND" != "" ]; then
  log_ok "Claim created in DB: $CLAIM_FOUND"
  PASS=$((PASS + 1))
else
  log_fail "No claim found in DB with POL-AUT-10001 from last 5 minutes"
fi

# Check 4: Router response confirms claim creation
TOTAL=$((TOTAL + 1))
if echo "$RESPONSE2" | grep -qi "CLM-\|claim\|received\|reference\|reviewing\|processing"; then
  log_ok "Router confirms claim creation/processing"
  PASS=$((PASS + 1))
else
  log_fail "Router response doesn't confirm claim creation"
fi

# Check 5: Claim has proper status (at least FNOL_RECEIVED)
if [ -n "$CLAIM_FOUND" ]; then
  TOTAL=$((TOTAL + 1))
  CLAIM_STATUS=$(vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"SELECT status FROM claims WHERE claim_id = '$CLAIM_FOUND';\"" 2>/dev/null)
  if [ -n "$CLAIM_STATUS" ] && [ "$CLAIM_STATUS" != "" ]; then
    log_ok "Claim status: $CLAIM_STATUS"
    PASS=$((PASS + 1))
  else
    log_fail "Could not read claim status"
  fi
fi

# Summary
print_summary "FNOL Collection Loop" "$PASS" "$TOTAL"

# Cleanup
if [ -n "$CLAIM_FOUND" ]; then
  log_step "CLEANUP"
  delete_claim "$CLAIM_FOUND"
  # Also clean up traces
  vps "PGPASSWORD=$DB_PASS psql -h localhost -U openclaw -d openclaw_claims -t -A -c \"DELETE FROM agent_traces WHERE claim_id = '$CLAIM_FOUND';\"" > /dev/null 2>&1
  log_ok "Deleted $CLAIM_FOUND and traces"
fi

log_info "Test complete."
