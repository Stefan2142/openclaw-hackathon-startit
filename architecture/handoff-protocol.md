# Hand-off Protocol Specification

Complete agent-to-agent transition specification for the Ohio Mutual Auto claims processing pipeline. Every transition is mediated by the Router agent -- pipeline agents never communicate directly. The claim JSON file (`shared/state/claims/<CLM-ID>.json`) is the single source of truth; agent sessions carry no inter-agent state.

**Reference Schema:** `shared/schemas/claim.schema.json`
**Orchestrator:** Router (depth-0 main agent, owns all state transitions)
**Pipeline Agents:** 6 depth-1 sub-agents spawned sequentially via `sessions_spawn`

---

## Announce Message Format

All pipeline agents use this normalized announce format when reporting back to the Router:

```
Status: SUCCESS | ERROR | ESCALATE
Summary: [What was accomplished in this stage]
Key findings: [Critical outputs that affect downstream processing]
Next recommended action: [What the Router should consider doing next]
```

**Router parsing rule:** The Router reads the `Status:` line first. If `SUCCESS`, proceed to validation. If `ERROR`, enter error handling. If `ESCALATE`, enter escalation protocol.

**Announce is best-effort:** If the OpenClaw gateway restarts mid-pipeline, pending announces are lost. The claim file on disk always reflects last known state, so recovery is possible by re-triggering from the last completed stage (check each `pipeline.<stage>.completed_at` field).

---

## Status State Machine

```
FNOL_RECEIVED --> COVERAGE_CHECKED --> ASSESSED --> FRAUD_ANALYZED --> REVIEWED --> PAYMENT_ISSUED
                       |                                                  |
                       +---> DENIED (coverage denial, skip Assessor)      +---> DENIED
                                                                          |
                                                                          +---> ESCALATED

Any stage can transition to ERROR or ESCALATED.
```

**Status ownership:** Only the Router sets the claim `status` field after validating each agent's announce and post-conditions. Pipeline agents write their section data but do not directly change the top-level `status` -- the Router reads the agent's announce and section data, validates, and then updates status.

---

## Transition 1: Router --> Front Desk

### Context
The Router receives an inbound claim (via WebChat, Slack, or CLI) and creates the initial claim record. Front Desk performs FNOL intake, categorization, completeness assessment, and priority assignment.

### Pre-spawn: What the Router Writes
Before spawning Front Desk, the Router:
1. Generates a claim ID in `CLM-YYYY-NNNNN` format
2. Creates the claim JSON file at `shared/state/claims/<CLM-ID>.json`
3. Populates root fields: `claim_id`, `status: "FNOL_RECEIVED"`, `submitted_at`, `updated_at`
4. Populates `claimant` section from inbound data (policy_id, name, contact info)
5. Populates `incident` section from inbound data (date, description, type, photos, witnesses)
6. Initializes all `pipeline` sections with null/empty defaults
7. Initializes `audit_log` with a `claim_registered` entry
8. Writes the file to disk

### Task Message
```
Process FNOL intake for auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json

Your role: Front Desk Agent -- FNOL intake specialist responsible for claim
categorization, completeness verification, and priority assignment.

Instructions:
1. Read the claim file
2. Verify claim has basic required fields (claimant, incident description, incident type)
3. Categorize the claim (standard collision, complex multi-vehicle, weather event, etc.)
4. Assess priority based on severity, injury involvement, and time sensitivity
5. Check for catastrophe event association if incident type is weather-related
6. Identify any missing information that would impede downstream processing
7. Write your results to pipeline.front_desk section
8. Set pipeline.front_desk.completed_at to current ISO 8601 timestamp
9. Record your session key in pipeline.front_desk.agent_session
10. Append an audit_log entry with your reasoning
11. Announce your result

Regulatory context:
- FNOL acknowledgment must occur within the regulatory window for the applicable
  jurisdiction; default to the most conservative standard
- Document all intake findings per FCSP Act requirements
```

### What Front Desk Reads
- Full claim JSON (root fields, claimant, incident)
- No external files required at this stage

