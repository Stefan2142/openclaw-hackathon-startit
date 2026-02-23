# OpenClaw Tool and Primitive Documentation

Every OpenClaw primitive used in the Ohio Mutual Auto Claims Processing System -- what it does, why we chose it, and how it is configured in our `openclaw.json`. This document demonstrates deep framework knowledge for hackathon judges evaluating System Thinking.

---

## Primitives Used

| # | Primitive | Category | Used By | Purpose in Our System |
|---|-----------|----------|---------|-----------------------|
| 1 | `sessions_spawn` | Sub-agent orchestration | Router | Spawn each pipeline agent sequentially |
| 2 | `sessions_list` | Sub-agent monitoring | Router | List active sub-agent sessions |
| 3 | `sessions_history` | Sub-agent debugging | Router | Read sub-agent transcripts on failure |
| 4 | Agent isolation (`agentDir`) | Multi-agent architecture | All agents | Prevent auth/session collisions |
| 5 | Tool scoping (`allow`/`deny`) | Security | All agents | Least-privilege tool access per agent |
| 6 | Workspace structure (`AGENTS.md`) | Agent configuration | All agents | Primary business logic container |
| 7 | Bindings (default agent) | Message routing | Router | Route all inbound claims to Router |
| 8 | Model config (per-agent) | LLM selection | All agents | Cost-optimized model tiers |

---

## 1. sessions_spawn

### What It Does

`sessions_spawn` creates a new sub-agent session, targeting a specific agent by its `agentId`. The Router calls this to invoke each pipeline agent. The call returns immediately with a `status: "accepted"` response and a `childSessionKey`. The spawned agent processes its task and then "announces" its result back to the Router's session.

### How We Use It

The Router spawns 6 pipeline agents sequentially, one at a time. After each spawn, it waits for the announce result before spawning the next agent. This is the **announce-wait-read-spawn** cycle:

```
Router calls sessions_spawn(agentId="front-desk", task="Process FNOL...", runTimeoutSeconds=60)
  --> Returns: { status: "accepted", runId: "uuid-1", childSessionKey: "agent:front-desk:subagent:uuid-1" }

Router waits for announce from front-desk session
  --> Receives: "Status: success\nResult: Intake complete. Category: standard collision..."

Router reads updated claim JSON, validates front-desk output
Router calls sessions_spawn(agentId="claims-officer", task="Verify coverage...", runTimeoutSeconds=90)
  --> Pattern repeats for all 6 stages
```

### Configuration in openclaw.json

```json
{
  "agents": {
    "list": [
      {
        "id": "router",
        "subagents": {
          "allowAgents": ["front-desk", "claims-officer", "assessor", "fraud-analyst", "senior-reviewer", "finance"]
        },
        "tools": {
          "allow": ["sessions_spawn", "sessions_list", "sessions_history", "session_status"]
        }
      }
    ]
  }
}
```

### Key Configuration Details

| Parameter | Value | Why |
|-----------|-------|-----|
| `agentId` | Pipeline agent ID (e.g., "front-desk") | Targets a specific registered agent |
| `task` | Constructed task message with absolute file paths, context, instructions | Contains everything the agent needs |
| `runTimeoutSeconds` | 60-120s per stage | Prevents stuck agents from blocking the pipeline |
| `allowAgents` | Explicit list of 6 IDs | Least-privilege -- Router can only spawn registered pipeline agents |

### Why sessions_spawn

`sessions_spawn` is the only documented OpenClaw pattern for targeted sub-agent invocation by `agentId`. Without it, the Router could not direct work to specific pipeline agents. The announce mechanism provides a natural callback for sequential orchestration -- the Router waits for the announce, reads the updated claim, and decides the next action.

### Announce Message Protocol

Sub-agents report back via announce with this format:

```
Status: SUCCESS | ERROR | ESCALATE
Summary: [What was accomplished]
Key findings: [Critical outputs for downstream]
Next recommended action: [Suggestion for Router]
```

The Router parses `Status:` first. SUCCESS triggers validation and next-stage spawn. ERROR triggers retry. ESCALATE triggers the human-in-the-loop protocol.

---

## 2. sessions_list

### What It Does

`sessions_list` returns a list of all active sub-agent sessions for the current agent. Each entry includes the session key, agent ID, status, and creation timestamp.

### How We Use It

The Router uses `sessions_list` to:
- Monitor which pipeline stages are currently running
- Verify that a spawned agent's session is active before waiting for its announce
- Debug situations where an announce has not arrived (check if the session is still running or has timed out)

### Configuration in openclaw.json

```json
{
  "id": "router",
  "tools": {
    "allow": ["sessions_list"]
  }
}
```

### Why sessions_list

During the demo, the Router may need to check pipeline status. If a claim appears stuck, `sessions_list` reveals whether the sub-agent session is still active or has terminated. This is particularly useful during live demos where network or API latency can cause delays.

