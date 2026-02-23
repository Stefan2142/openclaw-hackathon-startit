# Architecture Research

**Domain:** Multi-agent auto insurance claims processing on OpenClaw
**Researched:** 2026-02-17
**Confidence:** HIGH — based directly on OpenClaw official docs in `reference/openclaw-docs/`

---

## Recommended Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                         INBOUND LAYER                                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Channel (Slack/WebChat/CLI) → OpenClaw Gateway (port 18789)    │   │
│  └─────────────────────────┬───────────────────────────────────────┘   │
└────────────────────────────┼───────────────────────────────────────────┘
                             │ bindings: route all claims → router agent
┌────────────────────────────▼───────────────────────────────────────────┐
│                      ORCHESTRATION LAYER                               │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  router (agentId: "router") — depth-0 main agent              │     │
│  │  Workspace: workspaces/router/  — AGENTS.md drives logic      │     │
│  │  Tools: sessions_spawn, sessions_list, sessions_history,       │     │
│  │         read, write, exec (for file I/O on claim state)        │     │
│  │                                                                │     │
│  │  Responsibilities:                                             │     │
│  │    - Receive claim trigger (FNOL submission)                   │     │
│  │    - Write initial claim JSON to shared/state/claims/          │     │
│  │    - Spawn depth-1 pipeline agents sequentially (see below)    │     │
│  │    - Read announce results after each stage completes          │     │
│  │    - Decide: proceed / escalate / retry / halt                 │     │
│  │    - Update claim status after each stage                      │     │
│  └────────┬──────────┬──────────┬──────────┬──────────┬──────────┘     │
└────────────┼──────────┼──────────┼──────────┼──────────┼───────────────┘
             │ sessions_spawn (sequential, not parallel — see note)
┌────────────▼──────────▼──────────▼──────────▼──────────▼───────────────┐
│                        PIPELINE LAYER (depth-1 sub-agents)             │
│                                                                        │
│  Stage 1           Stage 2          Stage 3          Stage 4           │
│  ┌──────────┐   ┌──────────────┐  ┌──────────┐  ┌──────────────┐      │
│  │front-desk│   │claims-officer│  │ assessor │  │fraud-analyst │      │
│  └──────────┘   └──────────────┘  └──────────┘  └──────────────┘      │
│                                                                        │
│  Stage 5                   Stage 6                                     │
│  ┌────────────────┐     ┌─────────┐                                    │
│  │senior-reviewer │     │ finance │                                    │
│  └────────────────┘     └─────────┘                                    │
│                                                                        │
│  Each sub-agent:                                                       │
│  - Runs in own session: agent:<agentId>:subagent:<uuid>                │
│  - Reads claim JSON from shared/state/claims/<CLM-ID>.json             │
│  - Writes its section + appends audit_log entry                        │
│  - Announces result back to router (success/error + summary)           │
└────────────────────────────────────────────────────────────────────────┘
                             │ announce (result flows up)
┌────────────────────────────▼───────────────────────────────────────────┐
│                          STATE LAYER                                   │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  shared/state/claims/<CLM-ID>.json  — the claim record        │     │
│  │  (plain JSON files on the filesystem — all agents share CWD)  │     │
│  └───────────────────────────────────────────────────────────────┘     │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  shared/policies/<POLICY-ID>.json  — mock policy database     │     │
│  └───────────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Orchestration Pattern

**Decision: Sequential pipeline via sessions_spawn, not parallel.**

The router spawns each pipeline agent sequentially — each stage only starts after the previous announces completion. This is not a performance choice; it is a correctness choice: fraud analysis cannot run before damage assessment produces a repair estimate to flag as inflated; the Senior Reviewer cannot make a final decision before fraud analysis completes.

**How it works (OpenClaw primitives):**

- `maxSpawnDepth: 2` is NOT needed. The router is depth-0; pipeline agents are depth-1. Pipeline agents do NOT need to spawn their own children. Set `maxSpawnDepth: 1` (the default).
- The router calls `sessions_spawn` for Stage 1, then WAITS. The announce from Stage 1 returns to the router's session. The router reads the announce (success/error), checks the updated claim file, then calls `sessions_spawn` for Stage 2.
- This is not blocking in the traditional sense: `sessions_spawn` returns immediately with `{ status: "accepted", runId, childSessionKey }`. The router then uses `sessions_history` on the child session key to poll for completion, or relies on the announce message arriving in the router's chat session.

**State machine for each claim:**

