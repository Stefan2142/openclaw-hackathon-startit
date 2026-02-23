# Agent Documentation -- Ohio Mutual Auto Claims Processing

This document describes the 7 AI agents that comprise the Ohio Mutual Auto Claims Processing pipeline. Each agent mirrors a real insurance professional role, operating with domain-specific expertise and clearly scoped authority. The system demonstrates that AI agents can process insurance claims with the rigor, auditability, and regulatory compliance expected of human adjusters.

---

## Pipeline Overview

```
                            Claim Submission
                                  |
                                  v
                          +---------------+
                          |    ROUTER     |  depth-0 orchestrator
                          | (Claude Opus) |  owns lifecycle + state
                          +-------+-------+
                                  |
                     spawns sequentially (depth-1)
                                  |
          +-------+-------+-------+-------+-------+-------+
          |       |       |       |       |       |       |
          v       v       v       v       v       v       v
      +-------+-------+-------+-------+-------+-------+
      | Front | Claims|       | Fraud | Senior|       |
      | Desk  | Officer|Assessor|Analyst|Reviewer|Finance|
      |       |       |       |       |       |       |
      |Sonnet |Sonnet | Opus  | Opus  | Opus  |Sonnet |
      +-------+-------+-------+-------+-------+-------+
       Stage 1 Stage 2 Stage 3 Stage 4 Stage 5 Stage 6
       FNOL    Coverage Damage  Fraud   Decision Payment
       Intake  Check   Estimate Detect  Authority Process
```

### Agent Interaction Flow

```
[Claim JSON file: shared/state/claims/CLM-ID.json]
         ^                    |
         |   read             |   write
         |                    v
     +---+--------------------+---+
     |         ROUTER             |
     |  - Creates initial claim   |
     |  - Spawns agents 1-by-1   |
     |  - Validates each output   |
     |  - Owns status transitions |
     |  - Handles errors/escal.   |
     +---+--------------------+---+
         |                    ^
         |  sessions_spawn    |  announce (SUCCESS/ERROR/ESCALATE)
         v                    |
     +---+--------------------+---+
     |     Pipeline Agents 1-6    |
     |  - Read claim JSON         |
     |  - Write their section     |
     |  - Append audit log        |
     |  - Announce result         |
     +----------------------------+

No direct agent-to-agent communication.
All data flows through the claim JSON file.
Router mediates every transition.
```

---

## Agent 1: Router

**Role:** Depth-0 orchestrator that owns the entire claim lifecycle from submission to final outcome.

### Purpose in Real Insurance

In a real insurance organization, the claims routing function is handled by a claims intake supervisor or workflow management system. This role ensures every claim follows the correct processing path, that no step is skipped, and that exceptions (errors, escalations, denials) are handled according to organizational policy. Without centralized routing, claims can fall through cracks, skip required reviews, or proceed without proper authorization.

### Pipeline Position

Depth-0 main agent. The Router is NOT a pipeline stage -- it sits above the pipeline and orchestrates all 6 stages. It is the only agent that runs as a persistent session (all other agents are spawned as depth-1 sub-agents for a single task).

### Model Assignment

**Claude Opus** -- The Router requires the highest reasoning capability because it must:
- Maintain a complex state machine with multiple branching paths
- Validate the output of every other agent before allowing the pipeline to advance
- Make meta-decisions (retry vs. escalate vs. terminate) based on agent failures
- Construct context-enriched task messages for each pipeline stage
- Handle edge cases like coverage denial shortcuts and fraud-triggered escalations

### Tools Available

| Tool | Why |
|------|-----|
| read | Read claim files, policy files, and agent outputs from disk |
| write | Create initial claim records, update status and audit log |
| exec | Execute helper scripts (submit-claim, run-demo, status checks) |
| sessions_spawn | Spawn pipeline agents -- the core orchestration mechanism |
| sessions_list | Monitor active sub-agent sessions |
| sessions_history | Read sub-agent transcripts for debugging and audit |
| session_status | Check whether a sub-agent run has completed |

### Decision-Making Approach

The Router does not perform domain reasoning (that is delegated to pipeline agents). Instead, it applies a **validate-then-advance** pattern:
1. Spawn an agent with a constructed task message
2. Wait for the agent's announce message
3. Read the updated claim file
4. Validate that all required output fields are populated and well-formed
5. Decide: advance to next stage, retry on error, or escalate

