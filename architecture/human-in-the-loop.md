# Human-in-the-Loop Escalation Design

Design specification for the escalation system in the Ohio Mutual Auto claims processing pipeline. This document defines when AI should defer to human judgment, how escalation is communicated, how the pipeline pauses and resumes, and how regulatory timelines interact with escalation.

**Design Principle:** The escalation system demonstrates that AI agents know their limits. This is a competitive differentiator for the hackathon -- responsible AI that defers on high-stakes edge cases shows regulatory awareness and builds trust with judges evaluating business thinking.

**Reference Schema:** `shared/schemas/claim.schema.json`
**Reference Protocol:** `architecture/handoff-protocol.md`

---

## 1. Escalation Triggers

Escalation triggers are expressed as reasoning principles, not hardcoded thresholds. Each agent applies judgment about when a situation warrants human oversight, guided by the principles below. The specific examples and severity levels inform the agent's reasoning but do not define rigid if/then rules.

### Trigger Catalog

| # | Trigger | Source Agent | Reasoning Principle | Severity | Examples |
|---|---------|-------------|---------------------|----------|----------|
| 1 | **High fraud risk** | Fraud Analyst | When multiple fraud indicators converge into a pattern that matches known fraud schemes, the claim requires human investigation before any payment decision. A single isolated indicator is a note; converging indicators are a referral. | High | Risk level assessed as critical; recommendation is REFER_SIU; multiple flags with converging patterns |
| 2 | **Significant claim value** | Assessor | Claims of significant value relative to typical claim patterns and the policyholder's coverage tier warrant additional human oversight. The threshold for "significant" should reflect the insurer's risk appetite and the complexity of the damage. | Medium | Repair estimate substantially exceeds the typical range for the claim type; total estimated payout approaches coverage limit |
| 3 | **Total loss determination** | Assessor | Total loss declarations have outsized financial impact and policyholder consequences. When repair costs approach or exceed the threshold relative to the vehicle's actual cash value, human confirmation of the ACV assessment and total loss declaration is prudent. | Medium | Vehicle repair cost relative to ACV exceeds applicable total loss threshold; ACV assessment depends on judgment calls about condition, mileage, or market factors |
| 4 | **Legal representation** | Front Desk / Router | When a claimant has retained legal representation, the claim dynamics change significantly. Attorney involvement signals potential dispute, litigation risk, or bad faith allegation. Human claims handlers must be involved to manage the legal relationship appropriately. | High | Attorney letter received; legal representative noted in claim submission; claimant mentions legal counsel |
| 5 | **Bad faith risk** | Senior Reviewer | When the claims handling timeline approaches regulatory deadlines, the risk of bad faith allegations increases. Claims that are near or past regulatory timeframes require human oversight to ensure the insurer's response demonstrates good faith effort and compliance. | High | FCSP timeline check shows approaching deadline; elapsed time from FNOL nears the jurisdiction's decision window; prior delays in pipeline processing |
| 6 | **Coverage ambiguity** | Claims Officer | When policy language is genuinely ambiguous about whether a claim is covered, the ambiguity doctrine generally favors the insured -- but the judgment call about whether ambiguity exists requires human review. Uncertain coverage determinations should not be resolved by AI alone. | Medium | Coverage determination cannot be made with confidence; policy exclusions partially apply; incident type falls between two coverage categories |
| 7 | **Prior fraud history** | Fraud Analyst | When a claimant or associated party has prior fraud flags, history of SIU referrals, or a pattern of suspicious claims, human oversight ensures that prior history is weighed appropriately without unfairly prejudicing the current claim. | Medium | Claimant has prior claims with fraud flags; associated parties appear in multiple claims; pattern of claims from the same address or phone number |

### Reasoning Principle Design

Each trigger is framed as a **judgment principle** rather than a numerical threshold. This design choice directly supports the hackathon requirement that "your thinking should not be hardcoded."

**Why principles instead of thresholds:**
- Thresholds break when the secret addition changes the business context
- Principles allow the agent to reason about the specific claim circumstances
- Judges can ask "what if the threshold were different?" and the system adapts
- Real insurance companies use guidelines, not rigid cutoffs, for escalation decisions