```
NEW → INTAKE → COVERAGE_CHECK → ASSESSING → FRAUD_REVIEW
    → FINAL_REVIEW → PAYMENT_PROCESSING → SETTLED
    → REJECTED (from any stage)
    → ESCALATED (human-in-the-loop pause)
    → ERROR (agent failure, retry pending)
```

The router owns state transitions. It reads the claim JSON after each announce, determines current `status`, and decides the next action.

**Configuration:**

```json5
{
  agents: {
    defaults: {
      subagents: {
        maxSpawnDepth: 1,        // Default — pipeline agents are leaves
        maxChildrenPerAgent: 6,  // Up to 6 active sub-agents (one per stage max)
        maxConcurrent: 6,        // Claims processed sequentially per claim, but multiple claims in parallel
        archiveAfterMinutes: 120
      }
    }
  }
}
```

---

## 2. Hand-off Protocol

**The claim JSON file is the contract between agents.**

Every agent reads the claim file, does its work, writes its result section, appends to audit_log, and announces completion. The file is the single source of truth; agent sessions carry no inter-agent state.

**Claim record schema (shared/schemas/claim.schema.json):**

```json
{
  "claim_id": "CLM-2026-00001",
  "status": "FRAUD_REVIEW",
  "submitted_at": "2026-02-21T10:23:00Z",
  "claimant": {
    "policy_id": "POL-AUT-98765",
    "name": "...",
    "contact": "..."
  },
  "incident": {
    "date": "2026-02-20",
    "type": "collision",
    "description": "...",
    "photos": ["shared/uploads/CLM-2026-00001/photo1.jpg"]
  },
  "pipeline": {
    "front_desk": {
      "completed_at": null,
      "agent_session": null,
      "category": null,
      "priority": null,
      "completeness_score": null,
      "missing_info": []
    },
    "claims_officer": {
      "completed_at": null,
      "agent_session": null,
      "covered": null,
      "policy_type": null,
      "deductible_amount": null,
      "coverage_limit": null,
      "exclusions_checked": [],
      "denial_reason": null
    },
    "assessor": {
      "completed_at": null,
      "agent_session": null,
      "repair_estimate_usd": null,
      "total_loss": false,
      "total_loss_threshold_pct": null,
      "parts_recommendation": null,
      "labor_hours": null,
      "diminished_value_usd": null
    },
    "fraud_analyst": {
      "completed_at": null,
      "agent_session": null,
      "risk_score": null,
      "flags": [],
      "recommendation": null
    },
    "senior_reviewer": {
      "completed_at": null,
      "agent_session": null,
      "decision": null,
      "decision_reasoning": null,
      "escalated_to_human": false,
      "escalation_reason": null
    },
    "finance": {
      "completed_at": null,
      "agent_session": null,
      "payment_amount_usd": null,
      "deductible_applied": null,
      "depreciation_applied": null,
      "subrogation_candidate": false,
      "payment_reference": null
    }
  },
  "audit_log": [
    {
      "timestamp": "2026-02-21T10:23:00Z",
      "agent": "router",
      "action": "claim_registered",
      "reasoning": "..."
    }
  ]
}
```

**Validation between stages:**

Each pipeline agent validates the claim file has the required prior stage data before proceeding. If prior stage data is missing or status is wrong, the agent announces `ERROR` and the router triggers a retry or human escalation.

**Hand-off task message format (what sessions_spawn.task contains):**

```
Process auto insurance claim CLM-2026-00001.

Claim file: /path/to/shared/state/claims/CLM-2026-00001.json

Your role: [ROLE DESCRIPTION from AGENTS.md]

Instructions:
1. Read the claim file
2. Verify all required prior stages are complete (check pipeline.[prev_stage].completed_at)
3. Do your analysis per your AGENTS.md instructions
4. Write your results to the claim file pipeline.[your_section] fields
5. Append an entry to audit_log with your reasoning
6. Set claim status to [NEXT_STATUS]
7. Announce: SUCCESS if complete, ERROR if blocked, ESCALATE if human review needed

If the claim requires human review, set pipeline.senior_reviewer.escalated_to_human = true
and stop. Do not proceed further.
```

---

## 3. Shared State Management

**Decision: JSON files on shared filesystem. No database. No SQLite.**

**Justification for hackathon context:**

- All 7 OpenClaw agents run on the same gateway host. The shared filesystem IS the shared state store.
- OpenClaw workspaces use the filesystem as default CWD. Relative paths resolve inside the workspace; absolute paths reach the shared directory.
- JSON files give full auditability (git diff shows exactly what changed), zero setup overhead, and are self-documenting.
- For the hackathon demo, atomic write patterns (write to temp file, rename) prevent corruption from concurrent access.
- SQLite adds dependencies and debugging complexity. Postgres adds infrastructure. Both are wrong for a 10-hour hackathon.