The Router also applies **context enrichment** -- injecting relevant data from prior stages into each subsequent agent's task message so agents have the information they need without reading irrelevant data.

### Key Outputs

- Initial claim JSON record (claim_id, status, claimant, incident, empty pipeline)
- Status transitions (FNOL_RECEIVED, COVERAGE_CHECKED, ASSESSED, FRAUD_ANALYZED, REVIEWED, PAYMENT_ISSUED, DENIED, ESCALATED, ERROR)
- Audit log entries for pipeline events (claim_registered, pipeline_completed, error_logged, escalation_triggered)
- Escalation records with full pipeline context

### Why It Exists as a Separate Agent

The Router cannot be merged with any pipeline agent because it has fundamentally different responsibilities:
- **Lifecycle ownership:** Pipeline agents process one stage; the Router owns the entire sequence.
- **Tool access:** Only the Router has `sessions_spawn` -- merging it with a pipeline agent would give that agent the ability to spawn other agents, violating the depth-1 constraint.
- **Separation of concerns:** Domain reasoning (what decision to make) is separated from orchestration (what to do next). This means domain logic changes in one agent do not affect the pipeline flow.
- **Error isolation:** If a pipeline agent fails, the Router can retry or escalate. If the Router were merged with a pipeline agent, a failure in domain reasoning would also fail the orchestrator.

---

## Agent 2: Front Desk

**Role:** FNOL intake specialist responsible for categorizing claims, assessing completeness, and assigning processing priority.

### Purpose in Real Insurance

Every insurance company has a first-notice-of-loss (FNOL) intake function. In practice, this is the call center representative or online intake form that receives the initial loss report. The intake function determines: What kind of loss is this? How urgent is it? Is the report complete enough to proceed? Proper intake prevents downstream delays -- a miscategorized claim goes to the wrong coverage check, a missing police report number delays investigation, and an unrecognized urgency indicator causes regulatory timeline violations.

### Pipeline Position

Stage 1 (depth-1 sub-agent). First agent to process any claim. Reads the raw claim submission and produces structured intake findings.

### Model Assignment

**Claude Sonnet** -- FNOL intake is primarily a structured extraction and categorization task. The incident description is parsed into discrete fields (category, priority, missing items). This does not require the deep multi-step reasoning of Opus. Sonnet handles categorization efficiently while keeping cost and latency low for the highest-volume pipeline stage.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read the claim JSON file to process FNOL data |
| write | Write intake results to pipeline.front_desk and append audit log |

No `exec`, `sessions_spawn`, or `browser` access. Front Desk performs structured data extraction -- it does not need to run scripts or spawn sub-agents.

### Decision-Making Approach

The Front Desk follows a **systematic checklist**:
1. Verify minimum required fields are present (claim_id, policy_id, name, incident date, description, type)
2. Categorize the claim based on incident type and description details
3. Assess priority using a severity framework (injuries = urgent, total loss indicators = high, standard claims = normal, cosmetic only = low)
4. Check for catastrophe event indicators (weather-related damage affecting multiple policyholders)
5. Identify missing information that would impede downstream processing