### What Front Desk Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.front_desk.completed_at` | datetime | Processing completion timestamp |
| `pipeline.front_desk.agent_session` | string | OpenClaw session key for transcript retrieval |
| `pipeline.front_desk.category` | string | Claim category (e.g., "standard collision", "complex multi-vehicle", "weather event") |
| `pipeline.front_desk.priority` | enum | Priority level: low, normal, high, urgent |
| `pipeline.front_desk.cat_event` | string/null | CAT event ID if applicable (e.g., "CAT-2026-003-tornado") |
| `pipeline.front_desk.missing_info` | array | List of missing information items requiring follow-up |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:24:15Z",
  "agent": "front-desk",
  "action": "intake_completed",
  "reasoning": "Categorized as standard two-vehicle collision. Priority set to normal -- no injuries reported, no weather event. Police report number provided. All required information present for coverage verification.",
  "regulation_reference": null
}
```

### Post-condition Validation (Router checks)
Before spawning Claims Officer, the Router validates:
- [ ] `pipeline.front_desk.completed_at` is not null
- [ ] `pipeline.front_desk.category` is set (not null or empty)
- [ ] `pipeline.front_desk.priority` is one of: low, normal, high, urgent
- [ ] Announce status was `SUCCESS`

### Status Transition
Router sets: `status: "FNOL_RECEIVED"` (remains -- Front Desk does not change top-level status; Router advances to COVERAGE_CHECKED after spawning Claims Officer successfully)

### Error Path
- If Front Desk announces `ERROR` (e.g., claim data is too incomplete to categorize):
  - Router logs error in audit_log
  - Router retries once (re-spawns Front Desk with same claim)
  - If second attempt fails: Router sets status to `ERROR`, logs reason, stops pipeline
- If Front Desk announces `ESCALATE` (e.g., legal representation detected at intake):
  - Router sets status to `ESCALATED`
  - Router logs escalation reason in audit_log
  - Pipeline pauses for human resolution

---

## Transition 2: Front Desk --> Claims Officer (via Router)

### Context
Front Desk has completed intake. The Router spawns Claims Officer to verify policy coverage, check exclusions, and determine whether the claim is covered. This is the first critical decision point -- coverage denial terminates the standard path.

### Pre-spawn: Router Validation
Router confirms Transition 1 post-conditions are met (see above).

### Task Message
```
Verify coverage for auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json
Policy file: /absolute/path/shared/policies/<POLICY-ID>.json

Your role: Claims Officer -- coverage verification specialist responsible for
policy lookup, coverage confirmation, exclusion analysis, and denial documentation.

Instructions:
1. Read the claim file (note Front Desk's category and priority assessment)
2. Read the policy file for the claimant's policy
3. Verify the policy was active on the date of the incident
4. Determine which coverage type applies (collision, comprehensive, liability, UM/UIM)
5. Check all applicable exclusions against the incident circumstances
6. If covered: record deductible amount and coverage limit from policy
7. If not covered: document the specific exclusion or policy condition that applies
8. If coverage is ambiguous: resolve in the claimant's favor (ambiguity doctrine)
   OR flag for escalation if truly indeterminate
9. Write your results to pipeline.claims_officer section
10. Set pipeline.claims_officer.completed_at to current ISO 8601 timestamp
11. Record your session key in pipeline.claims_officer.agent_session
12. Append an audit_log entry with your reasoning
13. Announce your result

Regulatory context:
- Coverage denial must be communicated within the regulatory window for the
  applicable jurisdiction
- Document all exclusions checked per FCSP Act documentation requirements
- If coverage is ambiguous, the ambiguity doctrine generally favors the insured
- Record which policy sections were reviewed for audit trail compliance

Business context:
- Ohio Mutual's combined ratio target supports fair claims handling -- avoid
  unnecessary denials that create bad faith exposure
- Claims with minimal net payout after deductible may warrant direct payment
  consideration downstream
```

### What Claims Officer Reads
- Full claim JSON (all root fields + pipeline.front_desk section)
- Policy JSON from `shared/policies/<POLICY-ID>.json`

### What Claims Officer Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.claims_officer.completed_at` | datetime | Processing completion timestamp |
| `pipeline.claims_officer.agent_session` | string | OpenClaw session key |
| `pipeline.claims_officer.covered` | boolean/null | Coverage determination (true/false/null for uncertain) |
| `pipeline.claims_officer.policy_status` | enum | Policy status at time of incident: active, expired, cancelled, suspended |
| `pipeline.claims_officer.coverage_type` | string | Applicable coverage type (collision, comprehensive, liability, UM/UIM) |
| `pipeline.claims_officer.deductible_amount` | number/null | Applicable deductible in USD |
| `pipeline.claims_officer.coverage_limit` | number/null | Maximum coverage limit in USD |
| `pipeline.claims_officer.exclusions_checked` | array | List of exclusions reviewed with applicability notes |
| `pipeline.claims_officer.denial_reason` | string/null | If denied: specific policy language and exclusion |
| `pipeline.claims_officer.um_uim_route` | enum/null | UM/UIM routing if applicable |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:26:30Z",
  "agent": "claims-officer",
  "action": "coverage_verified",
  "reasoning": "Policy POL-AUT-98765 is active. Collision coverage applies with $500 deductible and $50,000 limit. Checked exclusions: racing (not applicable), intentional damage (not applicable), unauthorized driver (not applicable -- policyholder was driving). Claim is covered.",
  "regulation_reference": "FCSP Act: all exclusions must be documented when evaluated"
}
```

### Post-condition Validation (Router checks)
Before advancing, the Router validates:
- [ ] `pipeline.claims_officer.completed_at` is not null
- [ ] `pipeline.claims_officer.covered` is boolean (true or false) -- not null
- [ ] `pipeline.claims_officer.exclusions_checked` is non-empty array (due diligence)
- [ ] If `covered == false`: `denial_reason` is not null or empty
- [ ] Announce status was `SUCCESS`

### Status Transition
Router sets: `status: "COVERAGE_CHECKED"`

### Coverage Denial Shortcut Path
If `pipeline.claims_officer.covered == false`:
1. Router sets `status: "DENIED"`
2. Router logs denial in audit_log with reasoning from Claims Officer
3. Router skips Assessor, Fraud Analyst, and Finance stages
4. Router spawns Senior Reviewer with a modified task: "Review and document coverage denial for regulatory compliance and bad faith risk assessment"
5. Senior Reviewer reviews the denial reasoning, confirms or overrides, and documents the final decision
6. Pipeline terminates after Senior Reviewer (no Finance stage for denied claims)

This shortcut reflects real insurance operations: denied claims still need supervisory review to prevent bad faith exposure, but they do not need damage assessment or fraud analysis.

### Error Path
- If Claims Officer announces `ERROR` (e.g., policy file not found):
  - Router logs error, retries once
  - If policy truly missing: Router escalates (cannot proceed without policy data)
- If Claims Officer sets `covered = null` (uncertain):
  - Router treats as potential escalation
  - Router spawns Senior Reviewer for coverage determination before proceeding
- If Claims Officer announces `ESCALATE` (e.g., coverage ambiguity requires human judgment):
  - Standard escalation protocol

---

## Transition 3: Claims Officer --> Assessor (via Router)

### Context
Coverage is confirmed (`covered == true`). The Router spawns Assessor to estimate damage, determine total loss status, and recommend repair approach. This stage only runs for covered claims.

### Pre-spawn: Router Validation
Router confirms:
- Transition 2 post-conditions met
- `pipeline.claims_officer.covered == true` (if false, takes denial shortcut path)

### Task Message
```
Assess damage for auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json

