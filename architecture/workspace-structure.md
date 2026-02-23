# Agent Workspace Structure

This document defines the workspace layout for all 7 agents in the Ohio Mutual Auto Claims Processing System. Each agent has an isolated workspace directory containing its AGENTS.md operating instructions. The workspace paths match the `openclaw.json` agent registrations exactly.

---

## Workspace Layout Diagram

```
workspaces/
├── router/
│   └── AGENTS.md     (state machine, spawn patterns, error handling, context enrichment)
├── front-desk/
│   └── AGENTS.md     (FNOL intake, categorization, completeness check, domain knowledge)
├── claims-officer/
│   └── AGENTS.md     (policy lookup, coverage verification, exclusion analysis, domain knowledge)
├── assessor/
│   └── AGENTS.md     (damage estimation, total loss determination, photo analysis, domain knowledge)
├── fraud-analyst/
│   └── AGENTS.md     (fraud pattern catalog, risk scoring, SIU referral criteria, domain knowledge)
├── senior-reviewer/
│   └── AGENTS.md     (final decision authority, compliance check, escalation triggers, domain knowledge)
└── finance/
    └── AGENTS.md     (payment calculation, deductible/depreciation application, subrogation, domain knowledge)
```

---

## Why No SOUL.md in Sub-Agent Workspaces

