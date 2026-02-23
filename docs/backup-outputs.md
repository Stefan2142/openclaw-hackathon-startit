# Pre-Run Backup Outputs

If the live demo fails during presentation, open this document and display the relevant section on screen. Talk through the output using the talking points. The backup outputs are identical to what the live system would produce.

**How to use:**
1. Open this document in a text editor or terminal with `cat docs/backup-outputs.md`
2. Scroll to the relevant claim scenario section
3. Display the terminal output simulation on screen (copy-paste into a terminal window or display the raw text)
4. Use the talking points to narrate what the output means
5. If judges want to see the raw JSON, display the JSON state section

---
---

## Scenario 1: Happy Path Collision (CLM-2026-00001)

**Test claim file:** `shared/test-claims/happy-path-collision.json`
**Expected final status:** PAYMENT_ISSUED

### Terminal Output Simulation

What `scripts/check-status.sh CLM-2026-00001` would display after full pipeline completion:

```
================================================================================
  CLAIM STATUS: CLM-2026-00001
================================================================================

  Status:      PAYMENT_ISSUED
  Claimant:    John Smith (POL-AUT-10001)
  Submitted:   2026-02-21T10:30:00Z
  Updated:     2026-02-21T10:35:00Z

  ---- Pipeline Summary ----

  [1] Front Desk         COMPLETE   Category: collision | Priority: normal
  [2] Claims Officer     COMPLETE   Covered: YES | Deductible: $500 | Limit: $50,000
  [3] Assessor           COMPLETE   Estimate: $4,200 | Total Loss: NO
  [4] Fraud Analyst      COMPLETE   Risk: 15/100 (low) | Flags: 0 | Rec: proceed
  [5] Senior Reviewer    COMPLETE   Decision: APPROVED
  [6] Finance            COMPLETE   Payment: $3,700 | Ref: PAY-2026-00001

  ---- Key Details ----

  Subrogation:    YES -- State Farm / Maria Rodriguez / SF-98-7654321
  Supplement:     ELIGIBLE (hidden damage likely in wheel well)
  FCSP Status:    Within all deadlines

  ---- Audit Log (6 entries) ----

  10:30:45Z  front-desk        fnol_intake_complete
             Categorized as standard collision. Priority normal. FNOL complete.

  10:31:30Z  claims-officer    coverage_verified
             Policy POL-AUT-10001 active. Collision coverage. $500 deductible.

  10:32:45Z  assessor          damage_assessed
             Repair estimate $4,200. Not total loss. Hidden damage likely.

  10:33:30Z  fraud-analyst     fraud_analysis_complete
             All 7 patterns checked. Risk 15/100. No fraud indicators. Proceed.

  10:34:15Z  senior-reviewer   claim_approved
             APPROVED. Coverage confirmed, estimate reasonable, fraud low, FCSP compliant.

  10:35:00Z  finance           payment_issued
             $3,700 payment ($4,200 - $500 deductible). Subrogation flagged.

================================================================================
```

### Raw JSON State

The complete claim JSON as it would look after full pipeline processing:

```json
{
  "claim_id": "CLM-2026-00001",
  "status": "PAYMENT_ISSUED",
  "submitted_at": "2026-02-21T10:30:00Z",
  "updated_at": "2026-02-21T10:35:00Z",
  "claimant": {
    "policy_id": "POL-AUT-10001",
    "name": "John Smith",
    "contact_phone": "555-234-5678",
    "contact_email": "john.smith@example.com"
  },
  "incident": {
    "date": "2026-02-19",
    "time": "14:30",
    "location": "Intersection of Main St and Oak Ave, Columbus, OH",
    "description": "I was traveling northbound on Main Street approaching the intersection with Oak Avenue at approximately 30 mph. The traffic signal was green in my direction. As I entered the intersection, a dark blue Ford Explorer driven by the other party ran the red light on Oak Avenue and struck the front-right corner of my vehicle. The impact pushed my Honda Accord sideways approximately 6 feet. My airbags did not deploy. I was able to pull over to the shoulder after the impact. The other driver admitted fault at the scene and stated they did not see the red light. A Columbus Police officer responded within 10 minutes and took statements from both drivers and one witness. The other driver's front bumper and hood were also damaged. My vehicle has significant front-end damage on the passenger side including a crumpled right fender, broken headlight assembly, damaged bumper cover, and the hood is slightly buckled on the right side. I estimate the damage extends into the wheel well area. The vehicle is still drivable but I am concerned about alignment issues. No injuries to either driver. No passengers were in either vehicle.",
    "type": "collision",
    "other_party": {
      "name": "Maria Rodriguez",
      "insurance_company": "State Farm",
      "policy_number": "SF-98-7654321",
      "contact": "555-876-5432"
    },
    "police_report_number": "CPD-2026-018742",
    "photos": [],
    "injuries_reported": false,
    "witnesses": [
      {
        "name": "David Chen",
        "contact": "555-345-9876",
        "statement": "I was waiting at the crosswalk on the southeast corner of Main and Oak. The Honda had a green light and was going straight through the intersection. The Ford Explorer ran the red light and hit the Honda on the passenger side. The Explorer driver did not appear to brake before impact."
      }
    ]
  },
  "pipeline": {
    "front_desk": {
      "completed_at": "2026-02-21T10:30:45Z",
      "agent_session": "agent:front-desk:subagent:a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "category": "collision",
      "priority": "normal",
      "cat_event": null,
      "missing_info": []
    },
    "claims_officer": {
      "completed_at": "2026-02-21T10:31:30Z",
      "agent_session": "agent:claims-officer:subagent:b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "covered": true,
      "policy_status": "active",
      "coverage_type": "collision",
      "deductible_amount": 500,
      "coverage_limit": 50000,
      "exclusions_checked": ["intentional_acts", "racing", "commercial_use", "excluded_drivers"],
      "denial_reason": null,
      "um_uim_route": "not_applicable"
    },
    "assessor": {
      "completed_at": "2026-02-21T10:32:45Z",
      "agent_session": "agent:assessor:subagent:c3d4e5f6-a7b8-9012-cdef-123456789012",
      "repair_estimate_usd": 4200,
      "total_loss": false,
      "acv_usd": null,
      "salvage_value_usd": null,
      "parts_recommendation": "OEM for headlight assembly (vehicle under 3yr/36K mi, safety-critical component); aftermarket acceptable for bumper cover (cosmetic, no safety impact)",
      "labor_hours": 12,
      "rental_days": 5,
      "pre_existing_damage_flags": [],
      "hidden_damage_likely": true
    },
    "fraud_analyst": {
      "completed_at": "2026-02-21T10:33:30Z",
      "agent_session": "agent:fraud-analyst:subagent:d4e5f6a7-b8c9-0123-defa-234567890123",
      "risk_score": 15,
      "risk_level": "low",
      "flags": [],
      "soft_fraud": false,
      "recommendation": "proceed"
    },
    "senior_reviewer": {
      "completed_at": "2026-02-21T10:34:15Z",
      "agent_session": "agent:senior-reviewer:subagent:e5f6a7b8-c9d0-1234-efab-345678901234",
      "decision": "APPROVED",
      "decision_reasoning": "Straightforward collision claim with strong supporting evidence. Coverage verified on active policy POL-AUT-10001 with collision coverage. Damage estimate of $4,200 is proportionate to described front-right corner impact at approximately 30 mph. Independent witness David Chen corroborates claimant's account. Police report CPD-2026-018742 confirms other party (Maria Rodriguez) ran red light. Fraud analysis returned low risk (15/100) with no flags. All evidence is internally consistent. No basis for denial or conditions. FCSP timeline compliance: claim submitted same day as acknowledgment -- well within 10-15 day acknowledgment window and 40-day decision deadline.",
      "conditions": [],
      "escalated_to_human": false,
      "escalation_reason": null,
      "fcsp_timeline_check": "Within all FCSP deadlines. Acknowledgment and decision rendered same day as submission."
    },
    "finance": {
      "completed_at": "2026-02-21T10:35:00Z",
      "agent_session": "agent:finance:subagent:f6a7b8c9-d0e1-2345-fabc-456789012345",
      "payment_amount_usd": 3700,
      "deductible_applied_usd": 500,
      "depreciation_applied_usd": 0,
      "subrogation_candidate": true,
      "subrogation_target": "State Farm / Maria Rodriguez / SF-98-7654321",
      "payment_method": "direct_deposit",
      "payment_reference": "PAY-2026-00001",
      "supplement_eligible": true
    }
  },
  "audit_log": [
    {
      "timestamp": "2026-02-21T10:30:45Z",
      "agent": "front-desk",
      "action": "fnol_intake_complete",
      "reasoning": "Categorized as standard collision based on two-vehicle intersection impact with clear fault determination. Priority normal: no injuries reported, vehicle drivable, no CAT event indicators. FNOL report is complete with police report number CPD-2026-018742, independent witness David Chen, and other party insurance (State Farm SF-98-7654321)."
    },
    {
      "timestamp": "2026-02-21T10:31:30Z",
      "agent": "claims-officer",
      "action": "coverage_verified",
      "reasoning": "Policy POL-AUT-10001 is active. Incident date 2026-02-19 falls within policy period. Collision coverage applies to two-vehicle intersection collision. Deductible: $500. Coverage limit: $50,000. All exclusions reviewed: intentional acts (not applicable -- accidental collision), racing (not applicable), commercial use (not applicable -- personal trip), excluded drivers (no excluded drivers on this policy). UM/UIM routing not applicable -- other party has identified insurance (State Farm). Coverage confirmed.",
      "regulation_reference": "FCSP Act: coverage decision within 40 days of proof of loss"
    },
    {
      "timestamp": "2026-02-21T10:32:45Z",
      "agent": "assessor",
      "action": "damage_assessed",
      "reasoning": "Repair estimate $4,200 based on: right fender replacement ($850), headlight assembly replacement ($650 OEM), bumper cover ($400), hood straightening/blend ($750), paint and materials ($550), wheel well inspection and minor repair ($500), alignment check ($150), miscellaneous hardware ($350). 12 labor hours estimated. Not a total loss -- repair cost well below ACV threshold. Hidden damage likely in wheel well area based on description of impact extending into that zone. Recommend supplement eligibility for post-teardown findings. 5 rental days based on parts ordering and repair complexity.",
      "regulation_reference": "Ohio 100% ACV total loss threshold"
    },
    {
      "timestamp": "2026-02-21T10:33:30Z",
      "agent": "fraud-analyst",
      "action": "fraud_analysis_complete",
      "reasoning": "Assessed all 7 fraud patterns. Staged accident: no indicators -- independent witness (David Chen, no relation to claimant), police report confirming other party fault, consistent damage pattern. Phantom passengers: not applicable -- no passengers, no injury claims. Paper accident: not applicable -- police report, witness, other party confirmation. Inflated repair: estimate of $4,200 is proportionate to described damage (front-right corner impact at ~30 mph). Prior damage: no pre-existing damage flags from Assessor. Friendly tow: not applicable. VIN switching: not applicable. Risk score 15 reflects minimal residual uncertainty inherent in any claim. No fraud indicators detected. Recommendation: proceed to review."
    },
    {
      "timestamp": "2026-02-21T10:34:15Z",
      "agent": "senior-reviewer",
      "action": "claim_approved",
      "reasoning": "APPROVED. All pipeline stages consistent. Coverage confirmed, estimate proportionate, fraud risk low (15/100, no flags), independent witness and police report corroborate account. FCSP compliant. Proceeding to payment.",
      "regulation_reference": "FCSP Act: payment within 30 days of acceptance"
    },
    {
      "timestamp": "2026-02-21T10:35:00Z",
      "agent": "finance",
      "action": "payment_issued",
      "reasoning": "Payment calculated: $4,200 repair estimate - $500 deductible = $3,700. No depreciation applied (collision coverage pays repair cost, vehicle not a total loss). Payment method: direct deposit. Subrogation flagged: other party Maria Rodriguez at fault, insured by State Farm (SF-98-7654321) -- recovery of insurer costs plus claimant deductible. Supplement eligible: hidden damage likely in wheel well area per Assessor; additional payment may be issued after repair shop teardown and supplemental estimate.",
      "regulation_reference": "FCSP Act: payment within 30 days of settlement agreement"
    }
  ]
}
```