Your role: Assessor -- damage estimation specialist responsible for repair
cost estimation, total loss determination, parts recommendation, and pre-existing
damage identification.

Instructions:
1. Read the claim file (note incident type, description, and photos)
2. Review any photos referenced in incident.photos (paths relative to shared/uploads/)
3. Estimate repair costs based on damage description and photos
4. Determine if the vehicle is a total loss (repair cost relative to ACV)
5. If total loss: estimate ACV and salvage value
6. If repairable: recommend OEM vs aftermarket parts based on vehicle age and mileage
7. Estimate labor hours and rental car days
8. Flag any indicators of pre-existing damage
9. Assess likelihood of hidden damage based on impact type
10. Write your results to pipeline.assessor section
11. Set pipeline.assessor.completed_at to current ISO 8601 timestamp
12. Record your session key in pipeline.assessor.agent_session
13. Append an audit_log entry with your reasoning
14. Announce your result

Assessment context:
- Total loss determination is a professional judgment comparing repair cost to ACV
  using the applicable jurisdiction's threshold standards
- OEM parts recommendation is a judgment call weighing vehicle age, mileage,
  safety considerations, and applicable guidelines
- Pre-existing damage flags are critical input for the downstream Fraud Analyst
- Coverage limit from Claims Officer: $<COVERAGE_LIMIT> USD
- Deductible: $<DEDUCTIBLE> USD
```

### What Assessor Reads
- Full claim JSON (root fields + pipeline.front_desk + pipeline.claims_officer)
- Photo files referenced in `incident.photos` (via path)

### What Assessor Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.assessor.completed_at` | datetime | Processing completion timestamp |
| `pipeline.assessor.agent_session` | string | OpenClaw session key |
| `pipeline.assessor.repair_estimate_usd` | number | Total repair cost estimate in USD |
| `pipeline.assessor.total_loss` | boolean | Whether vehicle is a total loss |
| `pipeline.assessor.acv_usd` | number/null | Actual Cash Value if total loss assessed |
| `pipeline.assessor.salvage_value_usd` | number/null | Salvage value if total loss |
| `pipeline.assessor.parts_recommendation` | enum | OEM or aftermarket |
| `pipeline.assessor.labor_hours` | number | Estimated labor hours |
| `pipeline.assessor.rental_days` | integer/null | Estimated rental car days |
| `pipeline.assessor.pre_existing_damage_flags` | array | Pre-existing damage indicators |
| `pipeline.assessor.hidden_damage_likely` | boolean/null | Hidden damage likelihood |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:29:00Z",
  "agent": "assessor",
  "action": "estimate_completed",
  "reasoning": "Front bumper, hood, and radiator support damaged in frontal collision. Repair estimate $8,450 (parts $4,200 + labor 18 hrs at $85/hr + paint $1,420 + materials $800). Vehicle ACV approximately $22,000 -- repair cost is 38% of ACV, well below total loss threshold. Recommending aftermarket parts for bumper cover (vehicle is 5 years old, 62,000 miles), OEM for radiator support (safety-critical structural component). No pre-existing damage indicators observed. Hidden damage likely given frontal impact -- supplement may be needed.",
  "regulation_reference": null
}
```

### Post-condition Validation (Router checks)
- [ ] `pipeline.assessor.completed_at` is not null
- [ ] `pipeline.assessor.repair_estimate_usd` is a positive number
- [ ] `pipeline.assessor.total_loss` is boolean (not null)
- [ ] If `total_loss == true`: `acv_usd` and `salvage_value_usd` are set
- [ ] Announce status was `SUCCESS`

### Status Transition
Router sets: `status: "ASSESSED"`

### Error Path
- If Assessor announces `ERROR` (e.g., no photos and insufficient damage description):
  - Router logs error, retries once with enriched task context
  - If still insufficient: Router escalates for human assessment
- If Assessor announces `ESCALATE` (e.g., total loss on a high-value vehicle):
  - Standard escalation protocol

---

## Transition 4: Assessor --> Fraud Analyst (via Router)

### Context
Damage assessment is complete. The Router spawns Fraud Analyst to evaluate the entire claim history for fraud indicators. The Fraud Analyst has read access to all prior stages, enabling cross-referencing between incident description, coverage details, and damage assessment.

### Pre-spawn: Router Validation
Router confirms Transition 3 post-conditions met.

### Task Message
```
Analyze fraud risk for auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json