**Critical OpenClaw behavior:** Sub-agents (depth-1 agents spawned via sessions_spawn) receive ONLY `AGENTS.md` and `TOOLS.md` injected into their context. They do NOT receive `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, or `BOOTSTRAP.md`.

This means:
- **SOUL.md placed in a sub-agent workspace is never read.** It wastes disk space and misleads developers.
- **All operating instructions -- including role personality, behavioral constraints, and domain expertise -- must be embedded in AGENTS.md.**
- The Router is the only agent that runs as a depth-0 main agent, so it is the only agent where SOUL.md would be injected. However, for consistency and simplicity, we keep all agents with AGENTS.md only.

**Design decision:** No SOUL.md files in any workspace. All agent behavior defined in AGENTS.md exclusively. This eliminates the pitfall of placing critical instructions in a file that sub-agents never see.

---

## Agent Workspace Specifications

### 1. Router (workspaces/router/)

**OpenClaw Config Reference:**
```json
{
  "id": "router",
  "name": "Claims Router",
  "default": true,
  "workspace": "./workspaces/router",
  "model": "anthropic/claude-opus-4-6"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Complete orchestration logic (see architecture/router-design.md for spec)

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read claim files, policy files, agent outputs |
| write | ALLOW | Write initial claim JSON, update status and audit_log |
| exec | ALLOW | Execute helper scripts (demo, status checks) |
| sessions_spawn | ALLOW | Spawn pipeline agents -- core orchestration capability |
| sessions_list | ALLOW | List active sub-agent sessions for monitoring |
| sessions_history | ALLOW | Read sub-agent transcripts for debugging |
| session_status | ALLOW | Check sub-agent run status |
| browser | DENY | No web access needed |
| gateway | DENY | No gateway admin access |
| cron | DENY | No scheduled tasks |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads after each stage completes to validate output
- `shared/policies/{POLICY_ID}.json` -- reads policy_id to construct path for claims-officer task message

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes initial claim record, updates status and audit_log between stages

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (orchestrator personality embedded)
2. State Machine Definition (complete transition table)
3. Sequential Spawn Protocol (announce-wait-read-spawn cycle)
4. Task Message Construction (per-stage templates with context injection)
5. Error Handling and Retry Policy
6. Escalation Handling Protocol
7. Audit Logging Requirements
8. Regulatory Timeline Awareness

---

### 2. Front Desk (workspaces/front-desk/)

**OpenClaw Config Reference:**
```json
{
  "id": "front-desk",
  "name": "Front Desk",
  "workspace": "./workspaces/front-desk",
  "model": "anthropic/claude-sonnet-4-5"
}
```

**Workspace Contents:**
- `AGENTS.md` -- FNOL intake, categorization, and completeness assessment

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read claim file to process FNOL data |
| write | ALLOW | Write intake results to pipeline.front_desk and audit_log |
| exec | DENY | No code execution needed -- structured data extraction only |
| browser | DENY | No web access needed |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads the raw claim submitted by the claimant

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.front_desk` section (category, priority, missing_info), updates status, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (professional intake coordinator personality)
2. FNOL Processing Checklist (what to extract, verify, flag)
3. Claim Categorization Criteria (standard, complex, CAT event, multi-vehicle)
4. Priority Assignment Framework (severity, injuries, time sensitivity)
5. Completeness Assessment (required vs optional fields, missing info identification)
6. Domain Knowledge: FNOL lifecycle from Phase 1 research
7. Output Format (exact fields to write to pipeline.front_desk)
8. Announce Protocol (how to format SUCCESS/ERROR announce)

---

### 3. Claims Officer (workspaces/claims-officer/)

**OpenClaw Config Reference:**
```json
{
  "id": "claims-officer",
  "name": "Claims Officer",
  "workspace": "./workspaces/claims-officer",
  "model": "anthropic/claude-sonnet-4-5"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Coverage verification, policy analysis, and exclusion checking

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read claim file AND policy file -- this agent reads two files |
| write | ALLOW | Write coverage results to pipeline.claims_officer and audit_log |
| exec | DENY | No code execution -- coverage analysis is reasoning, not computation |
| browser | DENY | No web access |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads claim for incident details and front-desk results
- `shared/policies/{POLICY_ID}.json` -- reads the claimant's policy (path provided in task message by Router)

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.claims_officer` section (covered, deductible, limit, exclusions_checked, denial_reason), updates status, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (meticulous coverage analyst personality)
2. Policy Lookup Protocol (how to read policy JSON, what fields to check)
3. Coverage Verification Framework (matching incident type to coverage type)
4. Exclusion Analysis Checklist (excluded drivers, lapsed policies, coverage gaps)
5. Denial Documentation Requirements (FCSP Act compliance)
6. UM/UIM Routing Logic (when to set um_uim_route)
7. Domain Knowledge: Coverage verification from Phase 1 research
8. Output Format (exact fields to write to pipeline.claims_officer)
9. Announce Protocol

---

### 4. Assessor (workspaces/assessor/)

**OpenClaw Config Reference:**
```json
{
  "id": "assessor",
  "name": "Assessor",
  "workspace": "./workspaces/assessor",
  "model": "anthropic/claude-opus-4-6"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Damage estimation, total loss determination, and repair recommendation

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read claim file and photo file paths (photos as path references and descriptions) |
| write | ALLOW | Write assessment results to pipeline.assessor and audit_log |
| exec | DENY | No code execution -- estimation is professional judgment, not calculation scripts |
| browser | DENY | No web access |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads claim for incident description, photos paths, and prior stage results
- `shared/uploads/{CLAIM_ID}/*.jpg` -- photo file references (descriptions inform assessment, not ML inference)

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.assessor` section (estimate, total_loss, ACV, parts recommendation, labor hours, pre-existing flags), updates status, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (experienced damage appraiser personality)
2. Damage Assessment Methodology (systematic estimation approach)
3. Total Loss Determination Framework (ACV comparison, Ohio threshold)
4. Parts Recommendation Criteria (OEM vs aftermarket, vehicle age/mileage/safety)
5. Pre-existing Damage Detection (indicators, cross-reference to fraud)
6. Photo Analysis Protocol (what to look for in damage photos by description)
7. Domain Knowledge: Damage assessment from Phase 1 research
8. Output Format (exact fields to write to pipeline.assessor)
9. Announce Protocol

---

### 5. Fraud Analyst (workspaces/fraud-analyst/)

**OpenClaw Config Reference:**
```json
{
  "id": "fraud-analyst",
  "name": "Fraud Analyst",
  "workspace": "./workspaces/fraud-analyst",
  "model": "anthropic/claude-opus-4-6"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Fraud pattern detection, risk scoring, and SIU referral assessment

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read entire claim file (all prior stages) for cross-reference analysis |
| write | ALLOW | Write fraud analysis to pipeline.fraud_analyst and audit_log |
| exec | DENY | No code execution -- fraud detection is pattern recognition, not scripts |
| browser | DENY | No web access |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads FULL claim including all prior pipeline stages for pattern analysis

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.fraud_analyst` section (risk_score, risk_level, flags, recommendation), updates status, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (skeptical investigator personality)
2. Fraud Pattern Catalog (staged accidents, phantom passengers, inflated repairs, prior damage, VIN switching)
3. Indicator Convergence Framework (single flag vs converging indicators vs pattern match)
4. Risk Scoring Methodology (how to assign 0-100 score based on indicator convergence)
5. Soft vs Hard Fraud Distinction
6. SIU Referral Criteria (when REFER_SIU is warranted)
7. Cross-Reference Analysis (assessor estimate vs description consistency, timing patterns)
8. Domain Knowledge: Fraud detection from Phase 1 research
9. Output Format (exact fields to write to pipeline.fraud_analyst)
10. Announce Protocol (including ESCALATE for critical risk)

---

### 6. Senior Reviewer (workspaces/senior-reviewer/)

**OpenClaw Config Reference:**
```json
{
  "id": "senior-reviewer",
  "name": "Senior Reviewer",
  "workspace": "./workspaces/senior-reviewer",
  "model": "anthropic/claude-opus-4-6"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Final decision authority, compliance verification, and escalation judgment

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read entire claim file including all 4 prior pipeline stages |
| write | ALLOW | Write final decision to pipeline.senior_reviewer and audit_log |
| exec | DENY | No code execution -- decisions are reasoned judgment |
| browser | DENY | No web access |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads FULL claim with all prior pipeline results for final weighing

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.senior_reviewer` section (decision, reasoning, conditions, escalation), updates status, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (authoritative decision-maker personality)
2. Evidence Weighing Framework (how to balance coverage, assessment, fraud signals)
3. Decision Criteria (APPROVED, DENIED, CONDITIONAL, ESCALATE_HUMAN triggers)
4. FCSP Timeline Compliance Check (calculate deadlines from submitted_at)
5. Bad Faith Risk Assessment (when denial could trigger bad faith liability)
6. Escalation Judgment (when AI should defer to human)
7. Domain Knowledge: Regulatory compliance and edge cases from Phase 1 research
8. Output Format (exact fields to write to pipeline.senior_reviewer)
9. Announce Protocol (including ESCALATE for human-required decisions)

---

### 7. Finance (workspaces/finance/)

**OpenClaw Config Reference:**
```json
{
  "id": "finance",
  "name": "Finance",
  "workspace": "./workspaces/finance",
  "model": "anthropic/claude-sonnet-4-5"
}
```

**Workspace Contents:**
- `AGENTS.md` -- Payment calculation, deductible application, and disbursement recording

**Tool Scoping:**
| Tool | Access | Rationale |
|------|--------|-----------|
| read | ALLOW | Read claim file for approved amount, deductible, depreciation parameters |
| write | ALLOW | Write payment record to pipeline.finance and audit_log |
| exec | ALLOW | Execute payment simulation script (mock disbursement for demo) |
| browser | DENY | No web access |
| gateway | DENY | No gateway admin |
| cron | DENY | No scheduled tasks |
| sessions_spawn | DENY | Sub-agent, must not spawn further agents |

**Why Finance gets exec:** Finance is the only pipeline agent with `exec` access. It uses this to run a mock payment simulation script that generates a payment reference number. This simulates the real-world integration with a payment gateway. No other agent needs to execute scripts.

**Reads from shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- reads claim for approved amount, assessor estimate, deductible, coverage limit, conditions

**Writes to shared/:**
- `shared/state/claims/{CLAIM_ID}.json` -- writes `pipeline.finance` section (payment_amount, deductible applied, depreciation, subrogation flag, payment reference), updates status to PAYMENT_ISSUED, appends audit_log

**AGENTS.md Content Scope (Phase 3 fills these sections):**
1. Role and Identity (precise financial processor personality)
2. Payment Calculation Formula (estimate - deductible - depreciation, capped at coverage limit)
3. Deductible Application Rules (which deductible applies based on coverage type)
4. Depreciation Methodology (when and how to apply depreciation)
5. Subrogation Assessment (when to flag for recovery from other party's insurer)
6. Payment Method Selection (direct deposit, check, repair shop direct)
7. Domain Knowledge: Payment/subrogation from Phase 1 research
8. Output Format (exact fields to write to pipeline.finance)
9. Announce Protocol

---

## Cross-Agent File Access Summary

| Agent | Reads | Writes |
|-------|-------|--------|
| router | claims/*.json, policies/*.json | claims/*.json (initial + status updates) |
| front-desk | claims/{ID}.json | claims/{ID}.json (pipeline.front_desk) |
| claims-officer | claims/{ID}.json, policies/{POL_ID}.json | claims/{ID}.json (pipeline.claims_officer) |
| assessor | claims/{ID}.json, uploads/{ID}/* | claims/{ID}.json (pipeline.assessor) |
| fraud-analyst | claims/{ID}.json | claims/{ID}.json (pipeline.fraud_analyst) |
| senior-reviewer | claims/{ID}.json | claims/{ID}.json (pipeline.senior_reviewer) |
| finance | claims/{ID}.json | claims/{ID}.json (pipeline.finance) |

All paths are absolute, constructed by the Router and passed in task messages. Agents never construct their own paths to shared/ files.

---

*Architecture specification for: Agent Workspace Structure*
*Phase 02, Plan 02 of Ohio Mutual Auto Claims Processing System*