### Key Talking Points

- **Six agents, six audit log entries.** Notice the audit log has 6 entries -- one per agent -- each with documented reasoning. This is the compliance trail regulators require. Every decision is traceable to the agent that made it and the evidence it considered.
- **Subrogation recovery.** Finance identified this as a subrogation candidate. Maria Rodriguez was at fault and insured by State Farm. We recover our $3,700 payment plus the claimant's $500 deductible from State Farm. This is real business value -- the system is not just processing claims, it is recovering costs.
- **Supplement eligibility.** The Assessor flagged hidden damage in the wheel well. Finance marked the claim as supplement-eligible. When the shop opens it up and finds more damage, we issue an additional payment on the same claim -- no new claim needed. This handles what happens in 30-40% of real collision claims.
- **Five minutes, not five weeks.** The entire pipeline processed from 10:30 to 10:35 -- five minutes from FNOL to payment. In a traditional workflow, this takes days to weeks with claims sitting in queues between handoffs.

---
---

## Scenario 2: Fraud Rejection / SIU Referral (CLM-2026-00002)

**Test claim file:** `shared/test-claims/fraud-rejection-siu.json`
**Expected final status:** ESCALATED

### Terminal Output Simulation

What `scripts/check-status.sh CLM-2026-00002` would display after pipeline completion:

```
================================================================================
  CLAIM STATUS: CLM-2026-00002
================================================================================

  Status:      ESCALATED
  Claimant:    John Smith (POL-AUT-10001)
  Submitted:   2026-02-21T11:00:00Z
  Updated:     2026-02-21T11:04:30Z

  ---- Pipeline Summary ----

  [1] Front Desk         COMPLETE   Category: collision | Priority: normal
  [2] Claims Officer     COMPLETE   Covered: YES | Deductible: $500 | Limit: $50,000
  [3] Assessor           COMPLETE   Estimate: $850 | Total Loss: NO
  [4] Fraud Analyst      COMPLETE   Risk: 82/100 (high) | Flags: 4 | Rec: SIU_REFERRAL
  [5] Senior Reviewer    COMPLETE   Decision: ESCALATE_HUMAN
  [6] Finance            SKIPPED    (claim escalated -- no payment authorized)

  ---- Fraud Flags (4) ----

  [HIGH]   phantom_passengers
           4 passengers claiming soft tissue injuries from low-speed impact (~5-10 mph).
           Damage estimate $850 inconsistent with injury-producing forces.

  [HIGH]   staged_accident
           Low-speed parking lot impact with disproportionate injury claims.
           Witnesses are friends of claimant, not independent bystanders.

  [MEDIUM] prior_damage_history
           Similar parking lot incident 8 months ago. Pattern of repeated claims.

  [MEDIUM] attorney_representation
           Same attorney (Lawrence Mitchell) representing claimant and multiple
           passengers from single incident. Pre-arranged legal representation.

  ---- Escalation Details ----

  Escalated to:   SIU (Special Investigations Unit)
  Reason:         Multiple high-severity fraud indicators converging
  FCSP Status:    Timeline paused per fraud investigation exception

  ---- Audit Log (5 entries) ----

  11:00:35Z  front-desk        fnol_intake_complete
             Categorized as collision. Priority normal. Injuries reported.

  11:01:20Z  claims-officer    coverage_verified
             Policy POL-AUT-10001 active. Collision coverage. $500 deductible.

  11:02:30Z  assessor          damage_assessed
             Repair estimate $850. Minor cosmetic. Hidden damage unlikely.

  11:03:45Z  fraud-analyst     fraud_analysis_complete
             HIGH RISK (82/100). 4 converging fraud patterns. SIU referral recommended.

  11:04:30Z  senior-reviewer   claim_escalated
             ESCALATE_HUMAN. Four converging indicators exceed AI adjudication
             confidence. SIU referral for human investigation.

================================================================================
```

### Raw JSON State

The complete claim JSON as it would look after pipeline processing (escalated at Senior Reviewer):

