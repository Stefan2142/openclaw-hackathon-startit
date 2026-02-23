# Ohio Mutual Auto -- System Architecture

Comprehensive architecture documentation for the multi-agent auto insurance claims processing system built on OpenClaw. This document provides judges and team members with a visual and technical understanding of how the system works, why it is designed this way, and how each component interacts.

---

## 1. System Overview

```
+=========================================================================+
|                           INBOUND LAYER                                 |
|                                                                         |
|   WebChat / Slack / CLI                                                 |
|          |                                                              |
|          v                                                              |
|   OpenClaw Gateway (localhost:18789)                                    |
|          |                                                              |
|          v  bindings: all inbound --> router (default agent)            |
+=========================================================================+
          |
          v
+=========================================================================+
|                       ORCHESTRATION LAYER (depth-0)                     |
|                                                                         |
|   +---------------------------------------------------------------+    |
|   |  ROUTER  (Claims Router)                                      |    |
|   |  Model: Claude Opus 4.6                                       |    |
|   |  Tools: read, write, exec, sessions_spawn/list/history/status |    |
|   |                                                                |    |
|   |  Responsibilities:                                             |    |
|   |    - Receive claim submissions (FNOL trigger)                  |    |
|   |    - Generate claim ID (CLM-YYYY-NNNNN)                       |    |
|   |    - Write initial claim JSON to shared/state/claims/          |    |
|   |    - Spawn pipeline agents SEQUENTIALLY via sessions_spawn     |    |
|   |    - Validate stage outputs after each announce                |    |
|   |    - Manage state transitions (9-state machine)                |    |
|   |    - Handle errors, retries, and escalations                   |    |
|   |    - Enrich task messages with regulatory context              |    |
|   +---------------------------------------------------------------+    |
|          |         |         |         |         |         |            |
+=========================================================================+
           |         |         |         |         |         |
           v         v         v         v         v         v
           sessions_spawn (one at a time, sequential)
+=========================================================================+
|                    PIPELINE LAYER (depth-1 sub-agents)                  |
|                                                                         |
|   Stage 1        Stage 2          Stage 3        Stage 4               |
|   +-----------+  +---------------+ +-----------+ +--------------+      |
|   | Front     |  | Claims        | | Assessor  | | Fraud        |      |
|   | Desk      |  | Officer       | |           | | Analyst      |      |
|   | (Sonnet)  |  | (Sonnet)      | | (Opus)    | | (Opus)       |      |
|   +-----------+  +---------------+ +-----------+ +--------------+      |
|                                                                         |
|   Stage 5                    Stage 6                                    |
|   +--------------------+    +-----------+                               |
|   | Senior Reviewer    |    | Finance   |                               |
|   | (Opus)             |    | (Sonnet)  |                               |
|   +--------------------+    +-----------+                               |
|                                                                         |
|   Each sub-agent:                                                       |
|     - Runs in its own session (agent:<id>:subagent:<uuid>)             |
|     - Receives AGENTS.md + TOOLS.md only (no SOUL.md)                  |
|     - Reads claim JSON from shared/state/claims/<CLM-ID>.json          |
|     - Writes its pipeline section + appends audit_log entry            |
|     - Announces result back to Router (SUCCESS/ERROR/ESCALATE)         |
|     - Tools: read + write only (except Finance: read + write + exec)   |
+=========================================================================+
           |
           v  announce results flow up to Router
+=========================================================================+
|                         STATE LAYER (shared filesystem)                 |
|                                                                         |
|   shared/                                                               |
|   +-- state/claims/         One JSON file per claim (in-flight)        |
|   |   +-- CLM-2026-00001.json                                          |
|   |   +-- CLM-2026-00002.json                                          |
|   +-- policies/             Mock policy database (5 pre-built)         |
|   |   +-- POL-AUT-10001.json  (standard active)                       |
|   |   +-- POL-AUT-10002.json  (lapsed)                                |
|   |   +-- POL-AUT-10003.json  (excluded driver)                       |
|   |   +-- POL-AUT-10004.json  (high deductible)                       |
|   |   +-- POL-AUT-10005.json  (comprehensive-only)                    |
|   +-- schemas/              JSON Schema contract                       |
|   |   +-- claim.schema.json                                            |
|   +-- uploads/              Photo attachments per claim                |
|   +-- test-claims/          Pre-built test scenarios                   |
+=========================================================================+
```

---

## 2. Pipeline Flow

### Happy Path: Full Pipeline Through Payment