**Directory structure:**

```
shared/
├── state/
│   └── claims/
│       ├── CLM-2026-00001.json   (one file per claim, in-flight)
│       └── CLM-2026-00002.json
├── policies/
│   ├── POL-AUT-98765.json        (mock policy records)
│   └── POL-AUT-99001.json
├── schemas/
│   └── claim.schema.json         (the schema above)
├── uploads/
│   └── CLM-2026-00001/
│       ├── photo1.jpg
│       └── photo2.jpg
└── test-claims/
    ├── happy-path.json
    ├── fraud-flag.json
    ├── no-coverage.json
    └── total-loss.json
```

**Concurrency handling:**

Multiple claims processed simultaneously = multiple claim files. Since each claim has its own file and each pipeline stage writes to a distinct section of that file, true conflicts only happen if the same claim has two pipeline stages running simultaneously — which cannot happen with the sequential-spawn pattern.

For the router writing the initial record and then the first sub-agent reading it: the router writes the file, the spawn is accepted, and the sub-agent's `task` message tells it which file to open. The file exists before the sub-agent starts.

**Workspace path access:**

The shared directory must be accessible from each agent's workspace. Use absolute paths in task messages. Config:

```json5
{
  agents: {
    list: [
      {
        id: "router",
        workspace: "./workspaces/router"
        // All task messages use absolute paths to shared/
      }
    ]
  }
}
```

---

## 4. Tool Inventory Per Agent

**Principle: least privilege. Each agent gets only what it needs for its stage.**

| Agent | Allow | Deny | Rationale |
|-------|-------|------|-----------|
| router | `read`, `write`, `exec`, `sessions_spawn`, `sessions_list`, `sessions_history`, `session_status` | `browser`, `gateway`, `cron` | Must spawn sub-agents, read/write claim files, check status |
| front-desk | `read`, `write` | `exec`, `browser`, `gateway`, `cron` | Reads policy info, writes claim intake. No code execution needed |
| claims-officer | `read`, `write` | `exec`, `browser`, `gateway`, `cron` | Reads policy files and claim, writes coverage decision. Read-heavy |
| assessor | `read`, `write` | `exec`, `browser`, `gateway`, `cron` | Reads photos (via path), reads claim, writes damage estimate |
| fraud-analyst | `read`, `write` | `exec`, `browser`, `gateway`, `cron` | Reads claim history patterns, writes risk score. Read-heavy |
| senior-reviewer | `read`, `write`, `message` | `exec`, `browser`, `gateway`, `cron` | Reads full claim, writes decision, can send human escalation message |
| finance | `read`, `write`, `exec` | `browser`, `gateway`, `cron` | Reads decision, writes payment record, exec for payment simulation script |

**OpenClaw config (per agent example — claims-officer):**

```json5
{
  id: "claims-officer",
  name: "Claims Officer",
  workspace: "./workspaces/claims-officer",
  tools: {
    allow: ["read", "write"],
    deny: ["exec", "browser", "gateway", "cron", "sessions_spawn", "sessions_send"]
  }
}
```

**Tool groups available (from docs):**

- `group:fs` expands to: `read`, `write`, `edit`, `apply_patch`
- `group:runtime` expands to: `exec`, `bash`, `process`
- `group:sessions` expands to: `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status`

Use deny lists for simplicity. Sub-agents already have session tools denied by default (as documented in subagents.md), so the router needs explicit session tool access via its main agent configuration.

**Critical doc note:** Sub-agents get all tools EXCEPT session tools by default. Pipeline agents (depth-1 sub-agents) therefore CANNOT call `sessions_spawn` themselves. This is correct — pipeline agents should not spawn further agents.

---

## 5. Intelligence Middleware

**What it is:** Logic the router applies between spawning each stage. Not a separate service — it lives in the router's AGENTS.md instructions.

**Pattern: Router as State Machine + Context Enricher**

After each sub-agent announces, the router:

1. Parses the announce result (success/error/escalate)
2. Reads the updated claim file
3. Validates stage output is complete and well-formed
4. Enriches context if needed (e.g., pulls regulatory deadline from shared reference data)
5. Decides: next stage, retry, escalate, halt
6. Writes router audit log entry
7. Spawns next stage with full enriched task context

**Audit logging (regulatory requirement):**