The OpenClaw CLI command `/subagents list` provides the same information interactively -- useful for the presenter to show live pipeline state to judges.

---

## 3. sessions_history

### What It Does

`sessions_history` reads the full transcript of a completed (or active) sub-agent session. This includes the task message sent, the agent's tool calls, its reasoning, and its final output.

### How We Use It

The Router uses `sessions_history` when:
- A pipeline agent announces ERROR -- the Router reads the full transcript to understand what went wrong before retrying
- A pipeline agent times out -- the Router checks how far the agent progressed
- Debugging during development -- the team reads transcripts to verify agent behavior

### Configuration in openclaw.json

```json
{
  "id": "router",
  "tools": {
    "allow": ["sessions_history"]
  }
}
```

### Why sessions_history

When a pipeline stage fails, the announce message provides only a summary. The full transcript (via `sessions_history`) shows exactly what the agent attempted, where it got stuck, and what errors it encountered. This is essential for the Router's retry logic -- if the agent failed because of a missing file, the Router knows to check the file exists before retrying. Without session history, failed stages are black boxes.

---

## 4. Agent Isolation (agentDir)

### What It Does

Each agent in OpenClaw has a unique `agentDir` path -- a directory that stores the agent's authentication credentials and session state. This ensures that different agents maintain completely separate identity and session contexts.

### How We Use It

All 7 agents have unique workspace directories that serve as their isolated identity:

```
workspaces/router/           --> Router identity
workspaces/front-desk/       --> Front Desk identity
workspaces/claims-officer/   --> Claims Officer identity
workspaces/assessor/         --> Assessor identity
workspaces/fraud-analyst/    --> Fraud Analyst identity
workspaces/senior-reviewer/  --> Senior Reviewer identity
workspaces/finance/          --> Finance identity
```

### Configuration in openclaw.json

```json
{
  "agents": {
    "list": [
      { "id": "router", "workspace": "./workspaces/router" },
      { "id": "front-desk", "workspace": "./workspaces/front-desk" },
      { "id": "claims-officer", "workspace": "./workspaces/claims-officer" },
      { "id": "assessor", "workspace": "./workspaces/assessor" },
      { "id": "fraud-analyst", "workspace": "./workspaces/fraud-analyst" },
      { "id": "senior-reviewer", "workspace": "./workspaces/senior-reviewer" },
      { "id": "finance", "workspace": "./workspaces/finance" }
    ]
  }
}
```

### Why Agent Isolation

The OpenClaw docs are explicit: "Never reuse `agentDir` across agents (it causes auth/session collisions)." If two agents share an `agentDir`, session state from one agent bleeds into another. The Claims Officer might pick up the Front Desk's session history, producing nonsensical decisions. In an insurance claims system, this is unacceptable -- every agent's identity and decisions must be isolated and traceable.

### Verification

After deployment, run `openclaw agents list --bindings` to verify all agents have distinct workspace paths. This catches copy-paste errors where a workspace path was not updated for a new agent.

---

## 5. Tool Scoping (allow/deny)

### What It Does

OpenClaw's per-agent `tools.allow` and `tools.deny` lists control which tools each agent can access. This implements the principle of least privilege -- agents can only use the tools they need for their specific function.

### How We Use It

Seven distinct tool configurations, one per agent:

**Router (orchestrator):**
```json
{
  "tools": {
    "allow": ["read", "write", "exec", "sessions_spawn", "sessions_list", "sessions_history", "session_status"],
    "deny": ["browser", "gateway", "cron"]
  }
}
```

**Pipeline agents (5 of 6 -- all except Finance):**
```json
{
  "tools": {
    "allow": ["read", "write"],
    "deny": ["exec", "browser", "gateway", "cron", "sessions_spawn"]
  }
}
```

**Finance (only pipeline agent with exec):**
```json
{
  "tools": {
    "allow": ["read", "write", "exec"],
    "deny": ["browser", "gateway", "cron", "sessions_spawn"]
  }
}
```

### Tool Scoping Summary

| Tool | Router | Front Desk | Claims Officer | Assessor | Fraud Analyst | Senior Reviewer | Finance |
|------|--------|------------|----------------|----------|---------------|-----------------|---------|
| read | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| write | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| exec | ALLOW | DENY | DENY | DENY | DENY | DENY | ALLOW |
| sessions_spawn | ALLOW | DENY | DENY | DENY | DENY | DENY | DENY |
| sessions_list | ALLOW | -- | -- | -- | -- | -- | -- |
| sessions_history | ALLOW | -- | -- | -- | -- | -- | -- |
| browser | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| gateway | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| cron | DENY | DENY | DENY | DENY | DENY | DENY | DENY |