Your role: Fraud Analyst -- fraud detection specialist responsible for risk
scoring, pattern matching, indicator analysis, and SIU referral recommendation.

Instructions:
1. Read the full claim file (all prior stage results are relevant)
2. Analyze for known fraud patterns:
   - Staged accident indicators (timing, location, circumstances)
   - Phantom passenger claims (claimed injuries without corroboration)
   - Inflated repair estimates (compare Assessor's estimate to incident severity)
   - Prior damage claimed as new (check Assessor's pre_existing_damage_flags)
   - VIN/vehicle switching indicators
   - Suspicious timing (recent policy changes, coverage additions)
3. Assess indicator convergence -- isolated flags are notes, converging indicators
   warrant investigation, pattern matches warrant SIU referral
4. Distinguish between soft fraud (exaggeration of legitimate claim) and hard fraud
   (fabricated claim)
5. Assign a risk score reflecting indicator convergence strength (not probability)
6. Make a recommendation: CLEAR, INVESTIGATE, or REFER_SIU
7. Write your results to pipeline.fraud_analyst section
8. Set pipeline.fraud_analyst.completed_at to current ISO 8601 timestamp
9. Record your session key in pipeline.fraud_analyst.agent_session
10. Append an audit_log entry with your reasoning
11. Announce your result

Fraud analysis context:
- You are a flag-and-escalate system, not detect-and-deny
- Your recommendation informs the Senior Reviewer's decision; you do not
  directly approve or deny claims
- Document every indicator checked, even those that came back clean --
  thoroughness is part of the audit trail
- False positives on legitimate claims create bad faith exposure; false
  negatives allow fraud losses -- balance appropriately
```

### What Fraud Analyst Reads
- Full claim JSON (all root fields + all prior pipeline sections)
- Cross-references: incident description vs damage estimate, timing patterns, coverage details

### What Fraud Analyst Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.fraud_analyst.completed_at` | datetime | Processing completion timestamp |
| `pipeline.fraud_analyst.agent_session` | string | OpenClaw session key |
| `pipeline.fraud_analyst.risk_score` | integer 0-100 | Indicator convergence strength |
| `pipeline.fraud_analyst.risk_level` | enum | low, medium, high, critical |
| `pipeline.fraud_analyst.flags` | array of objects | Each with pattern, description, severity |
| `pipeline.fraud_analyst.soft_fraud` | boolean/null | Soft fraud indicators present |
| `pipeline.fraud_analyst.recommendation` | enum | CLEAR, INVESTIGATE, REFER_SIU |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:31:45Z",
  "agent": "fraud-analyst",
  "action": "fraud_analysis_completed",
  "reasoning": "Analyzed claim for 7 fraud pattern categories. No staged accident indicators -- police report corroborates collision with identified other party. No phantom passenger indicators -- no injury claims filed. Repair estimate of $8,450 is consistent with described frontal collision damage to a mid-size sedan. No pre-existing damage flags from Assessor. No suspicious timing patterns (policy active for 3+ years, no recent coverage changes). Risk score: 12 (low -- isolated minor flag for missing witness contact info, but this is common in legitimate claims). Recommendation: CLEAR.",
  "regulation_reference": null
}
```

### Post-condition Validation (Router checks)
- [ ] `pipeline.fraud_analyst.completed_at` is not null
- [ ] `pipeline.fraud_analyst.risk_score` is integer between 0 and 100
- [ ] `pipeline.fraud_analyst.risk_level` is one of: low, medium, high, critical
- [ ] `pipeline.fraud_analyst.recommendation` is one of: CLEAR, INVESTIGATE, REFER_SIU
- [ ] Announce status was `SUCCESS` or `ESCALATE`

### Status Transition
Router sets: `status: "FRAUD_ANALYZED"`

### Routing Decision After Fraud Analysis
The Router applies judgment based on the Fraud Analyst's outputs:

- **recommendation == CLEAR**: Proceed to Senior Reviewer normally
- **recommendation == INVESTIGATE**: Proceed to Senior Reviewer with an enriched task message flagging the fraud concerns for scrutiny
- **recommendation == REFER_SIU**: Router evaluates severity:
  - If `risk_level == "critical"`: Router may set status to `ESCALATED` immediately and pause for human review before Senior Reviewer
  - If `risk_level == "high"`: Router proceeds to Senior Reviewer with SIU referral flagged in the task message; Senior Reviewer decides whether to escalate

### Error Path
- If Fraud Analyst announces `ERROR`:
  - Router logs error, retries once
  - If repeat failure: Router proceeds to Senior Reviewer with a note that fraud analysis was inconclusive (pipeline should not block on fraud analysis failure)
- If Fraud Analyst announces `ESCALATE`:
  - Router sets status to `ESCALATED`
  - Router logs escalation with fraud findings in audit_log
  - Pipeline pauses for human resolution

---

## Transition 5: Fraud Analyst --> Senior Reviewer (via Router)

### Context
Fraud analysis is complete. The Router spawns Senior Reviewer as the final decision authority. Senior Reviewer weighs all prior stages, checks FCSP timeline compliance, and makes the claim decision. This agent is the last checkpoint before payment.

### Pre-spawn: Router Validation
Router confirms Transition 4 post-conditions met.

### Task Message
```
Review and decide on auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json

Your role: Senior Reviewer -- final decision authority responsible for weighing
all pipeline evidence, ensuring regulatory compliance, and making the claim decision.

Instructions:
1. Read the full claim file (all prior stage results)
2. Review Front Desk's categorization and completeness assessment
3. Review Claims Officer's coverage determination and exclusion analysis
4. Review Assessor's damage estimate and total loss determination
5. Review Fraud Analyst's risk assessment and recommendation
6. Check FCSP timeline compliance:
   - Calculate elapsed time from submitted_at to now
   - Verify acknowledgment deadline has been met
   - Verify decision is within the applicable regulatory window
   - Record timeline check in pipeline.senior_reviewer.fcsp_timeline_check
7. Make your decision: APPROVED, DENIED, CONDITIONAL, or ESCALATE_HUMAN
8. Document your reasoning thoroughly -- this is the decision that must be
   defensible in regulatory review
9. If escalating to human: set escalated_to_human = true and document why
10. Write your results to pipeline.senior_reviewer section
11. Set pipeline.senior_reviewer.completed_at to current ISO 8601 timestamp
12. Record your session key in pipeline.senior_reviewer.agent_session
13. Append an audit_log entry with your reasoning
14. Announce your result

Decision context:
- You are the final quality gate before payment
- Your decision must be supportable by the evidence in the claim file
- If fraud was flagged: weigh the evidence carefully -- a fraud flag alone
  is not grounds for denial; the underlying evidence must support the decision
- If the claim approaches regulatory deadlines: factor urgency into your
  decision timeline
- Conditional approvals must specify clear, achievable conditions

Fraud context from pipeline:
- Risk score: <RISK_SCORE>
- Risk level: <RISK_LEVEL>
- Recommendation: <RECOMMENDATION>
- Flags: <FLAG_SUMMARY>
```

### What Senior Reviewer Reads
- Full claim JSON (all root fields + all 4 prior pipeline sections)
- Complete audit_log history

### What Senior Reviewer Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.senior_reviewer.completed_at` | datetime | Processing completion timestamp |
| `pipeline.senior_reviewer.agent_session` | string | OpenClaw session key |
| `pipeline.senior_reviewer.decision` | enum | APPROVED, DENIED, CONDITIONAL, ESCALATE_HUMAN |
| `pipeline.senior_reviewer.decision_reasoning` | string | Detailed reasoning referencing evidence and regulations |
| `pipeline.senior_reviewer.conditions` | array | Conditions for CONDITIONAL approval |
| `pipeline.senior_reviewer.escalated_to_human` | boolean | Whether human escalation was triggered |
| `pipeline.senior_reviewer.escalation_reason` | string/null | Reason for escalation |
| `pipeline.senior_reviewer.fcsp_timeline_check` | object | Timeline compliance verification |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:34:20Z",
  "agent": "senior-reviewer",
  "action": "decision_approved",
  "reasoning": "All pipeline stages completed successfully. Coverage verified under collision coverage with $500 deductible. Repair estimate of $8,450 is reasonable for described damage. Fraud risk score 12 (low) with no converging indicators -- recommendation CLEAR. FCSP timeline: claim submitted 14 minutes ago, well within all regulatory windows. Decision: APPROVED for payment of repair estimate minus deductible. No conditions required.",
  "regulation_reference": "FCSP Act: decision communicated within regulatory window; all prior stage evidence reviewed and documented"
}
```

### Post-condition Validation (Router checks)
- [ ] `pipeline.senior_reviewer.completed_at` is not null
- [ ] `pipeline.senior_reviewer.decision` is one of: APPROVED, DENIED, CONDITIONAL, ESCALATE_HUMAN
- [ ] `pipeline.senior_reviewer.decision_reasoning` is not null or empty
- [ ] If `decision == CONDITIONAL`: `conditions` is non-empty array
- [ ] If `decision == ESCALATE_HUMAN`: `escalated_to_human == true` and `escalation_reason` is set
- [ ] `pipeline.senior_reviewer.fcsp_timeline_check` is populated
- [ ] Announce status was `SUCCESS` or `ESCALATE`

### Status Transition
Router sets based on decision:
- `APPROVED` or `CONDITIONAL` --> `status: "REVIEWED"` (proceed to Finance)
- `DENIED` --> `status: "DENIED"` (pipeline terminates, Router announces denial)
- `ESCALATE_HUMAN` --> `status: "ESCALATED"` (pipeline pauses for human)

### Routing Decision After Senior Review
- **decision == APPROVED**: Spawn Finance for payment processing
- **decision == CONDITIONAL**: Spawn Finance with conditions noted; Finance calculates payment but marks it as pending conditions
- **decision == DENIED**: Pipeline terminates. Router updates status to DENIED, logs final audit entry, announces denial outcome to requester
- **decision == ESCALATE_HUMAN**: Standard escalation protocol. Pipeline pauses.

### Error Path
- If Senior Reviewer announces `ERROR`:
  - Router logs error, retries once with full claim context
  - If repeat failure: Router escalates (a Senior Reviewer failure is critical)
- If Senior Reviewer announces `ESCALATE`:
  - Standard escalation protocol

---

## Transition 6: Senior Reviewer --> Finance (via Router)

### Context
Senior Reviewer has approved (or conditionally approved) the claim. The Router spawns Finance to calculate the final payment, apply deductible and depreciation, assess subrogation candidacy, and record the payment disbursement.

### Pre-spawn: Router Validation
Router confirms:
- Transition 5 post-conditions met
- `pipeline.senior_reviewer.decision` is `APPROVED` or `CONDITIONAL`
- If `DENIED` or `ESCALATE_HUMAN`: Finance is NOT spawned

### Task Message
```
Process payment for auto insurance claim <CLM-ID>.