Every decision appended to `claim.audit_log[]` with:
- timestamp (ISO 8601)
- agent id
- action taken
- reasoning (the agent's actual reasoning, not a code)
- reference to any regulation or policy applied

This satisfies Fair Claims Settlement Practices Act documentation requirements and provides the demo "audit trail" judges look for.

**Context enrichment in task message:**

The router injects regulatory context directly into each spawn task. Example for Claims Officer:

```
Process coverage verification for CLM-2026-00001.

Claim file: /absolute/path/shared/state/claims/CLM-2026-00001.json
Policy file: /absolute/path/shared/policies/POL-AUT-98765.json

Regulatory context:
- Ohio: Coverage denial must be communicated within 15 business days
- Document all exclusions checked per FCSP Act Section 2695.7(b)
- If coverage is ambiguous, resolve in claimant's favor (ambiguity doctrine)

Business context:
- Ohio Mutual's combined ratio target is 95% — avoid unnecessary denials
- Claims under $500 net of deductible: recommend direct payment, skip subrogation
```

This is the "intelligence middleware" — the router's AGENTS.md contains these patterns and the router constructs enriched task messages. No separate process required.

---

## 6. Human-in-the-Loop

**Where escalations happen:**

| Trigger | Agent | Action |
|---------|-------|--------|
| Fraud risk score >= 0.7 | fraud-analyst | Set `escalated_to_human: true`, announce ESCALATE |
| Total loss claim > $50k | assessor | Set `escalated_to_human: true`, announce ESCALATE |
| Coverage denial (claimant dispute risk) | claims-officer | Set `escalated_to_human: true`, announce ESCALATE |
| Senior Reviewer cannot make definitive decision | senior-reviewer | Set `escalated_to_human: true`, announce ESCALATE |

**How the router handles ESCALATE announces:**

1. Router receives announce with `ESCALATE` status
2. Router updates claim status to `"ESCALATED"`
3. Router uses `message` tool (if senior-reviewer has it) or router uses a notification mechanism to alert human reviewer
4. Router STOPS spawning further stages
5. Claim file stays on disk in ESCALATED status
6. Human resolves via direct interaction with router agent (they send a message to the router session)
7. Router resumes pipeline from escalation point

**OpenClaw primitive used:** The `message` tool on senior-reviewer allows it to send a notification. The router can also be configured to post to a Slack channel or WebChat when escalation occurs.

**For the demo:** Escalated claims show "ESCALATED - AWAITING HUMAN REVIEW" status. This demonstrates compliance-conscious design — AI does not make unilateral decisions on high-stakes edge cases.

---

## 7. Error Handling

**Agent failure modes and router responses:**

| Failure | Detection | Router Action |
|---------|-----------|---------------|
| Sub-agent timeout | `runTimeoutSeconds` exceeded, announce `Status: timeout` | Retry once with higher `runTimeoutSeconds`; then ESCALATE |
| Sub-agent error (bad claim file) | Announce `Status: error` | Retry once; if repeat error, ESCALATE |
| Sub-agent validation failure (prior stage incomplete) | Agent announces ERROR with reason | Router checks if prior stage actually wrote data; if yes retry this stage; if no retry prior stage |
| Missing policy file | Claims-officer announces ERROR | Router escalates — cannot proceed without policy data |
| Claim JSON corrupt | Any agent | Router detects, marks ERROR, escalates |

**Retry policy:**

```
Router AGENTS.md should include:
- Max retries: 2 per stage
- Retry delay: none (sub-agents are non-blocking, retry is immediate re-spawn)
- After 2 failures: set status = "ERROR", write to audit_log, stop pipeline
- Router announces error to the original requester channel
```

**runTimeoutSeconds per stage:**

| Agent | Timeout |
|-------|---------|
| front-desk | 60s — intake is fast |
| claims-officer | 90s — policy lookup required |
| assessor | 120s — photo analysis is slow |
| fraud-analyst | 90s — pattern matching |
| senior-reviewer | 90s — reasoning required |
| finance | 60s — execution |

**Important doc note:** `sessions_spawn` announce is best-effort. If gateway restarts mid-pipeline, pending announces are lost. For the hackathon, this is acceptable. For production, use a persistent queue. The claim file on disk always reflects last known state, so recovery is possible by manually re-triggering from the last completed stage.

---

## 8. Database Choice

**Decision: JSON files. Not SQLite. Not Postgres.**

| Option | Verdict | Rationale |
|--------|---------|-----------|
| JSON files | USE THIS | Zero setup. Fully visible state. Git-trackable. Self-documenting. Works with OpenClaw filesystem tools natively. Perfect for demo (cat the file, show judges). |
| SQLite | Avoid | Adds a library dependency, requires schema migration, harder to inspect mid-demo. OpenClaw memory uses SQLite internally but that is for embeddings, not application state. |
| Postgres | Avoid | Requires a running database service, adds VPS setup complexity, inappropriate for 10-hour hackathon scope. |

**The demo advantage of JSON files:** During the live presentation, you can run `cat shared/state/claims/CLM-2026-00001.json` and show judges the actual claim record changing in real time as agents process it. No query needed. Maximum legibility. This is a hackathon win.

**File locking note:** Two agents writing to the same claim file simultaneously is impossible with the sequential spawn pattern. The router does not spawn Stage 2 until Stage 1's announce arrives. Single-writer-at-a-time by design.

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| OpenClaw Gateway | Routing, WS server, session management | All agents via internal session mechanism |
| router agent | Orchestration, state machine, spawning | All pipeline agents (via sessions_spawn), requester channel, shared filesystem |
| front-desk agent | FNOL intake, claim categorization, completeness check | shared/state/claims/, shared/policies/ |
| claims-officer agent | Policy lookup, coverage verification, exclusion check | shared/state/claims/, shared/policies/ |
| assessor agent | Damage estimation, total loss determination, photo analysis | shared/state/claims/, shared/uploads/ |
| fraud-analyst agent | Risk scoring, pattern matching, flag generation | shared/state/claims/ (reads full history context) |
| senior-reviewer agent | Final decision, human escalation trigger | shared/state/claims/, message tool for notifications |
| finance agent | Payment calc, deductible application, disbursement record | shared/state/claims/, exec for payment simulation |
| shared filesystem | Single source of truth for claim state | All agents (read/write via OpenClaw read/write tools) |

---

## Data Flow

### Happy Path Claim Flow

```
[Claimant submits claim via WebChat/Slack/CLI]
        |
        v
[OpenClaw Gateway receives message]
        |
        v [binding: all inbound → router]
[router - depth 0]
  - writes CLM-ID.json with status=NEW
  - sessions_spawn(agentId="front-desk", task="Process CLM-ID...")
        |
        v [async, router waits for announce]
[front-desk - depth 1]
  - reads CLM-ID.json
  - verifies completeness, categorizes
  - writes pipeline.front_desk section
  - sets status=COVERAGE_CHECK
  - appends audit_log
  - announces: SUCCESS
        |
        v [announce returns to router]
[router]
  - reads CLM-ID.json (status=COVERAGE_CHECK)
  - sessions_spawn(agentId="claims-officer", task="Verify coverage...")
        |
        v
[claims-officer - depth 1]
  - reads policy file + claim file
  - verifies coverage, checks exclusions
  - writes pipeline.claims_officer section
  - sets status=ASSESSING
  - announces: SUCCESS
        |
        v
[router → sessions_spawn → assessor]
  - damage estimation, photo analysis
  - sets status=FRAUD_REVIEW
        |
        v
[router → sessions_spawn → fraud-analyst]
  - risk scoring, flag generation
  - sets status=FINAL_REVIEW
  OR sets escalated_to_human=true, status=ESCALATED, announces ESCALATE
        |
        v (if not escalated)
[router → sessions_spawn → senior-reviewer]
  - final decision
  - sets status=PAYMENT_PROCESSING
  - OR escalates, OR rejects
        |
        v (if approved)
[router → sessions_spawn → finance]
  - calculates payment (estimate - deductible - depreciation)
  - writes payment record
  - sets status=SETTLED
  - announces: SUCCESS
        |
        v
[router announces final outcome to requester channel]
```

### Escalation Flow

```
[fraud-analyst announces: ESCALATE]
        |
        v
[router reads claim: escalated_to_human=true]
  - sets status=ESCALATED
  - records escalation in audit_log
  - posts notification to human channel (senior-reviewer or slack)
  - STOPS pipeline
        |
        v
[Human adjuster reviews, sends resolution message to router]
        |
        v
[router resumes: sessions_spawn(senior-reviewer, "Human cleared, proceed...")]
```

---

## Recommended Project Structure

```
ohio-mutual-hackathon/
├── openclaw.json              # Full 7-agent config
├── setup.sh                   # One-touch VPS provisioning
├── workspaces/
│   ├── router/
│   │   ├── AGENTS.md          # Router state machine logic, spawn patterns
│   │   ├── SOUL.md            # Professional orchestrator personality
│   │   └── TOOLS.md           # Tool notes (not policy)
│   ├── front-desk/
│   │   ├── AGENTS.md          # Intake checklist, categorization rules
│   │   └── SOUL.md
│   ├── claims-officer/
│   │   ├── AGENTS.md          # Coverage verification rules, policy lookup protocol
│   │   └── SOUL.md
│   ├── assessor/
│   │   ├── AGENTS.md          # Damage estimation methodology, total loss thresholds
│   │   └── SOUL.md
│   ├── fraud-analyst/
│   │   ├── AGENTS.md          # Fraud patterns, risk scoring rubric
│   │   └── SOUL.md
│   ├── senior-reviewer/
│   │   ├── AGENTS.md          # Decision criteria, escalation triggers
│   │   └── SOUL.md
│   └── finance/
│       ├── AGENTS.md          # Payment calc rules, deductible application
│       └── SOUL.md
├── shared/
│   ├── schemas/
│   │   └── claim.schema.json
│   ├── state/
│   │   └── claims/            # Runtime claim files (gitignored in production)
│   ├── policies/              # Mock policy database (JSON)
│   ├── uploads/               # Photo attachments per claim
│   └── test-claims/           # Pre-built test scenarios
├── scripts/
│   ├── submit-claim.sh        # Trigger test claim via CLI
│   ├── check-status.sh        # Print claim JSON formatted
│   └── run-demo.sh            # Full scripted demo flow
└── docs/
    └── ARCHITECTURE.md        # This diagram + decisions
```

### Structure Rationale

- **workspaces/:** Each agent's workspace directory with AGENTS.md as the primary configuration surface. AGENTS.md is injected into every session, making it the operating manual for that agent.
- **shared/:** The only cross-agent shared surface. All agents access this via absolute paths. No agent-to-agent API calls — file system is the integration layer.
- **scripts/:** Demo support. `run-demo.sh` submits a test claim and tails the claim file to show processing in real time.

---

## Architectural Patterns

### Pattern 1: Router as State Machine Owner

**What:** The router agent holds all orchestration logic in its AGENTS.md. It owns the claim lifecycle transitions. Pipeline agents are stateless workers that transform the claim file.

**When to use:** Always. This is the correct pattern for OpenClaw sequential pipelines.

**Trade-offs:** Router becomes a single point of knowledge. But AGENTS.md is easy to update day-of if the secret addition changes routing logic. This is exactly the flexibility needed.

**Example (router AGENTS.md excerpt):**

```markdown
## Pipeline Orchestration

When I receive a new claim, I:
1. Generate claim ID (CLM-YYYY-NNNNN format)
2. Write initial JSON to shared/state/claims/<CLM-ID>.json
3. Spawn front-desk agent with absolute path to claim file
4. Wait for announce. If SUCCESS: proceed to stage 2. If ERROR: retry once.
   If ESCALATE: notify human, stop.
5. [Continue for each stage...]

## Stage Decision Logic

After fraud-analyst:
- risk_score < 0.3: proceed to senior-reviewer normally
- risk_score 0.3-0.7: flag in task to senior-reviewer, they decide
- risk_score > 0.7: ESCALATE immediately, do not proceed to senior-reviewer
```

### Pattern 2: Claim File as Integration Contract

**What:** The claim JSON is the API between agents. Each agent reads the full claim, adds its section, and announces completion. The schema is immutable during a single claim's lifecycle.

**When to use:** Whenever you need agents to share context without direct communication.

**Trade-offs:** Requires discipline in schema design. Schema must be defined before Day 1 build starts. Changes to schema during the hackathon require updating all agent AGENTS.md files.

**Example:** assessor reads `pipeline.front_desk.category` to know if it's a collision vs comprehensive claim (different assessment methodology). This avoids the router having to re-explain context in every spawn task.

### Pattern 3: AGENTS.md as Business Logic Container

**What:** All business rules, regulatory requirements, fraud patterns, and decision thresholds live in each agent's AGENTS.md — not in code. Agents reason from these instructions rather than executing hardcoded logic.

**When to use:** This is OpenClaw's design. Use it everywhere. It satisfies the hackathon constraint: "Plan for human reasoning: your thinking should not be hardcoded."

**Trade-offs:** Agents may reason slightly differently each run (LLM non-determinism). Mitigated by structured JSON output format in AGENTS.md instructions.

**Flexibility advantage:** When the secret addition arrives, update the relevant AGENTS.md file. No code changes. This is the correct hackathon adaptability strategy.

---

## Anti-Patterns

### Anti-Pattern 1: Parallel Pipeline Stages

**What people do:** Spawn all 6 agents simultaneously for performance.

**Why it's wrong:** Coverage verification must complete before damage assessment (need to know deductible/limit). Fraud analysis requires damage estimate to flag inflated claims. Sequential dependency is real insurance business logic, not premature optimization.

**Do this instead:** Sequential spawning. The router waits for each stage to announce before spawning the next.

### Anti-Pattern 2: Agent-to-Agent Direct Messaging

**What people do:** Have fraud-analyst send a message directly to senior-reviewer.

**Why it's wrong:** OpenClaw's `agentToAgent` is disabled by default (`tools.agentToAgent.enabled: false`). More importantly, it breaks the audit trail — messages between agents are not in the claim file. The router loses visibility.

**Do this instead:** All inter-agent communication flows through the shared claim file + announce → router → next spawn. The router is always the mediator.

### Anti-Pattern 3: Hardcoded Decision Logic in Tools

**What people do:** Write a Python script that makes coverage decisions and call it from exec.

**Why it's wrong:** Violates the "human reasoning" constraint from the challenge. Judges will ask "why did you hardcode this?" and there is no good answer. Also breaks the flexibility requirement — script needs code change when secret addition arrives.

**Do this instead:** Decision logic lives in AGENTS.md as natural language instructions. The LLM reasons from principles. Update AGENTS.md on the day to incorporate secret addition.

### Anti-Pattern 4: maxSpawnDepth: 2 Without Need

**What people do:** Enable nested sub-agents "just in case."

**Why it's wrong:** Adds complexity (orchestrator sub-agents get extra session tools, depth-2 workers have different tool policies). Not needed for this pipeline.

**Do this instead:** Keep `maxSpawnDepth: 1` (default). The router at depth-0 spawns depth-1 pipeline agents. No nesting required.

---

## Build Order (3 Team Members, Parallelization)

```
HOUR 0.5-1: ALL TOGETHER — Architecture lock-in
  - Define final claim.schema.json (everyone must agree before splitting)
  - Define shared/ directory structure
  - Write openclaw.json skeleton with all 7 agents registered

HOURS 1-3: PARALLEL SPLIT

  Member A: Router + Infrastructure
    - Router AGENTS.md (state machine, spawn patterns, error handling)
    - setup.sh (VPS deploy script, directory creation)
    - submit-claim.sh (test script)
    - shared/test-claims/*.json (test scenarios)

  Member B: Front Desk + Claims Officer
    - front-desk AGENTS.md + SOUL.md (FNOL intake, categorization)
    - claims-officer AGENTS.md + SOUL.md (coverage rules, policy lookup)
    - shared/policies/*.json (mock policy database)

  Member C: Assessor + Fraud Analyst
    - assessor AGENTS.md + SOUL.md (damage estimation methodology)
    - fraud-analyst AGENTS.md + SOUL.md (fraud patterns, risk scoring)
    - shared/uploads/ structure + sample photos

INTEGRATION CHECK AT HOUR 3:
  - Test: submit-claim.sh → front-desk → claims-officer → stop
  - Verify claim JSON writes correctly
  - Fix any path/schema issues before proceeding

HOURS 3-5: SECOND PARALLEL SPLIT

  Member A: Senior Reviewer + Finance
    - senior-reviewer AGENTS.md + SOUL.md
    - finance AGENTS.md + SOUL.md
    - run-demo.sh

  Member B + C: Integration + End-to-End Testing
    - Full pipeline happy path test
    - Fraud flag escalation test
    - No-coverage rejection test
    - Edge case: total loss claim

INTEGRATION CHECK AT HOUR 5:
  - Full pipeline happy path working
  - Audit log populated correctly
  - All 6 stages complete

HOURS 5-7: Secret Addition + Polish
  - Incorporate secret addition into relevant AGENTS.md files
  - Edge case testing
  - Error handling validation

HOURS 7-8.5: Demo Prep
  - run-demo.sh polished
  - Presentation slides
  - Q&A prep
```

**Parallelization principle:** Member A focuses on infrastructure and orchestration; Members B and C focus on domain-specific agent logic. They can work independently because the claim schema is agreed upfront — each agent's AGENTS.md just references the same field names.

---

## OpenClaw-Specific Implementation Details

### Required openclaw.json Sections

```json5
{
  agents: {
    defaults: {
      model: { primary: "anthropic/claude-opus-4-6" },
      subagents: {
        maxSpawnDepth: 1,
        maxConcurrent: 6,
        maxChildrenPerAgent: 6,
        archiveAfterMinutes: 120
      }
    },
    list: [
      { id: "router", default: true, name: "Claims Router", workspace: "./workspaces/router" },
      {
        id: "front-desk", name: "Front Desk",
        workspace: "./workspaces/front-desk",
        tools: { allow: ["read", "write"], deny: ["exec", "browser", "gateway", "cron"] }
      },
      {
        id: "claims-officer", name: "Claims Officer",
        workspace: "./workspaces/claims-officer",
        tools: { allow: ["read", "write"], deny: ["exec", "browser", "gateway", "cron"] }
      },
      {
        id: "assessor", name: "Assessor",
        workspace: "./workspaces/assessor",
        tools: { allow: ["read", "write"], deny: ["exec", "browser", "gateway", "cron"] }
      },
      {
        id: "fraud-analyst", name: "Fraud Analyst",
        workspace: "./workspaces/fraud-analyst",
        tools: { allow: ["read", "write"], deny: ["exec", "browser", "gateway", "cron"] }
      },
      {
        id: "senior-reviewer", name: "Senior Reviewer",
        workspace: "./workspaces/senior-reviewer",
        tools: { allow: ["read", "write", "message"], deny: ["exec", "browser", "gateway", "cron"] }
      },
      {
        id: "finance", name: "Finance",
        workspace: "./workspaces/finance",
        tools: { allow: ["read", "write", "exec"], deny: ["browser", "gateway", "cron"] }
      }
    ]
  },
  tools: {
    agentToAgent: { enabled: false }  // No direct agent-to-agent messaging
  }
}
```

### Sub-Agent Session Key Pattern

Each pipeline stage creates a session:
`agent:<agentId>:subagent:<uuid>`

Example: `agent:front-desk:subagent:a1b2c3d4`

The router can use `sessions_history(sessionKey)` to read the full transcript of any completed sub-agent run for detailed debugging.

### Announce Message Structure

Sub-agents announce back to the router with this normalized template:
```
Status: success | error | timeout | unknown
Result: [summary of what was done]
Notes: [any errors or important context]
[stats: runtime Ns, tokens X/Y/Z, sessionKey, transcript path]
```

The router's AGENTS.md should parse the `Status:` line to determine next action.

### AGENTS.md Injection Scope

Sub-agents get ONLY `AGENTS.md` and `TOOLS.md` injected (NOT `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, or `BOOTSTRAP.md`). This means:

- `AGENTS.md` must contain ALL operating instructions for the sub-agent
- `SOUL.md` personality is NOT active during sub-agent runs
- This is fine for pipeline agents — they need instructions, not personality

**Practical implication:** Don't put critical operating instructions in SOUL.md for pipeline agents. Put everything in AGENTS.md.

---

## Scalability Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1-5 concurrent claims (hackathon) | JSON files, sequential spawning per claim, no changes needed |
| 10-50 concurrent claims | JSON files still fine; consider file locking with atomic writes (write-then-rename); maxConcurrent bump |
| 100+ concurrent claims | Move to SQLite or Postgres for claim state; add a proper queue; multiple gateway instances |

**Hackathon scale note:** The demo will process 1-3 claims during the presentation. The architecture is correct, not just fast enough. Focus Q&A on design rationale, not performance benchmarks.

---

## Sources

- `reference/openclaw-docs/tools/subagents.md` — sessions_spawn, announce protocol, depth levels, tool policy (HIGH confidence — official docs)
- `reference/openclaw-docs/concepts/multi-agent.md` — agent isolation, bindings, agentId, agentDir, workspace (HIGH confidence — official docs)
- `reference/openclaw-docs/tools/multi-agent-sandbox-tools.md` — per-agent tool allow/deny, tool groups, precedence (HIGH confidence — official docs)
- `reference/openclaw-docs/concepts/agent-workspace.md` — workspace layout, AGENTS.md injection, what bootstrap files are loaded (HIGH confidence — official docs)
- `reference/openclaw-docs/concepts/agent.md` — sub-agent context injection: only AGENTS.md + TOOLS.md (HIGH confidence — official docs)
- `reference/openclaw-docs/concepts/memory.md` — memory system, sqlite-vec, memory tools (HIGH confidence — official docs)
- `reference/openclaw-docs/concepts/architecture.md` — gateway architecture, WebSocket protocol, session flow (HIGH confidence — official docs)
- `reference/hackathon-challenge.md` — challenge requirements (authoritative)
- `reference/PROJECT_BRIEF.md` — project scope and constraints (authoritative)

---

*Architecture research for: Multi-agent auto insurance claims processing (OpenClaw hackathon)*
*Researched: 2026-02-17*