```
Claim Submission (FNOL)
    |
    v
[Router] Generate CLM-ID, write initial JSON (status: FNOL_RECEIVED)
    |
    v
[Stage 1: Front Desk] ---- FNOL intake, categorize, prioritize
    |                        Reads: claim JSON
    |                        Writes: category, priority, missing_info
    |                        Announces: SUCCESS
    v
[Router] Validate front_desk.completed_at, category, priority
    |    Construct policy path from claimant.policy_id
    v
[Stage 2: Claims Officer] -- Verify coverage, check exclusions
    |                         Reads: claim JSON + policy JSON
    |                         Writes: covered, deductible, limit, exclusions
    |                         Announces: SUCCESS (covered=true)
    v
[Router] Validate covered=true, deductible, limit populated
    |    Set status: COVERAGE_CHECKED
    v
[Stage 3: Assessor] -------- Estimate damage, total loss check
    |                         Reads: claim JSON + photo references
    |                         Writes: estimate, total_loss, ACV, parts rec
    |                         Announces: SUCCESS
    v
[Router] Validate estimate > 0, total_loss is boolean
    |    Set status: ASSESSED
    v
[Stage 4: Fraud Analyst] --- Risk scoring, pattern matching
    |                         Reads: full claim JSON (all prior stages)
    |                         Writes: risk_score, flags, recommendation
    |                         Announces: SUCCESS
    v
[Router] Validate risk_score, recommendation populated
    |    Set status: FRAUD_ANALYZED
    v
[Stage 5: Senior Reviewer] - Final decision, FCSP check
    |                         Reads: full claim JSON
    |                         Writes: decision, reasoning, timeline check
    |                         Announces: SUCCESS (decision=APPROVED)
    v
[Router] Validate decision=APPROVED, reasoning documented
    |    Set status: REVIEWED
    v
[Stage 6: Finance] --------- Calculate payment, apply deductible
    |                         Reads: full claim JSON
    |                         Writes: payment_amount, reference, subrogation
    |                         Announces: SUCCESS
    v
[Router] Validate payment, reference populated
    |    Set status: PAYMENT_ISSUED
    |    Write final audit_log entry
    v
[Announce outcome to requester]
```

### Denial Path: Coverage Denial Shortcut

```
[Stage 2: Claims Officer] -- covered=false, denial_reason documented
    |
    v
[Router] Detects covered=false
    |    Sets status: DENIED
    |    SKIPS: Assessor, Fraud Analyst, Finance
    v
[Stage 5: Senior Reviewer] - Reviews denial for bad faith risk
    |                         Modified task: "Review coverage denial"
    |                         Confirms or overrides denial
    v
[Router] Logs final denial
    |    Announces denial outcome
    v
[Pipeline terminates]

Why this shortcut exists:
- No point assessing damage on an uncovered claim
- No point analyzing fraud on a denied claim
- Senior Reviewer still reviews to prevent bad faith exposure
- Saves tokens and processing time
```

### Escalation Path: Human-in-the-Loop

```
[Any pipeline agent] -------- Identifies escalation trigger
    |                          Sets escalation fields in its section
    |                          Announces: ESCALATE
    v
[Router] Reads escalation details from claim JSON
    |    Constructs escalation record with full pipeline context:
    |      - trigger_type, trigger_reason, severity
    |      - key_findings + mitigating_factors
    |      - stages_completed, stages_remaining
    |      - regulatory_context (FCSP deadlines, urgency)
    |    Sets status: ESCALATED
    |    Writes escalation record to claim JSON
    |    STOPS pipeline (no further agent spawns)
    v
[Claim sits in ESCALATED status on disk]
    |
    v  (Human reviews claim JSON, sends resolution to Router)
    |
[Router] Receives human resolution (approve/deny/modify/investigate)
    |    Updates claim with human decision
    |    Logs resolution in audit_log
    |    Resumes pipeline from escalation point
    |    OR terminates if human denies
    v
[Pipeline continues or terminates based on resolution]

Seven escalation triggers (all reasoning-based, no hardcoded thresholds):
1. High fraud risk (converging indicators)
2. Significant claim value (relative to typical patterns)
3. Total loss determination (ACV judgment required)
4. Legal representation detected
5. Bad faith risk (approaching regulatory deadlines)
6. Coverage ambiguity (cannot resolve with confidence)
7. Prior fraud history (pattern of suspicious claims)
```

---

## 3. Agent Interaction Diagram

This diagram shows what each agent reads from and writes to the claim JSON, with the Router as the central mediator. No direct agent-to-agent communication exists (`agentToAgent: disabled`).