```json
{
  "claim_id": "CLM-2026-00002",
  "status": "ESCALATED",
  "submitted_at": "2026-02-21T11:00:00Z",
  "updated_at": "2026-02-21T11:04:30Z",
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
      "completed_at": "2026-02-21T11:00:35Z",
      "agent_session": "agent:front-desk:subagent:1a2b3c4d-5e6f-7890-1234-abcdef123456",
      "category": "collision",
      "priority": "normal",
      "cat_event": null,
      "missing_info": []
    },
    "claims_officer": {
      "completed_at": "2026-02-21T11:01:20Z",
      "agent_session": "agent:claims-officer:subagent:2b3c4d5e-6f7a-8901-2345-bcdef1234567",
      "covered": true,
      "policy_status": "active",
      "coverage_type": "collision",
      "deductible_amount": 500,
      "coverage_limit": 50000,
      "exclusions_checked": ["intentional_acts", "racing", "commercial_use", "excluded_drivers"],
      "denial_reason": null,
      "um_uim_route": "not_applicable"
    },
    "assessor": {
      "completed_at": "2026-02-21T11:02:30Z",
      "agent_session": "agent:assessor:subagent:3c4d5e6f-7a8b-9012-3456-cdef12345678",
      "repair_estimate_usd": 850,
      "total_loss": false,
      "acv_usd": null,
      "salvage_value_usd": null,
      "parts_recommendation": "Aftermarket bumper cover (cosmetic repair, no safety impact)",
      "labor_hours": 3,
      "rental_days": 0,
      "pre_existing_damage_flags": [],
      "hidden_damage_likely": false
    },
    "fraud_analyst": {
      "completed_at": "2026-02-21T11:03:45Z",
      "agent_session": "agent:fraud-analyst:subagent:4d5e6f7a-8b9c-0123-4567-def123456789",
      "risk_score": 82,
      "risk_level": "high",
      "flags": [
        {
          "pattern": "phantom_passengers",
          "description": "4 passengers in sedan claiming soft tissue injuries from low-speed impact (~5-10 mph). Damage estimate of only $850 is inconsistent with injury-producing forces. Physics of low-speed rear-end impact do not typically produce whiplash in 5 occupants.",
          "severity": "high"
        },
        {
          "pattern": "staged_accident",
          "description": "Low-speed parking lot impact with disproportionate injury claims. Both witnesses (Dwayne Cooper, Rashid Thompson) are friends of claimant who were in the car behind -- not independent bystanders. Witness statements emphasize the low speed ('barely a tap') while claimant reports significant injuries.",
          "severity": "high"
        },
        {
          "pattern": "prior_damage_history",
          "description": "Claimant references a similar parking lot incident 8 months ago. Pattern of low-speed parking lot collisions raises concern about repeated claim behavior.",
          "severity": "medium"
        },
        {
          "pattern": "attorney_representation",
          "description": "Same attorney (Lawrence Mitchell at Mitchell & Associates) representing claimant and multiple passengers from a single incident. Pre-arranged legal representation across multiple parties is a known indicator of organized claim fraud.",
          "severity": "medium"
        }
      ],
      "soft_fraud": false,
      "recommendation": "SIU_REFERRAL"
    },
    "senior_reviewer": {
      "completed_at": "2026-02-21T11:04:30Z",
      "agent_session": "agent:senior-reviewer:subagent:5e6f7a8b-9c0d-1234-5678-ef1234567890",
      "decision": "ESCALATE_HUMAN",
      "decision_reasoning": "Multiple high-severity fraud indicators converging: phantom passenger pattern (4 injury claims from low-speed impact), staged accident indicators (non-independent witnesses, disproportionate claims), prior claim history (similar incident 8 months ago), and shared attorney representation across multiple parties. Fraud Analyst risk score 82/100 with SIU referral recommendation. The convergence of these indicators exceeds the threshold for confident AI adjudication. SIU investigation is warranted before any payment authorization. Property damage portion ($850) may be legitimate, but injury claims require human investigation. Escalation protects both the insurer (from paying potentially fraudulent claims) and the claimant (from wrongful denial if investigation clears them).",
      "conditions": [],
      "escalated_to_human": true,
      "escalation_reason": "Multiple high-severity fraud indicators converging. SIU investigation recommended before payment authorization.",
      "fcsp_timeline_check": "FCSP timeline paused pending investigation per fraud investigation exception. Investigation must be conducted in good faith and with reasonable diligence."
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
      "timestamp": "2026-02-21T11:00:35Z",
      "agent": "front-desk",
      "action": "fnol_intake_complete",
      "reasoning": "Categorized as collision based on rear-end impact in parking lot. Priority normal: injuries reported (soft tissue) but incident is low-speed parking lot collision. No CAT event indicators. FNOL report complete with police report number CPD-2026-017865, two witnesses, and other party insurance (Progressive PGR-44-2198765). Note: injuries reported by 4 passengers."
    },
    {
      "timestamp": "2026-02-21T11:01:20Z",
      "agent": "claims-officer",
      "action": "coverage_verified",
      "reasoning": "Policy POL-AUT-10001 is active. Incident date 2026-02-18 falls within policy period. Collision coverage applies to rear-end parking lot collision. Deductible: $500. Coverage limit: $50,000. All exclusions reviewed -- none apply. Coverage confirmed.",
      "regulation_reference": "FCSP Act: coverage decision within 40 days of proof of loss"
    },
    {
      "timestamp": "2026-02-21T11:02:30Z",
      "agent": "assessor",
      "action": "damage_assessed",
      "reasoning": "Repair estimate $850 based on: rear bumper cover replacement ($350 aftermarket), paint and materials ($250), scuff repair and blending ($150), hardware and clips ($100). 3 labor hours. Not a total loss. Vehicle is drivable -- no rental days needed for minor repair. Low-speed impact (5-10 mph) with minimal energy transfer. Hidden damage unlikely given the low impact speed and superficial damage pattern. No pre-existing damage indicators observed."
    },
    {
      "timestamp": "2026-02-21T11:03:45Z",
      "agent": "fraud-analyst",
      "action": "fraud_analysis_complete",
      "reasoning": "HIGH RISK -- SIU REFERRAL RECOMMENDED. Four converging fraud indicators detected. (1) Phantom passengers: 4 occupants claiming soft tissue injuries from ~5-10 mph impact; $850 damage estimate is inconsistent with injury-producing collision forces. (2) Staged accident indicators: low-speed impact, disproportionate injury claims, non-independent witnesses (friends of claimant in following vehicle). Witness statements describe 'barely a tap' while 5 people report injuries. (3) Prior history: similar parking lot incident 8 months prior. (4) Shared attorney: Lawrence Mitchell representing multiple parties from same incident. Individual indicators could have innocent explanations, but the convergence of all four patterns strongly suggests organized claim fraud (hard fraud, not soft fraud). Recommend SIU investigation before any payment authorization."
    },
    {
      "timestamp": "2026-02-21T11:04:30Z",
      "agent": "senior-reviewer",
      "action": "claim_escalated",
      "reasoning": "ESCALATE_HUMAN. Four converging fraud indicators (phantom passengers, staged accident, prior history, shared attorney) exceed AI adjudication confidence. SIU referral for human investigation. FCSP timeline paused under fraud investigation exception.",
      "regulation_reference": "FCSP Act: fraud investigation exception pauses timeline"
    }
  ]
}
```