The key reasoning principle: **categorize based on primary cause of loss** and **when in doubt between priority levels, choose the higher one** (faster processing is preferable to delayed processing).

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.front_desk.category` | Claim category (e.g., "standard collision", "weather event") |
| `pipeline.front_desk.priority` | Priority level: low, normal, high, urgent |
| `pipeline.front_desk.cat_event` | CAT event identifier if applicable |
| `pipeline.front_desk.missing_info` | List of missing information items |

### Why It Exists as a Separate Agent

Intake and coverage verification are distinct professional functions:
- **Different expertise:** Intake requires understanding loss event types and urgency indicators. Coverage verification requires understanding policy contracts and exclusion language. Combining them creates a "jack of all trades" agent that does neither well.
- **Pipeline independence:** Front Desk output does not depend on policy data (it does not read the policy file). If merged with Claims Officer, every claim would require a policy lookup even during intake, adding unnecessary latency.
- **Failure isolation:** A claim with a missing description can still be categorized and prioritized (with a note about missing info). If intake and coverage were merged, a policy file lookup failure would block even the intake function.

---

## Agent 3: Claims Officer

**Role:** Coverage verification specialist responsible for policy lookup, coverage confirmation, exclusion analysis, and denial documentation.

### Purpose in Real Insurance

The coverage analyst is the gatekeeper of the claims process. In a real insurance organization, this role verifies that the policyholder has an active policy with coverage that applies to the reported loss. They check effective dates, match incident types to coverage types, review all exclusions, and determine the applicable deductible and coverage limit. This is the first "hard decision" in the pipeline -- a coverage denial terminates the claim (with regulatory documentation requirements). Getting this wrong in either direction has consequences: wrongly denying a covered claim creates bad faith liability; wrongly approving an uncovered claim creates financial loss.

### Pipeline Position

Stage 2 (depth-1 sub-agent). Runs after Front Desk. This is the only pipeline agent that reads TWO files: the claim JSON and the policy JSON.

### Model Assignment

**Claude Sonnet** -- Coverage verification is a matching and exclusion-checking exercise. The agent compares incident characteristics against policy terms, checks dates, and applies exclusion rules. While important, it follows well-defined patterns (date range checks, coverage type matching, exclusion list review). Sonnet handles this structured analysis reliably without requiring Opus-level reasoning.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read both the claim file AND the policy file (two-file agent) |
| write | Write coverage results to pipeline.claims_officer and append audit log |

The Claims Officer is one of only two agents that read a file other than the claim JSON (the Router also reads policy files to construct paths).

### Decision-Making Approach

The Claims Officer applies a **systematic coverage verification framework**:
1. Verify policy was active on the date of loss (not the date of filing)
2. Match incident type to available coverage types on the policy
3. Check ALL applicable exclusions -- document each one reviewed, even if not applicable (due diligence for FCSP compliance)
4. Apply the ambiguity doctrine: if coverage is ambiguous, construe in the claimant's favor
5. For coverage denials: document the specific policy language and exclusion that applies

The coverage denial path is a critical shortcut -- denied claims skip Assessor, Fraud Analyst, and Finance stages entirely but still go to Senior Reviewer for bad faith risk assessment.

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.claims_officer.covered` | Boolean: is the claim covered? |
| `pipeline.claims_officer.policy_status` | active, expired, cancelled, suspended |
| `pipeline.claims_officer.coverage_type` | Applicable coverage type |
| `pipeline.claims_officer.deductible_amount` | Deductible in USD |
| `pipeline.claims_officer.coverage_limit` | Maximum coverage limit in USD |
| `pipeline.claims_officer.exclusions_checked` | All exclusions reviewed with applicability |
| `pipeline.claims_officer.denial_reason` | If denied: specific reason with policy reference |
| `pipeline.claims_officer.um_uim_route` | UM/UIM routing if applicable |

### Why It Exists as a Separate Agent

Coverage verification is the single highest-stakes binary decision in the pipeline:
- **Denial authority:** This is the only stage where a claim can be denied before reaching the Senior Reviewer. The coverage decision must be isolated so its reasoning is auditable independently of damage assessment or fraud analysis.
- **Two-file access:** The Claims Officer reads the policy file -- a different data source than the claim. Combining this with other agents would mean every agent would need policy file access, violating least-privilege.
- **Regulatory documentation:** FCSP Act requires that every exclusion checked is documented when evaluated. This documentation is specific to coverage verification and would clutter the output of a combined agent.
- **Early termination:** The coverage denial shortcut depends on a clean separation between "is it covered?" and "how much damage?"

---

## Agent 4: Assessor

**Role:** Damage estimation specialist responsible for repair cost estimation, total loss determination, parts recommendation, and pre-existing damage identification.

### Purpose in Real Insurance

The auto damage appraiser is a licensed professional in most states who inspects vehicle damage and produces a detailed repair estimate. This estimate determines how much the insurer will pay. The appraiser must understand vehicle construction, repair procedures, parts pricing, labor rates, and total loss thresholds. In our system, the Assessor performs this function using structured damage descriptions and photo references, applying professional judgment frameworks for estimation.

### Pipeline Position

Stage 3 (depth-1 sub-agent). Runs only for covered claims (skipped when Claims Officer denies coverage). Receives incident description and photos to estimate damage.

### Model Assignment

**Claude Opus** -- Damage estimation requires the most complex domain reasoning of any pipeline stage. The Assessor must synthesize multiple cost categories (labor, parts, paint, supplements), apply judgment about OEM vs. aftermarket parts, evaluate total loss against ACV, identify pre-existing damage indicators, and assess hidden damage likelihood. This multi-dimensional professional judgment task benefits from Opus's superior reasoning depth.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read claim file and photo file paths (descriptions inform assessment) |
| write | Write assessment results to pipeline.assessor and append audit log |