```
                        +------------------+
                        |     ROUTER       |
                        |  (depth-0 main)  |
                        +--------+---------+
                  creates |  validates |  enriches context
                 initial  |  outputs   |  for next stage
                 claim    |  between   |
                          |  stages    |
         +----------------+------------+------------------+
         |                |            |                  |
         v                v            v                  v
+--------+------+  +------+-------+  +-+----------+  +---+---------+
| FRONT DESK    |  | CLAIMS       |  | ASSESSOR   |  | FRAUD       |
| (Stage 1)     |  | OFFICER (2)  |  | (Stage 3)  |  | ANALYST (4) |
+---------------+  +--------------+  +------------+  +-------------+
| READS:        |  | READS:       |  | READS:     |  | READS:      |
| - claimant    |  | - front_desk |  | - claims_  |  | - front_    |
| - incident    |  |   results    |  |   officer  |  |   desk      |
|               |  | - policy     |  |   results  |  | - claims_   |
|               |  |   JSON file  |  | - incident |  |   officer   |
|               |  | - incident   |  |   photos   |  | - assessor  |
+---------------+  +--------------+  +------------+  |   results   |
| WRITES:       |  | WRITES:      |  | WRITES:    |  +-------------+
| - category    |  | - covered    |  | - repair_  |  | WRITES:     |
| - priority    |  | - deductible |  |   estimate |  | - risk_     |
| - missing_    |  | - coverage_  |  | - total_   |  |   score     |
|   info        |  |   limit      |  |   loss     |  | - flags     |
| - audit_log   |  | - exclusions |  | - ACV      |  | - recomm.   |
|   entry       |  | - denial_    |  | - parts_   |  | - audit_log |
+---------------+  |   reason     |  |   rec      |  |   entry     |
                   | - audit_log  |  | - audit_   |  +-------------+
                   |   entry      |  |   log      |
                   +--------------+  +------------+

+------------------+  +---------------+
| SENIOR REVIEWER  |  | FINANCE       |
| (Stage 5)        |  | (Stage 6)     |
+------------------+  +---------------+
| READS:           |  | READS:        |
| - ALL prior      |  | - ALL prior   |
|   pipeline       |  |   pipeline    |
|   stages         |  |   stages      |
| - full audit_log |  | - decision    |
+------------------+  | - estimate    |
| WRITES:          |  | - deductible  |
| - decision       |  | - limit       |
| - reasoning      |  +---------------+
| - conditions     |  | WRITES:       |
| - escalated_to_  |  | - payment_    |
|   human          |  |   amount      |
| - fcsp_timeline  |  | - deductible_ |
|   check          |  |   applied     |
| - audit_log      |  | - subrogation |
|   entry          |  | - payment_    |
+------------------+  |   reference   |
                      | - audit_log   |
                      |   entry       |
                      +---------------+

Data Flow Key:
  Router --> Agent:  Absolute file paths + enriched task context
  Agent --> Router:  Announce message (SUCCESS/ERROR/ESCALATE)
  All agents:        Read/write shared/state/claims/<CLM-ID>.json
  No direct agent-to-agent communication
```

---

## 4. State Transitions

### Claim Status State Machine

```
                                        (from any stage)
                                       +---> ESCALATED  (human review required)
                                       |
                                       +---> ERROR      (unrecoverable agent failure)
                                       |
 FNOL_RECEIVED ---> COVERAGE_CHECKED --+--> ASSESSED ---> FRAUD_ANALYZED ---> REVIEWED ---> PAYMENT_ISSUED
                         |                                                       |
                         |                                                       +---> DENIED
                         +---> DENIED
                        (coverage denial shortcut)

 Terminal States: PAYMENT_ISSUED, DENIED, ESCALATED, ERROR
 Non-terminal:    FNOL_RECEIVED, COVERAGE_CHECKED, ASSESSED, FRAUD_ANALYZED, REVIEWED
```

### Complete Transition Table

| From | To | Trigger | Validation |
|------|----|---------|------------|
| FNOL_RECEIVED | COVERAGE_CHECKED | Front Desk SUCCESS | category, priority, completed_at set |
| COVERAGE_CHECKED | ASSESSED | Claims Officer SUCCESS, covered=true | deductible, limit, exclusions populated |
| COVERAGE_CHECKED | DENIED | Claims Officer SUCCESS, covered=false | denial_reason documented |
| ASSESSED | FRAUD_ANALYZED | Assessor SUCCESS | repair_estimate or total_loss populated |
| FRAUD_ANALYZED | REVIEWED | Fraud Analyst SUCCESS | risk_score, recommendation populated |
| REVIEWED | PAYMENT_ISSUED | Senior Reviewer APPROVED, Finance SUCCESS | payment_amount, reference populated |
| REVIEWED | DENIED | Senior Reviewer DENIED | decision_reasoning documented |
| Any stage | ESCALATED | Any agent ESCALATE | escalation record constructed by Router |
| Any stage | ERROR | Agent timeout or 2 retries exhausted | error logged in audit_log |