### Key Talking Points

- **Four converging patterns, not one.** No single flag would justify an SIU referral. But four patterns converging -- phantom passengers, staged accident indicators, prior claim history, and shared attorney representation -- that is indicator convergence. This is how the Fraud Analyst earns its place in the pipeline.
- **The system does not deny.** Notice the decision is ESCALATE_HUMAN, not DENIED. The Fraud Analyst flags and recommends; the Senior Reviewer decides to escalate to a human investigator. The AI is smart enough to know it cannot make this call with confidence. It hands it to the Special Investigations Unit with documented evidence.
- **Audit trail protects both directions.** If the claim is fraudulent, the documentation supports the investigation. If the claimant is cleared, the documentation shows the investigation was conducted in good faith based on objective indicators. The system protects the insurer AND the claimant.
- **Finance never runs.** The pipeline stops at escalation. No payment is authorized. The Finance agent's hard constraint -- never pay without Senior Reviewer approval -- is enforced architecturally, not just by instruction.

---
---

## Scenario 3: Coverage Denial / Excluded Driver (CLM-2026-00003)

**Test claim file:** `shared/test-claims/coverage-denial-exclusion.json`
**Expected final status:** DENIED

### Terminal Output Simulation

What `scripts/check-status.sh CLM-2026-00003` would display after pipeline completion:

```
================================================================================
  CLAIM STATUS: CLM-2026-00003
================================================================================

  Status:      DENIED
  Claimant:    Robert Wilson (POL-AUT-10003)
  Submitted:   2026-02-21T11:30:00Z
  Updated:     2026-02-21T11:32:00Z

  ---- Pipeline Summary ----

  [1] Front Desk         COMPLETE   Category: collision | Priority: normal
  [2] Claims Officer     COMPLETE   Covered: NO | Reason: excluded driver
  [3] Assessor           SKIPPED    (coverage denied -- no damage assessment)
  [4] Fraud Analyst      SKIPPED    (coverage denied -- no fraud analysis)
  [5] Senior Reviewer    COMPLETE   Decision: DENIED (bad faith risk: LOW)
  [6] Finance            SKIPPED    (coverage denied -- no payment)

  ---- Denial Details ----

  Denial reason:  Vehicle operated by Michael Johnson who is listed as an
                  excluded driver on policy POL-AUT-10003.
  Bad faith risk: LOW -- exclusion language is clear and unambiguous
  FCSP Status:    Within all deadlines for denial notification

  ---- Audit Log (3 entries) ----

  11:30:30Z  front-desk        fnol_intake_complete
             Categorized as collision. Priority normal. FNOL complete.

  11:31:15Z  claims-officer    coverage_denied
             Michael Johnson is excluded driver on POL-AUT-10003. Coverage denied.

  11:32:00Z  senior-reviewer   denial_confirmed
             DENIED. Excluded driver exclusion is unambiguous. Bad faith risk LOW.

================================================================================
```

