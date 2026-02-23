#!/bin/bash
# ============================================================
# Pin-Test: Fraud Analyst with SUSPICIOUS claim
# ============================================================
# Uses the fraud-rejection-siu test claim (CLM-2026-00002)
# which has multiple fraud indicators:
# - 4 passengers all claiming injuries from low-speed impact
# - All same attorney
# - Friends as witnesses
# - Prior similar claim
#
# Expects: High fraud score, INVESTIGATE or REFER_SIU
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pin-test.sh"

check_prereqs || exit 1

CLAIM_ID="CLM-TEST-$(date +%s | tail -c 6)"

# Build seed data from the suspicious claim with assessor stage completed
SEED_JSON=$(cat <<'ENDJSON'
{
  "claim_id": "PLACEHOLDER",
  "status": "ASSESSED",
  "submitted_at": "2026-02-21T11:00:00Z",
  "updated_at": "2026-02-21T11:15:00Z",
  "claimant": {
    "policy_id": "POL-AUT-10001",
    "name": "John Smith",
    "contact_phone": "555-234-5678",
    "contact_email": "john.smith@example.com"
  },
  "incident": {
    "date": "2026-02-18",
    "time": "17:45",
    "location": "Parking lot exit at Eastland Mall, 2740 S Hamilton Rd, Columbus, OH",
    "description": "I was stopped at the exit of the Eastland Mall parking lot waiting to turn right onto Hamilton Road. Traffic was heavy due to the evening rush. A white Toyota Camry behind me rolled forward and struck the rear of my vehicle at low speed, maybe 5 to 10 mph. The impact felt like a firm bump but nothing extreme. I had four passengers in my car -- my friends Marcus Williams, Terrell Jackson, Devon Harris, and Anthony Brown. We were heading to a restaurant for dinner. After the collision, all four of my passengers started experiencing neck and back pain. Marcus said his shoulder was hurting too. We all went to the MedFirst Urgent Care clinic on East Broad Street that evening to get checked out. The doctor said we all had soft tissue injuries and whiplash symptoms. My passengers and I have retained Attorney Lawrence Mitchell at Mitchell & Associates to represent us regarding our injuries. I spoke with Marcus and Terrell and they confirmed they are also working with Attorney Mitchell since he was recommended by a friend. The other driver apologized and said he was looking at his phone when his foot slipped off the brake. A police officer came about 25 minutes later and took a report. My friends Dwayne Cooper and Rashid Thompson were in the car behind me and saw the whole thing happen. The damage to my rear bumper looks like some scuffing and a small crack in the bumper cover. The other driver's car had a small dent on the front bumper. I also had a similar incident about 8 months ago at a different parking lot where someone backed into my car, but that claim was for property damage only.",
    "type": "collision",
    "other_party": {
      "name": "Kevin Park",
      "insurance_company": "Progressive",
      "policy_number": "PGR-44-2198765",
      "contact": "555-432-1098"
    },
    "police_report_number": "CPD-2026-017865",
    "photos": [],
    "injuries_reported": true,
    "witnesses": [
      {
        "name": "Dwayne Cooper",
        "contact": "555-678-2345",
        "statement": "I was in the car directly behind the Toyota. I saw the Toyota roll into the back of the Honda. It was a very low speed impact. After the collision everyone in the Honda got out saying they were hurt."
      },
      {
        "name": "Rashid Thompson",
        "contact": "555-678-3456",
        "statement": "I was a passenger in Dwayne's car. We were right behind the Toyota when it bumped into the Honda ahead of it. It was barely a tap. Then all the people in the Honda started complaining about injuries."
      }
    ]
  },
  "pipeline": {
    "front_desk": {
      "completed_at": "2026-02-21T11:01:00Z",
      "agent_session": "agent:router:main",
      "category": "collision with injuries",
      "priority": "high",
      "cat_event": null,
      "missing_info": []
    },
    "claims_officer": {
      "completed_at": "2026-02-21T11:06:00Z",
      "agent_session": "agent:claims-officer:main",
      "covered": true,
      "policy_status": "active",
      "coverage_type": "collision",
      "deductible_amount": 500,
      "coverage_limit": null,
      "exclusions_checked": [
        "intentional_acts: not applicable",
        "racing: not applicable",
        "commercial_use: not applicable",
        "excluded_drivers: not applicable",
        "non_owned_vehicle: not applicable",
        "mechanical_breakdown: not applicable",
        "wear_and_tear: not applicable",
        "nuclear_war_seizure: not applicable"
      ],
      "denial_reason": null,
      "um_uim_route": "not_applicable"
    },
    "assessor": {
      "completed_at": "2026-02-21T11:12:00Z",
      "agent_session": "agent:assessor:main",
      "repair_estimate_usd": 1200,
      "total_loss": false,
      "acv_usd": null,
      "salvage_value_usd": null,
      "parts_recommendation": "aftermarket",
      "labor_hours": 4,
      "rental_days": 3,
      "pre_existing_damage_flags": [],
      "hidden_damage_likely": false
    },
    "fraud_analyst": {
      "completed_at": null,
      "agent_session": null,
      "risk_score": null,
      "risk_level": null,
      "flags": [],
      "soft_fraud": null,
      "recommendation": null
    },
    "senior_reviewer": {
      "completed_at": null,
      "agent_session": null,
      "decision": null,
      "decision_reasoning": null,
      "conditions": [],
      "escalated_to_human": false,
      "escalation_reason": null,
      "fcsp_timeline_check": null
    },
    "finance": {
      "completed_at": null,
      "agent_session": null,
      "payment_amount_usd": null,
      "deductible_applied_usd": null,
      "depreciation_applied_usd": null,
      "subrogation_candidate": false,
      "subrogation_target": null,
      "payment_method": null,
      "payment_reference": null,
      "supplement_eligible": null
    }
  },
  "audit_log": [
    {
      "timestamp": "2026-02-21T11:01:00Z",
      "agent": "router",
      "action": "claim_registered",
      "reasoning": "FNOL for low-speed parking lot collision with 4 passengers reporting injuries.",
      "regulation_reference": null
    },
    {
      "timestamp": "2026-02-21T11:06:00Z",
      "agent": "claims-officer",
      "action": "coverage_verified",
      "reasoning": "Policy active, collision coverage applies.",
      "regulation_reference": "FCSP Act"
    },
    {
      "timestamp": "2026-02-21T11:12:00Z",
      "agent": "assessor",
      "action": "estimate_completed",
      "reasoning": "Minor bumper damage only. Estimate $1,200 for scuffing and crack repair. Low-speed impact damage consistent with described incident.",
      "regulation_reference": null
    }
  ]
}
ENDJSON
)