### Status Ownership

Only the Router sets the top-level `status` field. Pipeline agents write their section data, but the Router reads, validates, and transitions status. This prevents inconsistent state from partial agent failures.

---

## 5. Tool Scoping Rationale

### Least-Privilege Principle

Each agent receives only the tools required for its specific function. No agent has more capability than its role demands. This demonstrates security awareness to judges and prevents unintended actions.

```
Tool Access Matrix:

                 read  write  exec  sessions_*  browser  gateway  cron
                 ----  -----  ----  ----------  -------  -------  ----
Router            Y      Y     Y       Y           N        N       N
Front Desk        Y      Y     N       N           N        N       N
Claims Officer    Y      Y     N       N           N        N       N
Assessor          Y      Y     N       N           N        N       N
Fraud Analyst     Y      Y     N       N           N        N       N
Senior Reviewer   Y      Y     N       N           N        N       N
Finance           Y      Y     Y       N           N        N       N
```

### Why the Router Gets Sessions Tools

The Router is the depth-0 main agent -- the only agent that orchestrates the pipeline. It needs:
- `sessions_spawn`: Spawn each pipeline agent sequentially
- `sessions_list`: Monitor active sub-agent sessions
- `sessions_history`: Read sub-agent transcripts for debugging failed stages
- `session_status`: Check if a spawned agent is still running

Pipeline agents (depth-1) have session tools denied. They are leaf workers that should never spawn further agents. This is enforced by both tool scoping AND `maxSpawnDepth: 1`.

### Why Finance Gets Exec

Finance is the only pipeline agent with `exec` access. It uses this to:
- Run a mock payment simulation script that generates a payment reference number
- Simulate the real-world integration point with a payment gateway

No other pipeline agent needs to execute scripts. Their work is reasoning and writing JSON -- pure read/write operations.

### Why All Pipeline Agents Have Read + Write Only

Pipeline agents need to:
- `read`: Read the claim JSON file (and for Claims Officer, the policy file)
- `write`: Write their results to their pipeline section and append to audit_log

They do NOT need:
- `exec`: Their work is LLM reasoning, not script execution (except Finance)
- `browser`: No external web access required
- `gateway`: No gateway administration
- `cron`: No scheduled operations
- `sessions_spawn`: Must not spawn sub-agents (enforced by tool scoping)

### Model Assignments

| Agent | Model | Rationale |
|-------|-------|-----------|
| Router | Opus 4.6 | Orchestration requires complex planning, error handling, and context enrichment |
| Front Desk | Sonnet 4.5 | Structured data extraction -- Sonnet is sufficient and cost-efficient |
| Claims Officer | Sonnet 4.5 | Policy lookup against structured JSON -- well-defined rules |
| Assessor | Opus 4.6 | Nuanced damage estimation from descriptions and photos -- benefits from strongest reasoning |
| Fraud Analyst | Opus 4.6 | Pattern recognition from incomplete data, adversarial scenarios -- requires top-tier reasoning |
| Senior Reviewer | Opus 4.6 | Final decision authority weighing conflicting signals -- high-stakes, needs best model |
| Finance | Sonnet 4.5 | Arithmetic and threshold checking -- deterministic enough for Sonnet |

Cost optimization: Opus for agents that need complex reasoning (Router, Assessor, Fraud Analyst, Senior Reviewer). Sonnet for agents with structured, deterministic tasks (Front Desk, Claims Officer, Finance). Prompt caching (`cacheRetention: short`) enabled on both models to reduce repeated AGENTS.md injection cost.

---

## 6. Key Design Principles

### Principle 1: AGENTS.md as Business Logic Container

All business rules, regulatory requirements, fraud patterns, and decision criteria live in each agent's AGENTS.md -- not in code. Agents reason from these instructions rather than executing hardcoded logic.

**Why this matters:**
- Satisfies the hackathon constraint: "Plan for human reasoning: your thinking should not be hardcoded"
- When the "secret addition" arrives, update the relevant AGENTS.md file -- no code changes needed
- Agents produce natural language reasoning in the audit log, making decisions transparent

**Critical OpenClaw behavior:** Sub-agents (depth-1) only receive AGENTS.md + TOOLS.md injected. They do NOT receive SOUL.md. Therefore ALL operating instructions must be in AGENTS.md. No SOUL.md files exist in any workspace.