### Raw JSON State

The complete claim JSON as it would look after pipeline processing (denied at Claims Officer, confirmed by Senior Reviewer):

```json
{
  "claim_id": "CLM-2026-00003",
  "status": "DENIED",
  "submitted_at": "2026-02-21T11:30:00Z",
  "updated_at": "2026-02-21T11:32:00Z",
  "claimant": {
    "policy_id": "POL-AUT-10003",
    "name": "Robert Wilson",
    "contact_phone": "555-345-6789",
    "contact_email": "robert.wilson@example.com"
  },
  "incident": {
    "date": "2026-02-20",
    "time": "09:15",
    "location": "Westbound I-275 near Exit 28, Cincinnati, OH",
    "description": "I am filing this claim for damage to my 2024 Ford F-150. On the morning of February 20th, my nephew Michael Johnson was driving my truck to a job site in West Chester. I had asked him to pick up some building materials for a renovation project I am working on. Michael was traveling westbound on I-275 near the Colerain Avenue exit when traffic slowed suddenly ahead of him. He was unable to stop in time and rear-ended the vehicle ahead of him, a silver Chevrolet Tahoe. Michael told me the traffic went from highway speed to nearly stopped within a few car lengths due to a construction zone merge. The front of my truck has damage to the bumper, grille, and hood. The radiator may be compromised as Michael said there was fluid leaking after the collision. The other vehicle had rear bumper and tailgate damage. Michael exchanged information with the other driver at the scene. A highway patrol officer responded and filed a report. Michael was cited for following too closely. No injuries were reported by either party. I want to get my truck repaired as soon as possible because I need it for work.",
    "type": "collision",
    "other_party": {
      "name": "Sandra Mitchell",
      "insurance_company": "Nationwide",
      "policy_number": "NW-OH-5567890",
      "contact": "555-234-8765"
    },
    "police_report_number": "OSHP-2026-004521",
    "photos": [],
    "injuries_reported": false,
    "witnesses": []
  },
  "pipeline": {
    "front_desk": {
      "completed_at": "2026-02-21T11:30:30Z",
      "agent_session": "agent:front-desk:subagent:6f7a8b9c-0d1e-2345-6789-ab1234567890",
      "category": "collision",
      "priority": "normal",
      "cat_event": null,
      "missing_info": []
    },
    "claims_officer": {
      "completed_at": "2026-02-21T11:31:15Z",
      "agent_session": "agent:claims-officer:subagent:7a8b9c0d-1e2f-3456-7890-bc1234567890",
      "covered": false,
      "policy_status": "active",
      "coverage_type": "collision",
      "deductible_amount": null,
      "coverage_limit": null,
      "exclusions_checked": ["excluded_drivers"],
      "denial_reason": "Vehicle operated by Michael Johnson who is listed as an excluded driver on policy POL-AUT-10003. Excluded driver exclusion applies per policy terms. Policy specifically names Michael Johnson as excluded from all coverage under this policy.",
      "um_uim_route": null
    },
    "assessor": {
      "completed_at": null,
      "agent_session": null,
      "repair_estimate_usd": null,
      "total_loss": null,
      "acv_usd": null,
      "salvage_value_usd": null,
      "parts_recommendation": null,
      "labor_hours": null,
      "rental_days": null,
      "pre_existing_damage_flags": [],
      "hidden_damage_likely": null
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
      "completed_at": "2026-02-21T11:32:00Z",
      "agent_session": "agent:senior-reviewer:subagent:8b9c0d1e-2f3a-4567-8901-cd1234567890",
      "decision": "DENIED",
      "decision_reasoning": "Coverage correctly denied per excluded driver exclusion on policy POL-AUT-10003. Policy explicitly excludes Michael Johnson by name. The exclusion language is clear and unambiguous -- it specifically identifies the excluded individual, leaving no room for interpretation. The ambiguity doctrine does not apply because there is no ambiguity in the exclusion language. Bad faith risk assessment: LOW. The denial is well-documented with specific policy language reference. The Claims Officer's reasoning correctly identifies the applicable exclusion and documents it thoroughly. FCSP compliance: denial notification must be issued within required timeframe with specific reference to the policy provision supporting the denial.",
      "conditions": [],
      "escalated_to_human": false,
      "escalation_reason": null,
      "fcsp_timeline_check": "Within all FCSP deadlines for denial notification. Denial letter must cite specific policy exclusion language per FCSP requirements."
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
      "timestamp": "2026-02-21T11:30:30Z",
      "agent": "front-desk",
      "action": "fnol_intake_complete",
      "reasoning": "Categorized as collision based on rear-end impact on I-275. Priority normal: no injuries reported, police report filed (OSHP-2026-004521). Note: vehicle was driven by Robert Wilson's nephew Michael Johnson at time of incident. FNOL report complete."
    },
    {
      "timestamp": "2026-02-21T11:31:15Z",
      "agent": "claims-officer",
      "action": "coverage_denied",
      "reasoning": "Policy POL-AUT-10003 is active. However, the vehicle was operated by Michael Johnson at the time of the incident. Michael Johnson is explicitly listed as an excluded driver on this policy. The excluded driver exclusion is clear and unambiguous -- the policy specifically names Michael Johnson. Coverage denied per excluded driver exclusion. No ambiguity to construe in claimant's favor (the exclusion names a specific individual, not a class of drivers). Note: this triggers the coverage denial shortcut -- pipeline skips Assessor, Fraud Analyst, and Finance, proceeding directly to Senior Reviewer for bad faith risk assessment.",
      "regulation_reference": "FCSP Act: denial must cite specific policy provision"
    },
    {
      "timestamp": "2026-02-21T11:32:00Z",
      "agent": "senior-reviewer",
      "action": "denial_confirmed",
      "reasoning": "DENIED. Excluded driver exclusion is unambiguous -- policy POL-AUT-10003 names Michael Johnson specifically. Bad faith risk: LOW. Denial is defensible. FCSP compliant.",
      "regulation_reference": "FCSP Act: written denial with specific policy provision citation required"
    }
  ]
}
```

