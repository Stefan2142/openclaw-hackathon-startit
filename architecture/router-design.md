# Router/Orchestrator Design

The Router is the depth-0 main agent that owns the claim lifecycle. It receives claim submissions, creates initial claim records, spawns pipeline agents sequentially, validates stage outputs, and handles errors and escalations. All orchestration logic lives in the Router's AGENTS.md -- no external orchestration service exists.

---

## 1. State Machine

### Status Transitions

```
                              (from any stage)
                             +-> ESCALATED
                             |
                             +-> ERROR
                             |
FNOL_RECEIVED --> COVERAGE_CHECKED --> ASSESSED --> FRAUD_ANALYZED --> REVIEWED --> PAYMENT_ISSUED
                       |                                                  |
                       +-> DENIED                                         +-> DENIED
```

### Complete Transition Table

| From | To | Trigger | Router Validation Before Spawn |
|------|-----|---------|-------------------------------|
| FNOL_RECEIVED | COVERAGE_CHECKED | front-desk announces SUCCESS | pipeline.front_desk.completed_at is set, category and priority are populated |
| COVERAGE_CHECKED | ASSESSED | claims-officer announces SUCCESS, covered=true | pipeline.claims_officer.completed_at is set, covered=true, deductible_amount and coverage_limit populated |
| COVERAGE_CHECKED | DENIED | claims-officer announces SUCCESS, covered=false | pipeline.claims_officer.denial_reason is populated, coverage denial is documented |
| ASSESSED | FRAUD_ANALYZED | assessor announces SUCCESS | pipeline.assessor.completed_at is set, repair_estimate_usd or total_loss populated |
| FRAUD_ANALYZED | REVIEWED | fraud-analyst announces SUCCESS | pipeline.fraud_analyst.completed_at is set, risk_score and recommendation populated |
| REVIEWED | PAYMENT_ISSUED | senior-reviewer announces SUCCESS, decision=APPROVED | pipeline.senior_reviewer.decision is APPROVED, finance completes payment |
| REVIEWED | DENIED | senior-reviewer announces SUCCESS, decision=DENIED | pipeline.senior_reviewer.decision is DENIED, decision_reasoning populated |
| Any stage | ESCALATED | Any agent announces ESCALATE | escalated_to_human=true set on the relevant pipeline section |
| Any stage | ERROR | Agent timeout or repeated failure | Max retries (2) exhausted for the stage |

### Terminal States

- **PAYMENT_ISSUED**: Claim settled, payment disbursed. Pipeline complete.
- **DENIED**: Claim denied at coverage check or senior review. Pipeline terminates with documented reason.
- **ESCALATED**: Claim paused awaiting human adjuster review. Router stops pipeline. Can resume after human resolution.
- **ERROR**: Unrecoverable agent failure. Router logs error, stops pipeline. Requires manual intervention.

### Early Termination Logic

The Router checks for early termination after claims-officer completes:

1. If `covered=false` -- Router sets status to DENIED, writes audit log entry citing denial reason, and announces final outcome. Does NOT spawn assessor or subsequent stages.
2. If `covered=true` but `um_uim_route` is set -- Router includes UM/UIM routing context in subsequent stage task messages.

---

## 2. Sequential Spawn Pattern (Announce-Wait-Read-Spawn)

### The Cycle

The Router follows this exact cycle for each pipeline stage:

```
1. ANNOUNCE intent (write audit_log entry: "spawning {agent} for {claim_id}")
2. SPAWN agent via sessions_spawn
3. WAIT for announce message from spawned agent
4. READ updated claim JSON file
5. VALIDATE stage output fields are complete and well-formed
6. DECIDE next action: proceed / retry / escalate / terminate
7. SPAWN next agent (repeat from step 1)
```

### sessions_spawn Call Format

For each pipeline stage, the Router calls sessions_spawn with these parameters:

```json
{
  "agentId": "{pipeline-agent-id}",
  "task": "{constructed task message -- see section 3}",
  "runTimeoutSeconds": "{per-stage timeout -- see section 4}"
}
```

The call returns immediately with:

```json
{
  "status": "accepted",
  "runId": "{uuid}",
  "childSessionKey": "agent:{agentId}:subagent:{uuid}"
}
```

The Router then waits for the announce message to arrive in its own session. The announce is the sub-agent's final output.

### Stage-by-Stage Spawn Sequence

**Stage 1: Front Desk (front-desk)**
- Router writes initial claim JSON to `shared/state/claims/{CLAIM_ID}.json` with status=FNOL_RECEIVED
- Spawns front-desk with claim file path
- Waits for announce
- Validates: category, priority, completed_at populated
- If SUCCESS: proceeds to Stage 2