### Principle 2: JSON Files as Integration Layer

The claim JSON file (`shared/state/claims/<CLM-ID>.json`) is the single source of truth and the API contract between all agents. No database, no message queue, no API calls between agents.

**Why JSON files, not a database:**
- Zero setup time (critical for 10-hour hackathon)
- Instantly readable during demo (`cat` the file, show judges real-time state changes)
- Fully auditable (every field change visible in the file)
- Native to OpenClaw filesystem tools (agents use read/write directly)
- No dependency to install, configure, or debug

**The claim schema (`claim.schema.json`) defines:**
- 9 claim statuses in the state machine
- 6 pipeline sections (one per agent)
- Audit log format with reasoning and regulation references
- 88 documented fields across all sections

### Principle 3: Sequential Pipeline for Correctness

Agents are spawned one at a time. Stage N+1 does not start until Stage N announces completion. This is a correctness choice, not a performance limitation.

**Why sequential, not parallel:**
- Fraud analysis NEEDS the damage estimate to flag inflated repairs
- Senior Reviewer NEEDS the fraud score to make an informed decision
- Coverage denial SHORTCUTS the pipeline (skips stages 3, 4, 6)
- Single-writer-per-claim eliminates all race conditions and file locking complexity

### Principle 4: Reasoning Frameworks Over Hardcoded Rules

Every decision point uses judgment principles rather than numerical thresholds.

**Examples:**
- Fraud detection: "When multiple indicators converge into a pattern" (not "if risk_score > 70")
- Total loss: "When repair cost approaches or exceeds the threshold relative to ACV" (not "if repair > 75% * ACV")
- Escalation: "When the claim's value is significant relative to typical patterns" (not "if amount > $25,000")

**Why this matters for judging:**
- Judges can ask "what if the threshold were different?" -- the system adapts naturally
- The "secret addition" may change business context -- reasoning frameworks accommodate this
- Real insurance companies use guidelines, not rigid cutoffs

### Principle 5: Router as Single Point of Orchestration

The Router mediates all communication. No agent talks directly to another agent. `agentToAgent` is explicitly disabled in `openclaw.json`.

**Benefits:**
- Complete audit trail (Router logs every transition)
- Router maintains full visibility of pipeline state
- Errors and escalations flow through a single handler
- Context enrichment happens at one point (Router injects regulatory context into each task message)

---

## 7. Configuration Reference

### openclaw.json Key Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| `maxSpawnDepth` | 1 | Router (depth-0) spawns pipeline agents (depth-1). No nesting needed. |
| `maxChildrenPerAgent` | 6 | One slot per pipeline stage. All 6 can be active for different claims. |
| `maxConcurrent` | 6 | Matches maxChildrenPerAgent for full concurrent claim support. |
| `archiveAfterMinutes` | 120 | Keep session data for 2 hours -- enough for hackathon demo and debugging. |
| `agentToAgent.enabled` | false | All communication through claim JSON + Router mediation. |
| `cacheRetention` | "short" | Prompt caching reduces token cost for repeated AGENTS.md injection. |
| Router `allowAgents` | [6 agent IDs] | Explicit list (not wildcard) -- least-privilege for spawn targeting. |

### File Structure

```
ohio-mutual-hackathon/
+-- openclaw.json              # Gateway config: 7 agents, models, tools, subagents
+-- .env.example               # Environment template (API keys, port, log level)
+-- workspaces/
|   +-- router/AGENTS.md       # Orchestration state machine
|   +-- front-desk/AGENTS.md   # FNOL intake logic
|   +-- claims-officer/AGENTS.md # Coverage verification
|   +-- assessor/AGENTS.md     # Damage estimation
|   +-- fraud-analyst/AGENTS.md # Fraud detection
|   +-- senior-reviewer/AGENTS.md # Final decisions
|   +-- finance/AGENTS.md      # Payment processing
+-- shared/
|   +-- schemas/claim.schema.json  # Contract between all agents
|   +-- state/claims/              # Runtime claim files
|   +-- policies/                  # 5 mock policy records
|   +-- uploads/                   # Photo attachments
|   +-- test-claims/               # Pre-built test scenarios
+-- scripts/
|   +-- setup.sh               # One-touch VPS provisioning
|   +-- submit-claim.sh        # Submit test claims
|   +-- check-status.sh        # Inspect claim status
|   +-- run-demo.sh            # Full pipeline demo
+-- architecture/              # Detailed design specs
+-- docs/                      # Judge-facing documentation
```

---

*Architecture documentation for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
