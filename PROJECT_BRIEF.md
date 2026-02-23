# Ohio Mutual Auto — OpenClaw Hackathon Project

## Event Details
- **What:** OpenClaw Business Engineering Hackathon
- **When:** Saturday, February 21st, 2026, 10 hours (10:00-20:00)
- **Where:** Insightful Offices, Knez Mihailova, Belgrade
- **Prize:** $2,800 total ($1,600 / $800 / $400)
- **Judging:** 50% Business Thinking + 50% System Thinking (5-min presentation + 5-min Q&A)

## The Challenge
Build a multi-agent claims processing system for **Ohio Mutual Auto**, a fictional mid-size car insurance company. Each role in the pipeline = an OpenClaw agent, appropriately scoped.

### Pipeline (6 agents)
1. **Router** — Orchestrates the pipeline, handles user communication, performs FNOL intake (absorbed Front Desk role)
2. **Claims Officer** — Checks whether coverage applies
3. **Assessor** — Estimates the actual damage
4. **Fraud Analyst** — Looks for suspicious patterns
5. **Senior Reviewer** — Makes the final decision (approve/deny/escalate)
6. **Finance** — Executes payment

### Key Rules
- Regulations exist and must be respected (FCSP Act timelines)
- Business priorities exist and must be respected
- Secret addition on the day adds business context that complicates design
- "Plan for human reasoning: your thinking should not be hardcoded"
- You may bring knowledge but NOT work product (no code, no text)

## What We Built

### Architecture Decisions
1. **`sessions_send` (synchronous RPC)** — Router calls each agent in sequence, blocks until response. No sub-agents, no spawning. Each agent is a full peer.
2. **PostgreSQL via `db.sh`** — Single `claim_data` JSONB column stores the full claim document. Agents read/write via bash wrapper script. No file-based state.
3. **6 agents, not 7** — Router absorbs Front Desk intake. Fewer moving parts, same coverage.
4. **Per-agent model selection** — Opus 4.6 for complex reasoning (Router, Fraud Analyst, Senior Reviewer). Sonnet 4.5 for structured work (Claims Officer, Assessor, Finance).
5. **Per-agent tool permissions** — Only Router has `sessions_send`. Pipeline agents have `read`, `write`, `exec` only. No agent can spawn sub-agents.
6. **Human-in-the-loop escalation** — 7 escalation triggers as reasoning principles (not hardcoded thresholds). Pipeline pauses, claim goes to ESCALATED status.
7. **Principle-based reasoning** — Agents reason from domain knowledge, not if/then rules. Adapts to the secret addition without code changes.

### Claim Lifecycle
```
FNOL_RECEIVED → COVERAGE_CHECKED → ASSESSED → FRAUD_ANALYZED → REVIEWED → PAYMENT_ISSUED
                                                                    ↓
                                              DENIED / ESCALATED / ERROR (from any stage)
```

### Domain Knowledge Embedded in Agents
- **Claims Officer**: 8 exclusion categories, coverage type matching, grace period analysis, ambiguity doctrine
- **Assessor**: Labor/parts/paint estimation, Ohio 100% ACV total loss rule, OEM vs aftermarket, pre-existing damage detection
- **Fraud Analyst**: 7 named fraud patterns (staged accident, phantom passengers, paper accident, inflated repairs, prior damage/VIN switching, owner give-up, organized rings), scoring framework
- **Senior Reviewer**: FCSP timeline compliance (10-day ack, 40-day decision, 30-day payment), 7 escalation triggers, denial documentation requirements
- **Finance**: Payment calculation, deductible/depreciation application, subrogation identification, GAP insurance awareness

### Repo Structure
```
repo/
├── setup.sh                     # One-touch setup (Node.js, PostgreSQL, OpenClaw, config merge)
├── openclaw.json                # 6 agents, Telegram channel, agent-to-agent messaging
├── workspaces/                  # One folder per agent (AGENTS.md + TOOLS.md + IDENTITY.md + SOUL.md)
│   ├── router/                  # Opus 4.6 — orchestrator + intake
│   ├── claims-officer/          # Sonnet 4.5 — coverage validation
│   ├── assessor/                # Sonnet 4.5 — damage analysis
│   ├── fraud-analyst/           # Opus 4.6 — risk scoring
│   ├── senior-reviewer/         # Opus 4.6 — decision authority
│   └── finance/                 # Sonnet 4.5 — payments
├── shared/
│   ├── schemas/                 # claim.schema.json (full data contract)
│   ├── policies/                # 5 Ohio auto policies (POL-AUT-10001 through 10005)
│   ├── test-claims/             # 3 scenarios (happy path, denial, fraud)
│   └── scripts/                 # db.sh (PostgreSQL wrapper) + db-setup.sql
├── architecture/                # Design specs (router, handoff, escalation, shared state)
├── docs/                        # Presentation script, demo walkthroughs, Q&A defense
└── reference/                   # Domain knowledge docs, hackathon challenge, OpenClaw docs
```

### Test Scenarios
1. **Happy path collision** — Standard rear-end collision, covered, approved, paid
2. **Coverage denial** — Excluded driver, policy valid but driver not covered, denied
3. **Fraud rejection** — Multiple converging fraud indicators, escalated to SIU

### What Makes This Different
- Agents reason from principles, not rules — adapts to secret addition without changes
- Full audit trail with reasoning at every step — regulatory compliance built in
- Human-in-the-loop escalation shows the system knows its limits
- FCSP timeline tracking throughout the pipeline
- PostgreSQL gives queryable state vs flat files