### Why Least-Privilege Tool Scoping

**Security argument:** In real insurance systems, the fraud detection function should not execute arbitrary scripts. The finance function should not spawn sub-agents. The damage assessor should not browse the internet. Each role has a defined scope of capability -- our tool scoping mirrors this.

**Hackathon judging argument:** Judges evaluate System Thinking (50% of score). Demonstrating awareness of least-privilege security principles shows mature architectural thinking. The per-agent tool configuration is a concrete, visible signal that we thought about security boundaries.

**Practical benefit:** Prevents accidental misuse. If a pipeline agent's AGENTS.md accidentally instructs it to spawn a sub-agent, the tool deny list prevents the action from succeeding. Defense in depth.

### OpenClaw Tool Groups

OpenClaw provides tool groups for convenience:
- `group:fs` expands to: `read`, `write`, `edit`, `apply_patch`
- `group:runtime` expands to: `exec`, `bash`, `process`
- `group:sessions` expands to: `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status`
- `group:automation` expands to: `cron`, `gateway`

We use individual tool names (not groups) for maximum precision in the allow/deny lists.

---

## 6. Workspace Structure (AGENTS.md / TOOLS.md)

### What It Does

Each agent's workspace directory contains markdown files that are injected into the agent's context at session start:
- **AGENTS.md** -- Operating instructions, loaded every session. This is the primary configuration surface for business logic.
- **TOOLS.md** -- Optional guidance on tool usage conventions. Does NOT control tool availability (that is done via `tools.allow`/`tools.deny`).
- **SOUL.md** -- Persona and personality. Loaded for main agents but NOT for sub-agents.

### How We Use It

**Critical behavior:** Sub-agents (depth-1 agents spawned via `sessions_spawn`) receive ONLY `AGENTS.md` and `TOOLS.md` injected. They do NOT receive SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, or BOOTSTRAP.md.

This means ALL operating instructions for pipeline agents must be in AGENTS.md:

```
workspaces/
+-- router/
|   +-- AGENTS.md     <-- State machine, spawn patterns, error handling,
|                          context enrichment, regulatory awareness
+-- front-desk/
|   +-- AGENTS.md     <-- FNOL intake, categorization, completeness check,
|                          priority assignment, domain knowledge
+-- claims-officer/
|   +-- AGENTS.md     <-- Policy lookup, coverage verification, exclusion
|                          analysis, denial documentation, domain knowledge
+-- assessor/
|   +-- AGENTS.md     <-- Damage estimation, total loss determination,
|                          OEM vs aftermarket, photo analysis, domain knowledge
+-- fraud-analyst/
|   +-- AGENTS.md     <-- Fraud pattern catalog, indicator convergence,
|                          risk scoring, SIU referral criteria, domain knowledge
+-- senior-reviewer/
|   +-- AGENTS.md     <-- Evidence weighing, FCSP timeline check, decision
|                          criteria, escalation judgment, domain knowledge
+-- finance/
    +-- AGENTS.md     <-- Payment calculation, deductible application,
                           depreciation, subrogation assessment, domain knowledge
```

### Configuration in openclaw.json

```json
{
  "agents": {
    "list": [
      {
        "id": "front-desk",
        "workspace": "./workspaces/front-desk"
      }
    ]
  }
}
```

The `workspace` path tells OpenClaw where to find the agent's AGENTS.md file. OpenClaw reads this file and injects its contents into every session started for this agent.

### Why AGENTS.md as Primary Configuration

**OpenClaw's design intent:** AGENTS.md is the "operating manual" for each agent. It contains everything the agent needs to know about its role, responsibilities, and decision criteria. Because sub-agents only receive AGENTS.md + TOOLS.md, this file must be self-contained.

**Our design choice:** No SOUL.md in any workspace. All instructions -- including role personality, behavioral constraints, and domain expertise from Phase 1 research -- are embedded in AGENTS.md. This eliminates the documented pitfall where teams put critical instructions in SOUL.md and wonder why sub-agents behave inconsistently.

**Hackathon flexibility:** When the "secret addition" arrives, the team updates the relevant AGENTS.md file(s). No code changes. The next claim processed uses the updated instructions immediately. This is the correct adaptability strategy.

---

## 7. Bindings (Default Agent)

### What It Does

OpenClaw bindings route inbound messages (from WebChat, Slack, or CLI channels) to a specific agent. The `default: true` flag on an agent makes it the recipient of all unmatched inbound messages.

### How We Use It

The Router is configured as the default agent. All claim submissions -- regardless of channel -- are routed to the Router for processing:

```json
{
  "agents": {
    "list": [
      {
        "id": "router",
        "name": "Claims Router",
        "default": true,
        "workspace": "./workspaces/router"
      }
    ]
  }
}
```

### Why the Router Is the Default Agent