**How agents apply principles:**
Each agent's AGENTS.md contains the relevant escalation principles as part of its operating instructions. The agent reasons about the current claim against these principles and decides whether escalation is warranted. The agent documents its reasoning in the audit log, regardless of whether it escalates or not.

**Example of principle-based reasoning in audit log:**
```
"reasoning": "Evaluated claim value against typical patterns for standard collision
claims. Repair estimate of $8,450 is within the normal range for frontal collision
damage to a mid-size sedan -- does not warrant escalation for value alone. Coverage
limit of $50,000 provides substantial headroom. No escalation triggered."
```

vs. hardcoded approach (what we avoid):
```
"reasoning": "Repair estimate $8,450 < $25,000 threshold. No escalation."
```

---

## 2. Escalation Output Format

When any agent triggers an escalation, it writes a structured escalation record to the claim JSON. This format ensures human reviewers receive complete context for their decision.

### Escalation JSON Structure

```json
{
  "escalation": {
    "triggered_by": "fraud-analyst",
    "trigger_type": "high_fraud_risk",
    "trigger_reason": "Multiple converging fraud indicators suggest a coordinated claim scheme. Staged accident pattern detected with phantom passenger and inflated repair elements.",
    "claim_id": "CLM-2026-00001",
    "severity": "high",
    "risk_summary": {
      "key_findings": [
        "Three fraud indicators converge: inconsistent witness statements, repair estimate 40% above comparable claims, claim filed within 30 days of coverage increase",
        "Pattern matches known staged accident scheme: low-speed rear-end collision with exaggerated injury claims",
        "Assessor flagged pre-existing damage consistent with prior unreported incident"
      ],
      "mitigating_factors": [
        "Police report filed and on record",
        "Claimant has 5-year claim-free history prior to this incident"
      ]
    },
    "recommended_action": "SIU investigation before proceeding. Recommend field inspection to verify damage consistency with reported incident.",
    "pipeline_position": "after FRAUD_ANALYZED",
    "stages_completed": ["front_desk", "claims_officer", "assessor", "fraud_analyst"],
    "stages_remaining": ["senior_reviewer", "finance"],
    "time_in_pipeline": "PT15M",
    "submitted_at": "2026-02-21T10:23:00Z",
    "escalated_at": "2026-02-21T10:38:00Z",
    "regulatory_context": {
      "acknowledgment_deadline": "2026-03-10",
      "decision_deadline": "2026-03-25",
      "days_elapsed": 0,
      "urgency": "normal"
    }
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `triggered_by` | string | Yes | Agent ID that triggered the escalation |
| `trigger_type` | string | Yes | Trigger category from the catalog (e.g., high_fraud_risk, significant_claim_value, total_loss, legal_representation, bad_faith_risk, coverage_ambiguity, prior_fraud_history) |
| `trigger_reason` | string | Yes | Human-readable explanation of why this escalation was triggered |
| `claim_id` | string | Yes | Claim identifier |
| `severity` | enum | Yes | high or medium (from trigger catalog) |
| `risk_summary.key_findings` | array | Yes | Bullet points of the most important evidence supporting escalation |
| `risk_summary.mitigating_factors` | array | Yes | Evidence that weighs against the escalation concern (balanced view) |
| `recommended_action` | string | Yes | What the escalating agent recommends the human reviewer should do |
| `pipeline_position` | string | Yes | Where in the pipeline the escalation occurred |
| `stages_completed` | array | Yes | Pipeline stages that finished before escalation |
| `stages_remaining` | array | Yes | Pipeline stages that would follow if escalation is resolved |
| `time_in_pipeline` | string | Yes | ISO 8601 duration from submitted_at to escalated_at |
| `submitted_at` | datetime | Yes | Original claim submission time |
| `escalated_at` | datetime | Yes | When escalation was triggered |
| `regulatory_context` | object | Yes | FCSP timeline information for the human reviewer |

### Where the Escalation Record Lives

The escalation record is written by the Router (not the pipeline agent) after receiving an ESCALATE announce. The Router:
1. Reads the agent's section data and announce message
2. Constructs the full escalation record with pipeline context
3. Writes it to the claim JSON as a top-level `escalation` field
4. The escalation field persists until human resolution

This ensures the escalation record includes full pipeline context that the individual agent may not have (e.g., time_in_pipeline, regulatory deadlines, stages_remaining).

---

## 3. Pipeline Pause Mechanism

When escalation is triggered, the pipeline must stop cleanly without losing state. The pause mechanism ensures the claim is preserved in a reviewable state.

### Pause Sequence

**Step 1: Agent Signals Escalation**
The pipeline agent that identifies the escalation concern:
- Completes writing its section to the claim JSON (all findings, even partial)
- Sets its `completed_at` timestamp (the agent's work IS complete -- the escalation IS the output)
- Announces `ESCALATE` to the Router with a summary of the escalation reason

**Step 2: Router Receives ESCALATE Announce**
The Router:
1. Reads the updated claim JSON to confirm the agent's section is written
2. Sets `pipeline.senior_reviewer.escalated_to_human = true` in the claim JSON
   - Note: This field is on the senior_reviewer section because the Senior Reviewer is the designated human escalation point in the pipeline hierarchy
   - If the Senior Reviewer itself triggers escalation, it sets this field directly
3. Sets `pipeline.senior_reviewer.escalation_reason` to the escalation explanation
4. Sets claim `status` to `"ESCALATED"`
5. Updates `updated_at` timestamp
6. Constructs and writes the `escalation` record (see Section 2)
7. Appends an audit_log entry:
   ```json
   {
     "timestamp": "2026-02-21T10:38:00Z",
     "agent": "router",
     "action": "escalation_triggered",
     "reasoning": "Fraud Analyst reported ESCALATE with critical risk assessment. Multiple converging fraud indicators detected. Pipeline paused at FRAUD_ANALYZED stage pending human review.",
     "regulation_reference": "FCSP Act: claim processing paused for investigation; regulatory timelines continue to run"
   }
   ```

**Step 3: Router Stops Pipeline**
- Router does NOT spawn any further pipeline agents
- Router does NOT attempt to retry or work around the escalation
- Router announces the escalation status to the original requester channel (if applicable)
- The claim file sits on disk in `ESCALATED` status, fully readable

**Step 4: Claim Preservation**
The claim JSON is complete through the last finished stage. All audit_log entries are preserved. The escalation record contains everything a human reviewer needs to make a decision without reading the full pipeline history.

### Claim JSON in ESCALATED State

```json
{
  "claim_id": "CLM-2026-00001",
  "status": "ESCALATED",
  "submitted_at": "2026-02-21T10:23:00Z",
  "updated_at": "2026-02-21T10:38:00Z",
  "pipeline": {
    "front_desk": { "completed_at": "2026-02-21T10:24:15Z", "...": "..." },
    "claims_officer": { "completed_at": "2026-02-21T10:26:30Z", "...": "..." },
    "assessor": { "completed_at": "2026-02-21T10:29:00Z", "...": "..." },
    "fraud_analyst": { "completed_at": "2026-02-21T10:31:45Z", "...": "..." },
    "senior_reviewer": {
      "completed_at": null,
      "escalated_to_human": true,
      "escalation_reason": "Multiple converging fraud indicators..."
    },
    "finance": { "completed_at": null }
  },
  "escalation": { "...": "full escalation record from Section 2" },
  "audit_log": [ "...complete history through escalation..." ]
}
```

---

## 4. Human Resolution Path

Human resolution follows a structured protocol that preserves the audit trail and enables clean pipeline resumption.

### Resolution Flow

**Step 1: Human Reviews Escalation**
The human reviewer:
- Reads the claim JSON file directly (e.g., `cat shared/state/claims/CLM-2026-00001.json`)
- Reviews the `escalation` record for the summary and recommended action
- Reviews `audit_log` for the complete decision history
- Reviews individual pipeline sections for detailed findings
- Makes a resolution decision

### Resolution Actions

| Resolution | Meaning | What Happens Next |
|------------|---------|-------------------|
| `approve` | Human overrides escalation concern; claim should proceed | Router resumes pipeline from escalation point |
| `deny` | Human agrees with concern; claim should be denied | Router sets status to DENIED, logs human decision |
| `modify` | Human adjusts claim data before proceeding | Router updates claim JSON per human instructions, then resumes |
| `investigate` | Human requires additional investigation | Claim stays ESCALATED with updated investigation notes |

**Step 2: Human Sends Resolution to Router**
The human sends a message to the Router session with the resolution:

```
Resolution for CLM-2026-00001:
Action: approve
Reasoning: SIU investigation conducted. Damage verified on-site as consistent
with reported collision. Witness statements confirmed independently. Fraud
indicators were coincidental, not convergent. Proceed with claim processing.
```

**Step 3: Router Processes Resolution**
The Router:
1. Reads the human resolution message
2. Updates the claim JSON:
   - Sets `pipeline.senior_reviewer.escalated_to_human = false` (escalation resolved)
   - Adds human decision reasoning to `pipeline.senior_reviewer.decision_reasoning`
   - Removes or marks the `escalation` record as resolved
   - Updates `updated_at`
3. Appends an audit_log entry:
   ```json
   {
     "timestamp": "2026-02-21T11:15:00Z",
     "agent": "router",
     "action": "human_resolution_received",
     "reasoning": "Human reviewer resolved escalation for CLM-2026-00001. Action: approve. SIU investigation cleared fraud concerns. Resuming pipeline from Senior Reviewer stage.",
     "regulation_reference": null
   }
   ```
4. Determines resume point based on escalation position and resolution action

**Step 4: Router Resumes Pipeline**
Based on the resolution action:

- **approve**: Router resumes from the next unfinished stage
  - If escalated during Fraud Analysis: spawn Senior Reviewer
  - If escalated during Senior Review: spawn Finance (treating human approval as Senior Reviewer decision)
  - If escalated during any earlier stage: resume from that stage's successor
- **deny**: Router sets status to DENIED, writes final audit entry, announces denial
- **modify**: Router applies modifications to claim JSON, then resumes from appropriate stage
- **investigate**: Router keeps claim in ESCALATED status, updates audit_log with investigation notes

### Resume Task Message Enhancement
When resuming after escalation, the Router enriches the task message with escalation context:

```
Review and decide on auto insurance claim CLM-2026-00001.