# Set the claim_id
SEED_JSON=$(echo "$SEED_JSON" | jq --arg cid "$CLAIM_ID" '.claim_id = $cid')
TMP_SEED=$(mktemp)
echo "$SEED_JSON" > "$TMP_SEED"

# Phase 1: SEED
seed_claim "$CLAIM_ID" "$TMP_SEED" "telegram" "test-user-002"
rm "$TMP_SEED"

# Phase 2: INVOKE
TASK_MSG="Analyze fraud for claim $CLAIM_ID, user test-user-002. Assessment: estimate=1200, total_loss=false, pre-existing=[]. Read claim: bash /shared/scripts/db.sh get-claim $CLAIM_ID. History: bash /shared/scripts/db.sh list-claims-by-user test-user-002. Regulatory: flag and recommend only, do NOT deny. Steps: read claim, verify Assessor complete, analyze 7 fraud patterns, write results via db.sh, announce."

invoke_agent "fraud-analyst" "$TASK_MSG" 180

# Phase 3: VERIFY
log_step "VERIFY: Fraud Analyst (Suspicious Claim)"
PASS=0
TOTAL=0

TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.fraud_analyst.completed_at" "completed_at" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_not_null "$CLAIM_ID" ".pipeline.fraud_analyst.risk_score" "risk_score" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.fraud_analyst.risk_level" "low" "medium" "high" "critical" && PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1)); verify_in_set "$CLAIM_ID" ".pipeline.fraud_analyst.recommendation" "CLEAR" "INVESTIGATE" "REFER_SIU" && PASS=$((PASS + 1))

# For suspicious claim, we expect flags to be raised
TOTAL=$((TOTAL + 1)); verify_non_empty_array "$CLAIM_ID" ".pipeline.fraud_analyst.flags" "fraud flags" && PASS=$((PASS + 1))

# Dump full output
dump_agent_output "$CLAIM_ID" "fraud_analyst"

# Show the flags in detail
log_step "FRAUD FLAGS DETAIL"
get_claim "$CLAIM_ID" | jq '.pipeline.fraud_analyst.flags[]' 2>/dev/null

# Summary
print_summary "Fraud Analyst (Suspicious)" "$PASS" "$TOTAL"

log_info "Claim $CLAIM_ID left in DB for inspection."