No `exec` access. Estimation is professional judgment based on structured reasoning, not computation scripts.

### Decision-Making Approach

The Assessor follows a **structured estimation methodology**:
1. Analyze incident mechanics (direction of impact, speed, forces) to understand expected damage pattern
2. Break down repair cost into categories: body labor, mechanical labor, paint labor, parts, paint materials, supplemental costs
3. Evaluate total loss by comparing repair estimate to Actual Cash Value (Ohio uses 100% ACV rule)
4. Recommend parts type using the OEM vs. aftermarket framework (vehicle age, mileage, safety criticality)
5. Estimate rental days based on repair complexity
6. Flag pre-existing damage indicators (inconsistent weathering, non-impact-pattern damage, old rust under fresh damage)
7. Assess hidden damage likelihood based on impact type (frontal impacts often have hidden radiator/frame damage)

Photo analysis is framed as description-based reasoning, not ML inference. The Assessor reads damage descriptions and photo context to inform professional judgment.

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.assessor.repair_estimate_usd` | Total repair cost estimate |
| `pipeline.assessor.total_loss` | Whether vehicle is a total loss |
| `pipeline.assessor.acv_usd` | Actual Cash Value (if total loss) |
| `pipeline.assessor.salvage_value_usd` | Salvage value (if total loss) |
| `pipeline.assessor.parts_recommendation` | OEM or aftermarket |
| `pipeline.assessor.labor_hours` | Estimated labor hours |
| `pipeline.assessor.rental_days` | Estimated rental car days |
| `pipeline.assessor.pre_existing_damage_flags` | Pre-existing damage indicators |
| `pipeline.assessor.hidden_damage_likely` | Hidden damage assessment |

### Why It Exists as a Separate Agent

Damage assessment is a specialized domain distinct from every other pipeline function:
- **Professional specialization:** In real insurance, damage appraisers are licensed separately from claims adjusters. The expertise (vehicle construction, repair procedures, parts pricing) is fundamentally different from coverage analysis or fraud detection.
- **Cross-reference value:** The Assessor's pre-existing damage flags feed into the Fraud Analyst's analysis. If merged, this cross-reference disappears -- the same agent cannot objectively flag damage inconsistencies and then evaluate its own flags for fraud.
- **Estimation methodology:** The structured cost breakdown (labor + parts + paint + supplements) is a self-contained methodology. Embedding it within a larger agent would dilute the focus and increase the chance of estimation errors.

---

## Agent 5: Fraud Analyst

**Role:** Fraud detection specialist responsible for pattern matching, risk scoring, indicator convergence analysis, and SIU referral recommendations.

### Purpose in Real Insurance

Insurance fraud costs the industry tens of billions of dollars annually. Every major insurer has a Special Investigations Unit (SIU) and fraud analytics function. The fraud analyst reviews claims for patterns that indicate staged accidents, phantom passengers, inflated repairs, prior damage fraud, and other schemes. Critically, the fraud analyst is a **flag-and-escalate** function, not a **detect-and-deny** function. Flagging fraud indicators informs the decision-maker; the fraud analyst does not have authority to deny claims.

### Pipeline Position

Stage 4 (depth-1 sub-agent). Runs after the Assessor. Reads the FULL claim file including all prior pipeline stages, enabling cross-reference analysis (e.g., comparing the Assessor's damage estimate to the incident description for consistency).

### Model Assignment

**Claude Opus** -- Fraud detection requires the deepest analytical reasoning in the pipeline. The Fraud Analyst must simultaneously evaluate 7 distinct fraud patterns, assess indicator convergence (multiple weak signals combining into a strong signal), distinguish soft fraud from hard fraud, consider alternative innocent explanations, and produce calibrated risk scores. This multi-pattern, cross-referencing analysis demands Opus's advanced reasoning.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read entire claim file (all prior stages) for cross-reference analysis |
| write | Write fraud analysis to pipeline.fraud_analyst and append audit log |

No `exec` or `browser`. Fraud detection is pattern recognition through reasoning, not external tool invocation.

### Decision-Making Approach

The Fraud Analyst uses an **indicator convergence framework**:

1. **Check all 7 fraud patterns:** Staged accidents, phantom passengers, inflated repairs, prior damage fraud, VIN switching, owner give-up, and provider fraud rings. Document what was checked even when no indicators are found.
2. **Assess convergence:** A single indicator is a note. Multiple indicators from the same pattern are a flag. Multiple patterns with converging indicators are an escalation trigger.
3. **Consider alternative explanations:** Before concluding fraud, reason about whether indicators have legitimate explanations. Missing witness contacts are common in honest claims. A high repair estimate alone does not mean fraud.
4. **Classify fraud type:** Hard fraud (fabricated/staged) vs. soft fraud (exaggeration of legitimate claim). This distinction changes the recommended response entirely.
5. **Produce recommendation:** CLEAR (no fraud concerns), INVESTIGATE (Senior Reviewer should scrutinize), or REFER_SIU (Special Investigations Unit referral).

The risk score (0-100) represents indicator convergence strength, NOT probability of fraud.

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.fraud_analyst.risk_score` | 0-100 indicator convergence strength |
| `pipeline.fraud_analyst.risk_level` | low, medium, high, critical |
| `pipeline.fraud_analyst.flags` | Array of {pattern, description, severity} objects |
| `pipeline.fraud_analyst.soft_fraud` | Whether soft fraud indicators are present |
| `pipeline.fraud_analyst.recommendation` | CLEAR, INVESTIGATE, or REFER_SIU |

