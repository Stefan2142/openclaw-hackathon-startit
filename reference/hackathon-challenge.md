# OpenClaw Hackathon — Step-by-Step Guide

## 🎯 What Is This Hackathon?

**Event:** OpenClaw Business Engineering Hackathon
**Date:** Saturday, February 21st, 2026, 9:00 AM – ~21:30
**Location:** Insightful Offices, Knez Mihailova, Belgrade
**Duration:** 10 hours of building (10:00–20:00)
**Prize:** $2,800 total ($1,600 / $800 / $400)
**Teams:** 10 teams max
**Format:** 5-min presentation + 5-min Q&A per team

---

## 🏗️ The Challenge

Build a **multi-agent claims processing system** for **Ohio Mutual Auto**, a fictional mid-size car insurance company.

Their current process is entirely manual — phone calls, paper forms, blurry photos. Each claim passes through **6 people** before resolution.

### The Pipeline (6 Roles → 6 OpenClaw Agents)

| # | Role | Responsibility |
|---|------|---------------|
| 1 | **Front Desk** | Registers and categorizes the claim |
| 2 | **Claims Officer** | Checks whether coverage applies |
| 3 | **Assessor** | Estimates the actual damage |
| 4 | **Fraud Analyst** | Looks for suspicious patterns |
| 5 | **Senior Reviewer** | Makes the final decision |
| 6 | **Finance** | Executes payment |

### Key Constraints
- Regulations exist — you MUST respect them
- Business priorities exist — you MUST respect them
- Disregard either → you're out of business (and not winning)
- **Secret addition on the day** — adds business context that complicates design decisions
- "Plan for human reasoning: your thinking should not be hardcoded"

---

## 📊 Judging Criteria (CRITICAL)

| Criteria | Weight | What They're Looking For |
|----------|--------|--------------------------|
| **Business Thinking** | **50%** | Can you defend decisions from a business perspective? |
| **System Thinking** | **50%** | Does it work end-to-end? Does the multi-agent design make sense? |

**This is NOT a pure coding hackathon.** Half the score is about understanding insurance business logic, regulations, and trade-offs. The other half is about a working, well-architected system.

---

## 🔧 Required Tooling

**OpenClaw is mandatory.** Each role in the pipeline = an OpenClaw agent, appropriately scoped.

You can use anything else in addition, but must demonstrate **meaningful use of OpenClaw**.

---

## 🧠 What We Need to Know Before Building

### Insurance Claims 101 (Research Before Feb 21)
> "Teams that research how claims work before the hackathon will have a real advantage"

Key things to research:
1. **Claims lifecycle** — How do real insurance claims flow from FNOL (First Notice of Loss) to payment?
2. **Coverage verification** — What determines if a claim is covered? (policy type, deductibles, exclusions)
3. **Damage assessment** — How do adjusters estimate repair costs?
4. **Fraud detection** — Common fraud patterns in auto insurance (staged accidents, inflated claims, prior damage)
5. **Regulatory requirements** — Claim acknowledgement timelines, fair claims practices, documentation retention
6. **Payment processing** — Subrogation, deductible application, depreciation vs replacement

### The "Secret Addition"
- Added on the day at 9:30 AM Q&A
- Adds business context that changes your design
- Could be: new regulation, surge in claims, new fraud pattern, merger, etc.
- Our architecture must be **flexible enough to adapt**

---

## 🏛️ Architecture: How to Build This with OpenClaw

### Core Concept: Each Role = An OpenClaw Agent