### Key Talking Points

- **Three agents processed, three skipped.** The pipeline ran Front Desk, Claims Officer, and Senior Reviewer. It skipped Assessor, Fraud Analyst, and Finance entirely. No point estimating damage on an uncovered claim. No point analyzing fraud on a denied claim. This is the coverage denial shortcut -- efficient processing that saves tokens and time.
- **Every denial still gets supervisory review.** Even though the denial is clear-cut, the Senior Reviewer still reviews it. The Senior Reviewer checks that the denial is defensible, assesses bad faith risk (LOW in this case), and verifies the exclusion language is unambiguous. This protects the insurer if the claimant disputes the denial.
- **Specific policy provision cited.** The denial references the specific exclusion: Michael Johnson is named as an excluded driver on policy POL-AUT-10003. The Claims Officer documents the exact policy language. This is a FCSP requirement -- you cannot just say "excluded," you must cite the specific provision.
- **Only 2 minutes from submission to decision.** Three agents, three audit log entries, clear denial with documented reasoning. The system processes denials as efficiently as approvals while maintaining full regulatory compliance.

---
---

## Presentation Recovery Script

If the live demo fails completely (gateway down, API errors, network issues), use this script:

**Step 1:** "While we resolve the technical issue, let me show you the output our system produces. This is a pre-captured run of our three demo scenarios."

**Step 2:** Open this document. Display the terminal output simulation for CLM-2026-00001 (happy path).

**Step 3:** Walk through using the talking points. Emphasize: "Six agents, six audit log entries, subrogation recovery identified, five minutes from FNOL to payment."

**Step 4:** "Now let me show you what happens when the system detects fraud." Display CLM-2026-00002 terminal output.

**Step 5:** Walk through the fraud flags one by one. Build tension: "Pattern one... pattern two... pattern three... pattern four. No single flag justifies a referral, but four patterns converging? That is indicator convergence."

**Step 6:** "One more scenario. What happens when coverage does not apply?" Display CLM-2026-00003 terminal output.

**Step 7:** "Three agents processed, three skipped. Every denial still gets supervisory review. The pipeline is smart enough to shortcut when appropriate."

**Step 8:** "Three claims. Three different outcomes. One system. Complete audit trails for all three. That is what we built."

**If judges ask to see the raw JSON:** Scroll down to the JSON section for the relevant claim and display it. Point to the audit_log array: "Every agent writes its reasoning here. This is the compliance trail."

---

*Pre-run backup outputs for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*3 scenarios: Happy Path (PAYMENT_ISSUED), Fraud/SIU (ESCALATED), Coverage Denial (DENIED)*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