### Why It Exists as a Separate Agent

Fraud analysis must be independent from both damage assessment and decision-making:
- **Objective cross-referencing:** The Fraud Analyst reads the Assessor's output to check for consistency (e.g., low-speed impact with high repair estimate). If merged with the Assessor, the agent would be checking its own work for fraud -- a conflict of interest.
- **Flag-and-escalate separation:** The Fraud Analyst flags concerns; the Senior Reviewer makes decisions. Merging them would conflate detection with adjudication, undermining the checks-and-balances architecture.
- **Pattern expertise:** Fraud pattern detection requires a different knowledge base (staged accident indicators, phantom passenger patterns, SIU referral criteria) than any other pipeline function. Embedding this expertise in a broader agent dilutes its effectiveness.
- **Audit trail integrity:** When a claim is investigated or referred to SIU, regulators and courts examine the fraud analysis independently. Having it as a separate agent with its own audit log entries makes the analysis clearly attributable.

---

## Agent 6: Senior Reviewer

**Role:** Final decision authority responsible for weighing all pipeline evidence, ensuring regulatory compliance, and making the claim decision.

### Purpose in Real Insurance

The senior claims adjuster or claims manager is the decision authority in an insurance organization. They review the complete claim file -- intake findings, coverage determination, damage estimate, and fraud analysis -- and make the final call: approve, deny, attach conditions, or escalate to a human specialist. This role exists because no single upstream function should have both analytical authority and decision authority. The Senior Reviewer ensures that all prior stages are consistent, that the decision complies with regulations, and that the insurer's exposure to bad faith liability is managed.

### Pipeline Position

Stage 5 (depth-1 sub-agent). Runs after Fraud Analyst for standard claims. Also runs for coverage-denied claims (in a modified role: reviewing the denial for bad faith risk). This is the last decision point before payment.

### Model Assignment

**Claude Opus** -- The Senior Reviewer makes the highest-stakes decision in the pipeline. It must weigh evidence from 4 prior stages, check FCSP timeline compliance, assess bad faith risk, and produce a detailed decision rationale that must withstand regulatory audit. This holistic evidence-weighing task requires Opus's superior reasoning and judgment capabilities.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read entire claim file including all prior pipeline stages |
| write | Write final decision to pipeline.senior_reviewer and append audit log |

The Senior Reviewer has the same minimal toolset as other pipeline agents. Decision authority comes from its position in the pipeline and the Router's enforcement of the state machine, not from special tool access.

### Decision-Making Approach

The Senior Reviewer applies a **holistic evidence-weighing framework**:

1. Review ALL prior pipeline stages as a complete body of evidence
2. Verify FCSP timeline compliance (acknowledgment, decision, and payment deadlines)
3. Assess whether coverage determination was correct and well-documented
4. Evaluate damage estimate reasonableness relative to the incident
5. Weigh fraud analysis findings -- a fraud flag alone is NOT grounds for denial; the underlying evidence must support the decision
6. Choose one of four outcomes:
   - **APPROVED:** All stages passed, proceed to payment
   - **DENIED:** Evidence supports denial (with documented reasoning)
   - **CONDITIONAL:** Approved with specific conditions (additional documentation, inspection)
   - **ESCALATE_HUMAN:** AI cannot make a confident decision (high fraud risk, complex coverage question, bad faith risk)