OpenClaw's multi-agent system lets you define isolated agents, each with:
- **Own workspace** (AGENTS.md, SOUL.md, files)
- **Own tools** (scoped permissions — e.g., Finance can pay, others can't)
- **Own sandbox** (isolation level)
- **Own model/thinking config**

### The Orchestrator Pattern

We need a **7th agent: the Router/Orchestrator** that:
1. Receives incoming claims
2. Spawns sub-agents for each pipeline stage
3. Tracks state transitions
4. Handles errors and escalations

This uses OpenClaw's `sessions_spawn` + `maxSpawnDepth: 2`:
```
Main Agent (Router)
  ├── spawns → Front Desk agent
  ├── spawns → Claims Officer agent
  ├── spawns → Assessor agent
  ├── spawns → Fraud Analyst agent
  ├── spawns → Senior Reviewer agent
  └── spawns → Finance agent
```

### Config Structure (`openclaw.json`)

```json5
{
  agents: {
    defaults: {
      model: { primary: "anthropic/claude-opus-4-6" },
      subagents: {
        maxSpawnDepth: 2,
        maxConcurrent: 8,
        maxChildrenPerAgent: 6
      }
    },
    list: [
      {
        id: "router",
        default: true,
        name: "Claims Router",
        workspace: "./workspaces/router"
      },
      {
        id: "front-desk",
        name: "Front Desk",
        workspace: "./workspaces/front-desk",
        tools: {
          allow: ["read", "write", "exec"],
          deny: ["gateway", "cron", "browser"]
        }
      },
      {
        id: "claims-officer",
        name: "Claims Officer",
        workspace: "./workspaces/claims-officer",
        tools: {
          allow: ["read", "write"],
          deny: ["gateway", "cron", "browser"]
        }
      },
      {
        id: "assessor",
        name: "Assessor",
        workspace: "./workspaces/assessor",
        tools: {
          allow: ["read", "write", "image"],
          deny: ["gateway", "cron", "browser"]
        }
      },
      {
        id: "fraud-analyst",
        name: "Fraud Analyst",
        workspace: "./workspaces/fraud-analyst",
        tools: {
          allow: ["read", "write"],
          deny: ["gateway", "cron", "browser"]
        }
      },
      {
        id: "senior-reviewer",
        name: "Senior Reviewer",
        workspace: "./workspaces/senior-reviewer",
        tools: {
          allow: ["read", "write", "message"],
          deny: ["gateway", "cron", "browser"]
        }
      },
      {
        id: "finance",
        name: "Finance",
        workspace: "./workspaces/finance",
        tools: {
          allow: ["read", "write", "exec"],
          deny: ["gateway", "cron", "browser"]
        }
      }
    ]
  }
}
```

### Each Agent's Workspace

```
workspaces/
├── router/
│   ├── AGENTS.md          # Router instructions: orchestrate pipeline
│   ├── SOUL.md            # Professional, systematic personality
│   └── shared/            # Shared claim state files
│       └── schemas/
│           └── claim.json # JSON schema for claim records
├── front-desk/
│   ├── AGENTS.md          # Intake instructions, categorization rules
│   ├── SOUL.md            # Friendly, thorough personality
│   └── shared/
├── claims-officer/
│   ├── AGENTS.md          # Coverage verification rules, policy lookup
│   ├── SOUL.md            # Precise, by-the-book personality  
│   └── shared/
├── assessor/
│   ├── AGENTS.md          # Damage estimation, photo analysis
│   ├── SOUL.md            # Detail-oriented, technical personality
│   └── shared/
├── fraud-analyst/
│   ├── AGENTS.md          # Fraud patterns, red flags, scoring
│   ├── SOUL.md            # Skeptical, analytical personality
│   └── shared/
├── senior-reviewer/
│   ├── AGENTS.md          # Final decision criteria, escalation rules
│   ├── SOUL.md            # Authoritative, fair personality
│   └── shared/
└── finance/
    ├── AGENTS.md          # Payment rules, deductible calc, disbursement
    ├── SOUL.md            # Precise, compliance-focused personality
    └── shared/
```

### How Agents Communicate: Shared State via Files

All agents read/write claim JSON files in a shared directory:

```json
{
  "claim_id": "CLM-2026-00001",
  "status": "ASSESSING",
  "pipeline": {
    "front_desk": { "completed_at": "...", "category": "collision" },
    "claims_officer": { "completed_at": "...", "covered": true, "deductible": 500 },
    "assessor": null,
    "fraud_analyst": null,
    "senior_reviewer": null,
    "finance": null
  },
  "audit_log": [
    { "timestamp": "...", "agent": "front-desk", "action": "categorized", "reasoning": "..." }
  ]
}
```

### How the Router Spawns Agents

```
# Router uses sessions_spawn to kick off each stage:
sessions_spawn(
  task="Process claim CLM-2026-00001. Read shared/state/claims/CLM-2026-00001.json. 
        Verify policy coverage. Update the claims_officer section and set status accordingly.",
  agentId="claims-officer",
  model="anthropic/claude-opus-4-6",
  label="claims-officer-CLM-2026-00001",
  runTimeoutSeconds=120,
  cleanup="keep"
)
```

---

## 📋 Step-by-Step Build Plan (10 Hours)

### Hour 0 (9:00-9:30) — Setup & Q&A
- [ ] Arrive, connect to WiFi
- [ ] Hear the **secret addition** at 9:30 Q&A
- [ ] Discuss as team: how does the secret change our approach?

### Hour 0.5-1 (9:30-10:00) — Architecture Planning
- [ ] Whiteboard the full pipeline
- [ ] Define claim state schema
- [ ] Decide what each agent can/can't do (tool scoping)
- [ ] Incorporate secret addition into design
- [ ] Assign: who builds which agents

### Hours 1-3 (10:00-13:00) — Phase 1: Core Pipeline
- [ ] Set up project repo with OpenClaw config
- [ ] Create all 7 agent workspaces (AGENTS.md + SOUL.md)
- [ ] Build Router agent (orchestrator)
- [ ] Build Front Desk agent (intake + categorization)
- [ ] Build Claims Officer agent (coverage check)
- [ ] Test: submit claim → Front Desk → Claims Officer flow

### Hours 3-5 (13:00-15:00) — Phase 2: Assessment & Fraud
- [ ] Build Assessor agent (damage estimation + photo analysis)
- [ ] Build Fraud Analyst agent (pattern detection + scoring)
- [ ] Create test claims with photos
- [ ] Test: claim flows through all 4 stages

### Hours 5-7 (15:00-17:00) — Phase 3: Decision & Payment
- [ ] Build Senior Reviewer agent (final decision logic)
- [ ] Build Finance agent (payment execution)
- [ ] End-to-end test: full pipeline happy path
- [ ] Test edge cases: rejection, fraud flag, no coverage

### Hours 7-8.5 (17:00-18:30) — Integration & Polish
- [ ] Full pipeline stress test (multiple claims)
- [ ] Handle the secret addition properly
- [ ] Error handling and edge cases
- [ ] Audit log completeness

### Hours 8.5-10 (18:30-20:00) — Demo Prep
- [ ] Prepare 5-min presentation
- [ ] Script the demo flow (which claim to show)
- [ ] Prepare business justification for every design decision
- [ ] Practice Q&A: "Why did you scope it this way?" "What regulation does this address?"

---

## 🎤 Presentation Strategy (5 min + 5 min Q&A)

### The 5-Minute Pitch
1. **Problem** (30s) — Ohio Mutual's manual process, why it's broken
2. **Architecture** (1 min) — 6 agents + router, how they communicate
3. **Business Logic** (1.5 min) — Regulations respected, fraud prevention, compliance
4. **Live Demo** (1.5 min) — Submit a claim, watch it flow through the pipeline
5. **Secret Addition** (30s) — How we adapted to the day-of challenge

### Anticipate Q&A Questions
- "Why 6 separate agents instead of one big one?" → Separation of concerns, least-privilege, auditability
- "What happens when the Fraud Analyst flags something?" → Escalation path, human-in-the-loop
- "How do you ensure compliance?" → Audit log, regulatory timelines, documentation
- "What if two claims come in at once?" → Concurrent processing, state isolation
- "How would this scale?" → Agent instances, shared state, queue management

---

## 🔑 Key Differentiators (What Wins)

1. **Business understanding > fancy code** — Know WHY each agent exists in real insurance
2. **Proper scoping** — Each agent has ONLY the tools it needs (least privilege)
3. **Audit trail** — Every decision logged with reasoning (regulatory requirement)
4. **Adaptability** — Architecture handles the secret addition gracefully
5. **Defend every decision** — "We chose X because in insurance, Y regulation requires Z"

---

## 📚 Pre-Hackathon Research TODO

- [ ] How FNOL (First Notice of Loss) works
- [ ] State insurance regulations (claim acknowledgement timelines)
- [ ] Common auto insurance fraud patterns
- [ ] How damage assessors estimate repairs (OEM vs aftermarket parts)
- [ ] Subrogation basics
- [ ] Fair Claims Settlement Practices
- [ ] Total loss thresholds
- [ ] Read OpenClaw docs: multi-agent routing, subagents, sessions_spawn, agent workspaces