Claim file: /absolute/path/shared/state/claims/<CLM-ID>.json

Your role: Finance Agent -- payment processing specialist responsible for
final payment calculation, deductible application, depreciation assessment,
subrogation evaluation, and payment record creation.

Instructions:
1. Read the full claim file (all prior stage results)
2. Determine payment basis:
   - If total loss: payment = ACV - deductible - salvage adjustment
   - If repairable: payment = repair estimate - deductible - applicable depreciation
3. Apply the deductible from Claims Officer's coverage determination
4. Apply depreciation if applicable (parts depreciation for older vehicles)
5. Verify payment does not exceed coverage limit
6. Assess subrogation candidacy:
   - If other party is at fault and has insurance: flag as subrogation candidate
   - Record target insurer information for recovery
7. Determine payment method
8. Generate a payment reference number (mock for hackathon demo)
9. Assess supplement eligibility (if Assessor flagged hidden damage)
10. Write your results to pipeline.finance section
11. Set pipeline.finance.completed_at to current ISO 8601 timestamp
12. Record your session key in pipeline.finance.agent_session
13. Append an audit_log entry with your reasoning
14. Announce your result

Payment context:
- Senior Reviewer decision: <DECISION>
- Conditions (if CONDITIONAL): <CONDITIONS>
- Repair estimate: $<REPAIR_ESTIMATE> USD
- Deductible: $<DEDUCTIBLE> USD
- Coverage limit: $<COVERAGE_LIMIT> USD
- Total loss: <TOTAL_LOSS>