**Stage 2: Claims Officer (claims-officer)**
- Router reads updated claim (status should now reflect front-desk completion)
- Constructs task message with claim file path AND policy file path
- Spawns claims-officer
- Waits for announce
- Validates: covered, deductible_amount, coverage_limit, exclusions_checked populated
- If covered=true: proceeds to Stage 3
- If covered=false: sets status=DENIED, terminates pipeline

**Stage 3: Assessor (assessor)**
- Router constructs task with claim file path
- Includes coverage context (deductible, limit) from claims-officer results
- Spawns assessor
- Waits for announce
- Validates: repair_estimate_usd or (total_loss=true + acv_usd + salvage_value_usd) populated
- If SUCCESS: proceeds to Stage 4

**Stage 4: Fraud Analyst (fraud-analyst)**
- Router constructs task with claim file path
- Includes assessment summary context for fraud cross-referencing
- Spawns fraud-analyst
- Waits for announce
- Validates: risk_score, risk_level, recommendation populated
- If recommendation=REFER_SIU: sets status=ESCALATED, stops pipeline
- If recommendation=INVESTIGATE or CLEAR: proceeds to Stage 5 with fraud context

**Stage 5: Senior Reviewer (senior-reviewer)**
- Router constructs task with claim file path
- Includes fraud analysis summary and any special flags
- Spawns senior-reviewer
- Waits for announce
- Validates: decision, decision_reasoning populated
- If decision=APPROVED: proceeds to Stage 6
- If decision=DENIED: sets status=DENIED, terminates pipeline
- If decision=ESCALATE_HUMAN: sets status=ESCALATED, stops pipeline
- If decision=CONDITIONAL: proceeds to Stage 6 with conditions noted

**Stage 6: Finance (finance)**
- Router constructs task with claim file path
- Includes approved payment parameters (estimate, deductible, conditions)
- Spawns finance
- Waits for announce
- Validates: payment_amount_usd, payment_reference populated
- If SUCCESS: sets status=PAYMENT_ISSUED, announces final outcome

---

## 3. Task Message Template

The Router constructs a task message for each sessions_spawn call. The template ensures every agent receives consistent context.

### Generic Template

```
Process auto insurance claim {CLAIM_ID}.

Claim file: {ABSOLUTE_PATH}/shared/state/claims/{CLAIM_ID}.json
{ADDITIONAL_FILE_REFERENCES}

{STAGE_SPECIFIC_CONTEXT}

Regulatory context:
{REGULATORY_INJECTION}

Instructions:
1. Read the claim file
2. Verify prior stage ({PRIOR_STAGE}) is complete (check pipeline.{PRIOR_SECTION}.completed_at)
3. Perform your analysis per AGENTS.md
4. Write results to pipeline.{YOUR_SECTION}
5. Append audit_log entry with reasoning
6. Update status to {NEXT_STATUS}
```

### Stage-Specific Task Messages

**Front Desk:**
```
Process auto insurance claim CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json

This is a new FNOL submission. No prior stages exist.

Regulatory context:
- FCSP Act: Acknowledge receipt within 15 business days
- Document all information provided and identify any gaps

Instructions:
1. Read the claim file
2. Categorize the claim type and set priority
3. Identify any missing information the claimant should provide
4. Write results to pipeline.front_desk
5. Append audit_log entry with your intake reasoning
6. Update status to COVERAGE_CHECKED
```

**Claims Officer:**
```
Process coverage verification for CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json
Policy file: /opt/ohio-mutual/shared/policies/POL-AUT-10001.json

Regulatory context:
- Ohio: Coverage denial must be communicated within 15 business days
- Document all exclusions checked per FCSP Act Section 2695.7(b)
- If coverage is ambiguous, resolve in claimant's favor (ambiguity doctrine)
- Ohio Mutual combined ratio target is 95% -- avoid unnecessary denials

Instructions:
1. Read the claim file
2. Verify prior stage (front-desk) is complete (check pipeline.front_desk.completed_at)
3. Read the policy file and verify coverage
4. Check all applicable exclusions
5. Write results to pipeline.claims_officer
6. Append audit_log entry with coverage reasoning
7. Update status to ASSESSED (if covered) or DENIED (if not covered)
```

**Assessor:**
```
Process damage assessment for CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json

Coverage context:
- Deductible: ${DEDUCTIBLE} (from claims_officer)
- Coverage limit: ${COVERAGE_LIMIT} (from claims_officer)
- Coverage type: ${COVERAGE_TYPE}

Regulatory context:
- Ohio total loss threshold: when repair cost exceeds 70-75% of ACV
- OEM vs aftermarket: professional judgment based on vehicle age, mileage, safety criticality
- Document all estimation methodology for audit trail

Instructions:
1. Read the claim file
2. Verify prior stage (claims-officer) is complete (check pipeline.claims_officer.completed_at)
3. Assess damage from description and photos
4. Write results to pipeline.assessor
5. Append audit_log entry with assessment reasoning
6. Update status to FRAUD_ANALYZED
```