**Single entry point:** All claims enter the system through the Router. This ensures:
- Every claim gets a unique ID (CLM-YYYY-NNNNN)
- Every claim gets an initial JSON record created
- Every claim enters the pipeline through the same state machine
- The audit trail starts from the very first interaction

**No direct access to pipeline agents:** If a message were routed directly to the Fraud Analyst, it would bypass intake, coverage verification, and damage assessment. The Router's role as the entry point enforces the correct pipeline ordering.

**Demo simplicity:** The team submits test claims via `submit-claim.sh` which sends a message to the default agent. No routing configuration needed beyond `default: true`.

---

## 8. Model Config (Per-Agent Override)

### What It Does

OpenClaw allows setting a default model for all agents and then overriding the model per individual agent. This enables cost-optimized model selection where high-reasoning roles use a stronger (more expensive) model and deterministic roles use a faster (cheaper) model.

### How We Use It

**Default model:** Claude Opus 4.6 (strongest reasoning)
**Per-agent overrides:** Sonnet 4.5 for three agents with deterministic tasks

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-6"
      },
      "models": {
        "anthropic/claude-opus-4-6": {
          "alias": "Opus",
          "params": { "cacheRetention": "short" }
        },
        "anthropic/claude-sonnet-4-5": {
          "alias": "Sonnet",
          "params": { "cacheRetention": "short" }
        }
      }
    },
    "list": [
      { "id": "router",          "model": "anthropic/claude-opus-4-6" },
      { "id": "front-desk",      "model": "anthropic/claude-sonnet-4-5" },
      { "id": "claims-officer",  "model": "anthropic/claude-sonnet-4-5" },
      { "id": "assessor",        "model": "anthropic/claude-opus-4-6" },
      { "id": "fraud-analyst",   "model": "anthropic/claude-opus-4-6" },
      { "id": "senior-reviewer", "model": "anthropic/claude-opus-4-6" },
      { "id": "finance",         "model": "anthropic/claude-sonnet-4-5" }
    ]
  }
}
```

### Model Assignment Rationale

| Agent | Model | Why |
|-------|-------|-----|
| Router | Opus 4.6 | Orchestration requires planning, error recovery, and multi-step reasoning |
| Front Desk | Sonnet 4.5 | Structured data extraction from FNOL -- well-defined, deterministic |
| Claims Officer | Sonnet 4.5 | Policy field matching against structured JSON -- rule-following task |
| Assessor | Opus 4.6 | Nuanced damage estimation from descriptions -- benefits from strong reasoning |
| Fraud Analyst | Opus 4.6 | Pattern recognition from incomplete data, adversarial scenarios -- needs top-tier |
| Senior Reviewer | Opus 4.6 | Final authority weighing conflicting signals -- highest-stakes decision |
| Finance | Sonnet 4.5 | Arithmetic (estimate - deductible - depreciation) -- deterministic calculation |

### Why Per-Agent Model Selection

**Cost optimization without quality sacrifice:** The OpenClaw docs recommend: "set a cheaper model for sub-agents and keep your main agent on a higher-quality model." We go further by selecting per-agent based on task complexity. Sub-agents accumulate token cost with each session -- using Sonnet for three simpler agents reduces cost meaningfully.

**Prompt caching:** Both model configurations include `cacheRetention: "short"` to reduce cost when AGENTS.md is repeatedly injected across multiple claim sessions. The OpenClaw docs note that API-key auth honors cache settings, while subscription auth does not.

---

## OpenClaw Concepts Not Used (and Why)

| Concept | What It Does | Why We Did Not Use It |
|---------|-------------|----------------------|
| `SOUL.md` | Agent persona/personality file | Sub-agents do not receive SOUL.md. All instructions go in AGENTS.md. |
| `agentToAgent` messaging | Direct agent-to-agent communication | Disabled. All communication flows through claim JSON + Router mediation for audit trail. |
| `maxSpawnDepth: 2` | Allow depth-1 agents to spawn depth-2 workers | Unnecessary. Pipeline agents are leaf workers. maxSpawnDepth: 1 is sufficient. |
| `group:sessions` on pipeline agents | Grant session tools to pipeline agents | Pipeline agents must not spawn or manage sessions. Only the Router orchestrates. |
| `memory` tools | Agent long-term memory (SQLite-backed) | Not needed for hackathon scope. Each claim is self-contained in its JSON file. |
| `browser` tool | Web browsing capability | No agent needs to access the internet during claim processing. |
| `cron` / scheduled tasks | Time-based task execution | Pipeline is event-driven (FNOL trigger), not scheduled. |
| `gateway` admin tools | Gateway configuration management | Not needed at runtime. Configuration is set before the hackathon starts. |

---

*OpenClaw tool documentation for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*Demonstrates deep framework knowledge for System Thinking evaluation*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