Regulatory context:
- Payment must be issued within the regulatory window after claim acceptance
- Document the complete payment calculation for audit trail compliance
- Subrogation rights must be preserved by proper documentation
```

### What Finance Reads
- Full claim JSON (all root fields + all 5 prior pipeline sections)
- Specifically: Assessor's repair estimate, Claims Officer's deductible/limit, Senior Reviewer's decision

### What Finance Writes
| Field | Type | Description |
|-------|------|-------------|
| `pipeline.finance.completed_at` | datetime | Processing completion timestamp |
| `pipeline.finance.agent_session` | string | OpenClaw session key |
| `pipeline.finance.payment_amount_usd` | number | Final payment after all deductions |
| `pipeline.finance.deductible_applied_usd` | number | Deductible deducted |
| `pipeline.finance.depreciation_applied_usd` | number | Depreciation deducted |
| `pipeline.finance.subrogation_candidate` | boolean | Whether subrogation applies |
| `pipeline.finance.subrogation_target` | string/null | Target insurer for recovery |
| `pipeline.finance.payment_method` | enum | direct_deposit, check, repair_shop_direct |
| `pipeline.finance.payment_reference` | string | Payment transaction reference |
| `pipeline.finance.supplement_eligible` | boolean/null | Eligible for supplement if hidden damage found |

### Audit Log Entry
```json
{
  "timestamp": "2026-02-21T10:36:00Z",
  "agent": "finance",
  "action": "payment_issued",
  "reasoning": "Payment calculated: repair estimate $8,450 minus $500 deductible = $7,950. No depreciation applied (parts recommendation includes mix of OEM and aftermarket, already accounted for in estimate). Payment within coverage limit of $50,000. Subrogation candidate: yes -- other party (John Smith, insured by State Farm policy SF-12345) was at fault per police report. Payment method: direct deposit. Supplement eligible: yes, Assessor flagged hidden damage likely. Payment reference: PAY-2026-00001.",
  "regulation_reference": "FCSP Act: payment issued within regulatory window after approval"
}
```

### Post-condition Validation (Router checks)
- [ ] `pipeline.finance.completed_at` is not null
- [ ] `pipeline.finance.payment_amount_usd` is a non-negative number
- [ ] `pipeline.finance.payment_amount_usd` <= `pipeline.claims_officer.coverage_limit`
- [ ] `pipeline.finance.deductible_applied_usd` == `pipeline.claims_officer.deductible_amount`
- [ ] `pipeline.finance.payment_reference` is not null or empty
- [ ] Announce status was `SUCCESS`

### Status Transition
Router sets: `status: "PAYMENT_ISSUED"`

### Pipeline Completion
After Finance completes successfully:
1. Router verifies all 6 pipeline sections have `completed_at` timestamps
2. Router sets final `status: "PAYMENT_ISSUED"`
3. Router writes a final audit_log entry: `pipeline_completed`
4. Router announces the outcome to the original requester channel with a summary

### Error Path
- If Finance announces `ERROR` (e.g., payment calculation inconsistency):
  - Router logs error, retries once
  - If repeat failure: Router escalates (payment errors are critical)
- Finance should NOT announce `ESCALATE` under normal operation (the Senior Reviewer already approved); if it does, Router treats it as an error requiring human attention

---

## Cross-Cutting Protocols

### Retry Protocol
Applied by the Router when any pipeline agent announces `ERROR`:

1. **First failure**: Log error in audit_log, re-spawn the same agent with identical task message
2. **Second failure**: Log repeated error, set claim status to `ERROR`, stop pipeline
3. **Max retries per stage**: 2 (original attempt + 1 retry)
4. **No retry delay**: Re-spawn is immediate (sessions_spawn is non-blocking)

### Escalation Protocol
Applied by the Router when any pipeline agent announces `ESCALATE`:

1. Router reads the claim file to identify escalation details
2. Router sets `pipeline.senior_reviewer.escalated_to_human = true` (if not already set by the announcing agent)
3. Router sets `status: "ESCALATED"`
4. Router writes escalation audit_log entry with: trigger agent, reason, claim state at escalation time
5. Router stops spawning further pipeline stages
6. Claim file remains on disk in ESCALATED status
7. Human resolves by sending a message to the Router session
8. Router updates claim with human decision and resumes pipeline from escalation point

### Audit Log Protocol
Every pipeline agent appends to `audit_log[]` with:

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | Yes | ISO 8601 timestamp |
| `agent` | Yes | Agent ID (router, front-desk, claims-officer, assessor, fraud-analyst, senior-reviewer, finance) |
| `action` | Yes | Action identifier (claim_registered, intake_completed, coverage_verified, coverage_denied, estimate_completed, fraud_analysis_completed, fraud_flags_raised, decision_approved, decision_denied, decision_escalated, payment_issued, pipeline_completed, error_logged, escalation_triggered) |
| `reasoning` | Yes | Human-readable explanation of why this action was taken |
| `regulation_reference` | No | Applicable regulation citation if action has regulatory implications |

The audit log is append-only. Agents must never modify or delete existing entries. The Router also writes entries for state transitions, errors, and pipeline-level events.

### Timeout Protocol
Each pipeline agent has a `runTimeoutSeconds` configured in the spawn call:

| Agent | Timeout | Rationale |
|-------|---------|-----------|
| front-desk | 60s | Intake categorization is fast |
| claims-officer | 90s | Policy lookup and exclusion analysis |
| assessor | 120s | Photo analysis and detailed estimation |
| fraud-analyst | 90s | Pattern matching across full claim history |
| senior-reviewer | 90s | Final decision requiring full context reasoning |
| finance | 60s | Payment calculation is deterministic |

If an agent exceeds its timeout, the announce returns with `Status: timeout`. The Router treats this as an ERROR and applies the retry protocol.

---

## Summary: Complete Transition Map

```
   Router                                        Pipeline Agents
   ------                                        ---------------

   [Receive claim]
   |
   +-- Write initial CLM-ID.json (status: FNOL_RECEIVED)
   |
   +-- Validate: file created, required fields present
   |
   +-- sessions_spawn(front-desk) ----------------> [Front Desk]
   |                                                  Reads: claim JSON
   |                                                  Writes: pipeline.front_desk
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: front_desk.completed_at, category set
   |
   +-- sessions_spawn(claims-officer) ------------> [Claims Officer]
   |                                                  Reads: claim + policy JSON
   |                                                  Writes: pipeline.claims_officer
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: claims_officer.completed_at, covered is boolean
   |
   +-- [IF covered == false] --> DENIAL SHORTCUT PATH
   |     +-- status: DENIED
   |     +-- spawn Senior Reviewer for denial review only
   |     +-- Pipeline terminates (no Assessor, Fraud, Finance)
   |
   +-- [IF covered == true] --> Continue pipeline
   |
   +-- sessions_spawn(assessor) ------------------> [Assessor]
   |                                                  Reads: claim JSON + photos
   |                                                  Writes: pipeline.assessor
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: assessor.completed_at, repair_estimate > 0
   |
   +-- sessions_spawn(fraud-analyst) -------------> [Fraud Analyst]
   |                                                  Reads: full claim JSON
   |                                                  Writes: pipeline.fraud_analyst
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: fraud_analyst.completed_at, risk_score, recommendation
   |
   +-- [IF REFER_SIU + critical] --> May ESCALATE before Senior Reviewer
   |
   +-- sessions_spawn(senior-reviewer) -----------> [Senior Reviewer]
   |                                                  Reads: full claim JSON
   |                                                  Writes: pipeline.senior_reviewer
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: senior_reviewer.completed_at, decision set
   |
   +-- [IF DENIED] --> status: DENIED, pipeline terminates
   +-- [IF ESCALATE_HUMAN] --> status: ESCALATED, pipeline pauses
   +-- [IF APPROVED/CONDITIONAL] --> Continue
   |
   +-- sessions_spawn(finance) -------------------> [Finance]
   |                                                  Reads: full claim JSON
   |                                                  Writes: pipeline.finance
   |   <-- announce: SUCCESS/ERROR/ESCALATE ------    Announces: result
   |
   +-- Validate: finance.completed_at, payment_amount, payment_reference
   |
   +-- status: PAYMENT_ISSUED
   +-- Final audit_log entry: pipeline_completed
   +-- Announce outcome to requester
```

---

*Hand-off protocol for: Ohio Mutual Auto -- Multi-Agent Claims Processing Pipeline*
*Reference: shared/schemas/claim.schema.json*