**Fraud Analyst:**
```
Process fraud analysis for CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json

Assessment context:
- Repair estimate: ${REPAIR_ESTIMATE} (from assessor)
- Total loss: ${TOTAL_LOSS} (from assessor)
- Pre-existing damage flags: ${PRE_EXISTING_FLAGS}

Regulatory context:
- Ohio SIU referral: required when converging fraud indicators present
- Soft fraud (inflation) vs hard fraud (fabrication) distinction matters for response
- Document every flag raised with evidence basis

Instructions:
1. Read the claim file
2. Verify prior stage (assessor) is complete (check pipeline.assessor.completed_at)
3. Analyze for fraud patterns
4. Write results to pipeline.fraud_analyst
5. Append audit_log entry with fraud analysis reasoning
6. Update status to REVIEWED
```

**Senior Reviewer:**
```
Process final review for CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json

Fraud context:
- Risk score: ${RISK_SCORE}/100 (from fraud_analyst)
- Risk level: ${RISK_LEVEL}
- Recommendation: ${FRAUD_RECOMMENDATION}
- Flags: ${FLAG_SUMMARY}

Regulatory context:
- FCSP Act: decision must be communicated within 30 business days of claim filing
- Document decision reasoning thoroughly -- this is the defensible decision record
- Escalate to human if: high fraud risk, complex coverage question, bad faith risk
- Ohio bad faith exposure: unreasonable denial triggers 2x damages + attorney fees

Instructions:
1. Read the claim file
2. Verify prior stage (fraud-analyst) is complete (check pipeline.fraud_analyst.completed_at)
3. Weigh all evidence and make final decision
4. Write results to pipeline.senior_reviewer
5. Append audit_log entry with decision reasoning
6. Update status to PAYMENT_ISSUED (if approving) or DENIED (if denying)
```

**Finance:**
```
Process payment for CLM-2026-00001.

Claim file: /opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json

Approval context:
- Decision: ${DECISION} (from senior_reviewer)
- Conditions: ${CONDITIONS}
- Repair estimate: ${REPAIR_ESTIMATE}
- Deductible: ${DEDUCTIBLE}
- Coverage limit: ${COVERAGE_LIMIT}

Regulatory context:
- FCSP Act: payment must be issued within 30 business days of approval
- Subrogation: flag if other party at fault for recovery opportunity
- Document payment calculation for audit trail

Instructions:
1. Read the claim file
2. Verify prior stage (senior-reviewer) is complete (check pipeline.senior_reviewer.completed_at)
3. Calculate payment (estimate minus deductible minus depreciation, capped at coverage limit)
4. Write results to pipeline.finance
5. Append audit_log entry with payment calculation reasoning
6. Update status to PAYMENT_ISSUED
```

---

## 4. Error Handling and Retry Policy

### Per-Stage Timeouts

| Agent | runTimeoutSeconds | Rationale |
|-------|-------------------|-----------|
| front-desk | 60 | FNOL intake is structured data extraction -- fast |
| claims-officer | 90 | Policy lookup and exclusion analysis requires careful reading |
| assessor | 120 | Damage estimation from descriptions/photos is the most complex reasoning task |
| fraud-analyst | 90 | Pattern matching against claim data requires thorough analysis |
| senior-reviewer | 90 | Final decision requires weighing all prior evidence |
| finance | 60 | Payment calculation is arithmetic + record writing -- fast |

### Retry Policy

- **Max retries per stage:** 2 (total attempts = 3 including original)
- **Retry delay:** None (re-spawn is immediate)
- **After max retries exhausted:** Set status=ERROR, write detailed error to audit_log, stop pipeline
- **Retry resets:** Each retry gets a fresh session -- no carryover of failed state

### Announce Parsing

The Router parses the announce message from each sub-agent. The expected format:

```
Status: success | error | timeout | unknown
Result: [summary of work done]
Notes: [any errors, warnings, or important context]
```

**Router action by status:**

| Announce Status | Router Action |
|----------------|---------------|
| success | Read claim file, validate output, proceed to next stage |
| error | Increment retry counter, re-spawn if under limit, ERROR if over |
| timeout | Increment retry counter, re-spawn with +30s timeout, ERROR if over limit |
| unknown | Treat as error, increment retry counter |
| ESCALATE | Set status=ESCALATED, log reason, stop pipeline, notify human |

### Escalation Triggers

Each pipeline agent may announce ESCALATE instead of SUCCESS. The Router handles all escalations uniformly:

1. Read claim file to find escalation_reason
2. Set claim status to ESCALATED
3. Write audit_log entry: "Pipeline paused -- escalated to human adjuster. Reason: {reason}"
4. Stop spawning further stages
5. Announce escalation to the originating channel

**Escalation sources by agent:**

| Agent | Escalation Condition |
|-------|---------------------|
| front-desk | Injuries reported with potential bodily injury liability |
| claims-officer | Coverage ambiguity that cannot be resolved by AI, policy in dispute |
| assessor | Total loss claim above coverage limit, complex multi-vehicle |
| fraud-analyst | Risk level=critical or recommendation=REFER_SIU |
| senior-reviewer | Cannot reach confident decision, bad faith risk identified |
| finance | Payment exceeds authorization threshold (if set) |

### Human Resolution Flow

When a human resolves an escalated claim:

1. Human sends message to the Router session with resolution instructions
2. Router reads the resolution, updates claim file with human decision
3. Router writes audit_log entry: "Human resolution received: {summary}"
4. Router resumes pipeline from the stage after escalation (or terminates if human denies)

---

## 5. Context Enrichment

### What the Router Injects Per Stage

The Router acts as an intelligence middleware. Before spawning each stage, it reads the current claim state and injects relevant context into the task message.

**Context enrichment by stage:**

| Stage | Context Injected |
|-------|-----------------|
| front-desk | None (first stage, claim is raw FNOL) |
| claims-officer | Policy file path (constructed from claimant.policy_id), regulatory deadlines |
| assessor | Coverage parameters (deductible, limit, type) from claims-officer results |
| fraud-analyst | Assessment summary (estimate, total loss, pre-existing flags) from assessor |
| senior-reviewer | Fraud analysis summary (risk score, level, flags, recommendation) from fraud-analyst |
| finance | Approval details (decision, conditions), financial parameters (estimate, deductible, limit) |

### Regulatory Context Injection

The Router maintains awareness of key regulatory requirements and injects them into task messages:

**FCSP Act Timelines:**
- Acknowledgment: 15 business days from FNOL
- Decision: 30 business days from claim filing
- Payment: 30 business days from decision

**Ohio-Specific Rules:**
- Total loss threshold: 70-75% of ACV (professional judgment, not hardcoded)
- Bad faith exposure: unreasonable denial triggers 2x damages + attorney fees
- UM/UIM: Ohio Rev. Code 3937.18 requirements
- Ambiguity doctrine: coverage ambiguity resolved in claimant's favor

### Domain Knowledge at Startup

When the Router first receives a claim submission, it reads AGENTS.md which contains:
- The complete state machine (this document's logic)
- Stage-by-stage spawn instructions
- Error handling policy
- Regulatory context templates
- Audit logging requirements

The Router does NOT read Phase 1 domain knowledge files directly. Domain knowledge is embedded in each pipeline agent's AGENTS.md. The Router's job is orchestration, not domain reasoning.

---

## 6. Claim Lifecycle Example (Happy Path)

```
[User submits claim via channel]
  |
  v
[Router receives message]
  - Generates claim_id: CLM-2026-00001
  - Writes initial JSON: shared/state/claims/CLM-2026-00001.json
    status: FNOL_RECEIVED, submitted_at: now
  - Appends audit_log: {agent: "router", action: "claim_registered"}
  |
  v
[Router spawns front-desk]
  sessions_spawn(agentId="front-desk", task="Process auto insurance claim...", runTimeoutSeconds=60)
  |
  v  (Router waits for announce)
  |
[front-desk completes]
  Announce: "Status: success\nResult: FNOL intake complete. Category: standard collision..."
  |
  v
[Router reads CLM-2026-00001.json]
  Validates: pipeline.front_desk.completed_at is set
  Reads: claimant.policy_id = "POL-AUT-10001"
  Constructs policy path: shared/policies/POL-AUT-10001.json
  |
  v
[Router spawns claims-officer]
  sessions_spawn(agentId="claims-officer", task="Process coverage verification...", runTimeoutSeconds=90)
  |
  v  ... (pattern repeats through all 6 stages) ...
  |
  v
[finance completes]
  Announce: "Status: success\nResult: Payment of $4,250.00 issued..."
  |
  v
[Router reads final claim state]
  status: PAYMENT_ISSUED
  Appends audit_log: {agent: "router", action: "pipeline_complete", reasoning: "All 6 stages complete..."}
  Announces to originating channel: "Claim CLM-2026-00001 processed. Payment of $4,250.00 issued."
```

---

*Architecture specification for: Router/Orchestrator Design*
*Phase 02, Plan 02 of Ohio Mutual Auto Claims Processing System*