Claim file: /absolute/path/shared/state/claims/CLM-2026-00001.json

ESCALATION CONTEXT:
This claim was previously escalated due to: [trigger_reason]
Human resolution: [action] -- [reasoning]
Time in escalation: [duration]

Please factor the human reviewer's findings into your decision.
Your role and instructions remain the same as standard processing.
```

---

## 5. Demo Implications

The escalation system serves a dual purpose: operational correctness and hackathon presentation value.

### Demonstrating Responsible AI

For the hackathon demo, ESCALATED claims show the system's judgment about when to defer to humans. This is a competitive differentiator because:

1. **Regulatory awareness:** The system knows that certain decisions should not be made autonomously, demonstrating understanding of real insurance operations
2. **Transparent reasoning:** The escalation record shows exactly why the AI deferred, not just that it did
3. **Balanced judgment:** Including mitigating factors in the escalation shows the system considers all evidence, not just alarm signals
4. **FCSP compliance:** The regulatory context in the escalation shows the system tracks deadlines even during human review

### Recommended Demo Scenario: Fraud Escalation

Prepare one test claim that triggers the fraud escalation path:

**Scenario: Suspicious Collision Claim**
- Claimant filed a claim 25 days after adding collision coverage
- Low-speed rear-end collision with no witnesses
- Repair estimate is significantly higher than comparable claims for similar damage
- Claimant has a prior claim from 18 months ago with fraud flags (but was cleared)

**Expected pipeline behavior:**
1. Front Desk: Categorizes as standard collision, priority normal
2. Claims Officer: Coverage confirmed (collision coverage active)
3. Assessor: Estimates repair, flags pre-existing damage indicators, notes estimate seems high relative to described impact
4. Fraud Analyst: Identifies converging indicators -- recent coverage addition + no witnesses + elevated estimate + prior fraud history. Sets risk_level to high, recommendation to REFER_SIU. Announces ESCALATE.
5. Router: Pauses pipeline, writes escalation record, sets status to ESCALATED
6. **Demo moment:** Show the claim JSON in ESCALATED status. Read the escalation record aloud. Explain why the system deferred rather than auto-denying.

**Presenter narration:**
"Notice what the system did NOT do -- it did not automatically deny this claim. Instead, it identified converging fraud indicators and escalated to a human reviewer. The system's reasoning is transparent: here are the indicators, here are the mitigating factors, and here is what it recommends the human investigate. This is responsible AI -- it knows when to defer."

### Demo Script Integration
The `run-demo.sh` script should include an escalation scenario as the second or third demo claim. The first claim should be a happy path (full pipeline through payment). The escalation claim shows judgment and restraint.

---

## 6. FCSP Timeline Compliance in Escalation

Escalation does not pause regulatory timelines. Even when a claim is in ESCALATED status awaiting human review, the FCSP Act deadlines continue to run. The system must track and communicate this.

### Timeline Tracking During Escalation

**At escalation time:**
The Router calculates and includes in the escalation record:
- `days_elapsed`: Business days from `submitted_at` to `escalated_at`
- `acknowledgment_deadline`: Per applicable jurisdiction (conservative default)
- `decision_deadline`: Per applicable jurisdiction
- `urgency`: Derived from proximity to deadlines

**Urgency levels:**

| Level | Reasoning Principle |
|-------|---------------------|
| `normal` | Claim is well within all regulatory windows. No timeline pressure. |
| `elevated` | Claim has been in pipeline long enough that the escalation investigation period, combined with remaining processing time, brings the total close to regulatory limits. Human reviewer should prioritize. |
| `critical` | Claim is approaching or has reached regulatory deadlines. Immediate human action required to prevent compliance violation and bad faith exposure. |

Note: These are reasoning-based assessments, not hardcoded day counts. The Senior Reviewer and Router reason about timeline proximity relative to the jurisdiction's requirements.

### Senior Reviewer Timeline Check

The Senior Reviewer performs a FCSP timeline check on every claim, including those resumed after escalation. The check is recorded in `pipeline.senior_reviewer.fcsp_timeline_check`:

```json
{
  "fcsp_timeline_check": {
    "acknowledgment_deadline": "2026-03-10",
    "decision_deadline": "2026-03-25",
    "payment_deadline": "2026-04-24",
    "compliant": true
  }
}
```

If the Senior Reviewer determines that the claim is approaching or past a regulatory deadline:
- It factors urgency into its decision
- It may recommend expedited processing or interim communication to the claimant
- It documents the timeline concern in the audit_log
- In extreme cases, it may escalate with a `bad_faith_risk` trigger

### Escalation Duration Awareness

When a claim has been in ESCALATED status, the Router tracks total escalation duration. On resume:
1. Router calculates escalation duration (escalated_at to resolution timestamp)
2. Router adds the duration to the enriched task message for subsequent agents
3. Subsequent agents factor total pipeline time into their processing
4. Senior Reviewer's FCSP timeline check accounts for escalation delays

### Preventing Escalation from Becoming Non-Compliance

The system includes safeguards to prevent escalation from causing regulatory violations:

1. **Escalation record includes regulatory_context:** Human reviewer sees deadline information immediately
2. **Urgency assessment at escalation time:** Critical urgency claims are flagged for immediate human attention
3. **Router periodic check (future enhancement):** For production, the Router would periodically check ESCALATED claims and re-alert if deadlines approach. For the hackathon demo, the escalation record's regulatory context is sufficient.
4. **Audit trail documentation:** If a claim's timeline was extended due to escalation, the audit log documents the reason (fraud investigation, human review needed, etc.) -- this is the insurer's defense against bad faith allegations

---

## Summary

The human-in-the-loop escalation system ensures that:

1. **Seven escalation triggers** cover the critical scenarios where AI should defer to human judgment, expressed as reasoning principles rather than hardcoded thresholds
2. **Structured escalation output** gives human reviewers complete context including key findings, mitigating factors, recommended actions, and regulatory timeline information
3. **Clean pipeline pause** preserves all claim state and audit history while stopping further automated processing
4. **Structured human resolution** with four resolution types (approve, deny, modify, investigate) and full audit trail of human decisions
5. **FCSP timeline awareness** ensures escalation does not inadvertently cause regulatory non-compliance by tracking deadlines throughout the escalation lifecycle
6. **Demo value** demonstrates responsible AI that knows its limits -- a competitive differentiator for hackathon judges evaluating business thinking

---

*Human-in-the-loop escalation design for: Ohio Mutual Auto -- Multi-Agent Claims Processing Pipeline*
*Reference: shared/schemas/claim.schema.json, architecture/handoff-protocol.md*