Bad faith awareness is a core part of the decision framework: denying a legitimate claim carries worse consequences than paying a marginal one.

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.senior_reviewer.decision` | APPROVED, DENIED, CONDITIONAL, ESCALATE_HUMAN |
| `pipeline.senior_reviewer.decision_reasoning` | Detailed reasoning referencing evidence and regulations |
| `pipeline.senior_reviewer.conditions` | Conditions for CONDITIONAL approval |
| `pipeline.senior_reviewer.escalated_to_human` | Whether human escalation was triggered |
| `pipeline.senior_reviewer.escalation_reason` | Reason for escalation |
| `pipeline.senior_reviewer.fcsp_timeline_check` | Regulatory timeline compliance verification |

### Why It Exists as a Separate Agent

The decision authority must be isolated from all analytical functions:
- **Separation of analysis and judgment:** The Fraud Analyst flags; the Senior Reviewer decides. The Assessor estimates; the Senior Reviewer determines if the estimate supports payment. Merging decision-making with any analytical function removes the check that the analytical function was correct.
- **Regulatory compliance:** FCSP Act requires that claim decisions be documented with thorough reasoning. The Senior Reviewer produces this regulatory-ready decision record. Embedding it in a larger agent would make the decision rationale harder to extract and audit.
- **Escalation authority:** Only the Senior Reviewer can trigger human escalation (ESCALATE_HUMAN). This ensures that the decision to involve a human is made by the agent with the most complete view of the claim, not by an upstream agent with partial information.
- **Bad faith protection:** The Senior Reviewer's explicit bad faith risk assessment function protects the insurer. This assessment requires reviewing the complete pipeline, which only the final decision agent can do.

---

## Agent 7: Finance

**Role:** Payment processing specialist responsible for calculating the final payment amount, applying deductibles and depreciation, identifying subrogation opportunities, and creating the disbursement record.

### Purpose in Real Insurance

The finance/disbursement function in an insurance company translates an approved claim decision into an actual payment. This involves precise arithmetic (applying deductibles, depreciation, and coverage limits), identifying recovery opportunities (subrogation against at-fault parties), and creating auditable payment records. The finance function has one absolute rule: never pay without authorization. In our system, this is enforced as a hard constraint -- Finance will not calculate payment unless the Senior Reviewer's decision is APPROVED or CONDITIONAL.

### Pipeline Position

Stage 6 (depth-1 sub-agent). The final pipeline stage. Runs only when the Senior Reviewer approves or conditionally approves the claim. Never runs for denied or escalated claims.

### Model Assignment

**Claude Sonnet** -- Payment calculation follows deterministic formulas (estimate minus deductible minus depreciation, capped at coverage limit). While accuracy is critical, the reasoning is straightforward compared to damage estimation or fraud detection. Sonnet provides reliable arithmetic and record creation at lower cost and latency.

### Tools Available

| Tool | Why |
|------|-----|
| read | Read claim file for approved amount, deductible, and coverage parameters |
| write | Write payment record to pipeline.finance and append audit log |
| exec | Execute mock payment simulation script (generates payment reference number) |

Finance is the only pipeline agent with `exec` access. It uses this to run a mock payment disbursement script that simulates the real-world integration with a payment gateway and generates a payment reference number.

### Decision-Making Approach

The Finance agent follows a **calculation-first, verification-second** approach:

1. **Hard constraint check:** Verify Senior Reviewer decision is APPROVED or CONDITIONAL. If not, refuse to process payment.
2. **Determine payment basis:** Standard repair (estimate - deductible - depreciation) or total loss (ACV - deductible - salvage adjustment)
3. **Apply deductible:** Use the deductible amount from Claims Officer's coverage determination
4. **Apply depreciation:** For older vehicles, depreciate parts value based on age and condition
5. **Cap at coverage limit:** Verify payment does not exceed the policy's coverage limit
6. **Assess subrogation:** If other party is at fault and insured, flag as subrogation candidate for recovery
7. **Record payment:** Generate reference number, select payment method, note supplement eligibility

### Key Outputs

| Field | Description |
|-------|-------------|
| `pipeline.finance.payment_amount_usd` | Final payment after all deductions |
| `pipeline.finance.deductible_applied_usd` | Deductible amount deducted |
| `pipeline.finance.depreciation_applied_usd` | Depreciation deducted |
| `pipeline.finance.subrogation_candidate` | Whether subrogation applies |
| `pipeline.finance.subrogation_target` | Target insurer for recovery |
| `pipeline.finance.payment_method` | direct_deposit, check, or repair_shop_direct |
| `pipeline.finance.payment_reference` | Payment transaction reference |
| `pipeline.finance.supplement_eligible` | Eligible for supplemental payment |

### Why It Exists as a Separate Agent

Payment processing must be isolated from decision-making:
- **Authorization enforcement:** Finance's hard constraint (never pay without Senior Reviewer approval) is only meaningful if Finance is a separate agent. If merged with the Senior Reviewer, the same agent that decides "approve" also processes payment, eliminating the authorization check.
- **Financial controls:** In real insurance, payment authorization and payment execution are always separated (dual control principle). Our architecture mirrors this control structure.
- **Subrogation expertise:** Identifying recovery opportunities requires understanding fault determination, insurance company relationships, and recovery procedures. This is a distinct skill from claim decision-making.
- **Audit separation:** Regulators examine payment records separately from claim decisions. Having Finance as a distinct agent with its own audit log entries supports this regulatory requirement.

---

## Model Tier Rationale

The system uses two model tiers across the 7 agents:

| Tier | Model | Agents | Rationale |
|------|-------|--------|-----------|
| **Opus** (higher reasoning) | Claude Opus | Router, Assessor, Fraud Analyst, Senior Reviewer | Complex multi-step reasoning, professional judgment, pattern analysis, holistic evidence weighing |
| **Sonnet** (efficient execution) | Claude Sonnet | Front Desk, Claims Officer, Finance | Structured extraction, rule-based matching, deterministic calculation |

### Why Not All Opus?

Cost and latency scale with model capability. Using Opus for every agent would increase processing time and cost without proportional benefit. Front Desk categorization, Claims Officer exclusion checking, and Finance payment calculation follow well-defined patterns that Sonnet handles reliably.

### Why Not All Sonnet?

The Assessor's damage estimation requires synthesizing multiple cost categories with professional judgment. The Fraud Analyst's pattern convergence analysis demands deep cross-referencing. The Senior Reviewer's evidence-weighing decision and the Router's state machine management require the highest reasoning capability. These tasks benefit measurably from Opus's reasoning depth.

### The Principle

**Match model capability to task complexity.** Structured tasks get Sonnet. Judgment tasks get Opus. The Router gets Opus because orchestration errors cascade through the entire pipeline.

---

## Tool Scoping Rationale

Every agent gets exactly the tools it needs and nothing more. This follows the principle of least privilege.

### Tool Access Matrix

| Tool | Router | Front Desk | Claims Officer | Assessor | Fraud Analyst | Senior Reviewer | Finance |
|------|--------|------------|----------------|----------|---------------|-----------------|---------|
| read | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| write | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| exec | Yes | -- | -- | -- | -- | -- | Yes |
| sessions_spawn | Yes | -- | -- | -- | -- | -- | -- |
| sessions_list | Yes | -- | -- | -- | -- | -- | -- |
| sessions_history | Yes | -- | -- | -- | -- | -- | -- |
| session_status | Yes | -- | -- | -- | -- | -- | -- |
| browser | -- | -- | -- | -- | -- | -- | -- |
| gateway | -- | -- | -- | -- | -- | -- | -- |

### Why This Distribution

- **read/write:** Universal because every agent reads the claim file and writes its section. This is the minimum viable toolset.
- **exec:** Only Router (helper scripts) and Finance (payment simulation). No other agent needs to execute arbitrary commands. Giving exec to a fraud analyst or assessor would create unnecessary security surface.
- **sessions_spawn/list/history/status:** Router only. These are orchestration tools. If pipeline agents could spawn sub-agents, the depth constraint (maxSpawnDepth=1) would be violated, and the clean sequential pipeline would break down.
- **browser/gateway:** No agent needs web access or gateway administration. Claims processing works entirely with local JSON files.

---

*Agent documentation for: Ohio Mutual Auto Claims Processing System*
*7 agents, 6 pipeline stages, 1 orchestrator*
*Built on OpenClaw framework with Claude Opus and Sonnet models*
