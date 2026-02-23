# Stack Research

**Domain:** Multi-agent auto insurance claims processing (OpenClaw + Claude)
**Researched:** 2026-02-17
**Confidence:** HIGH (OpenClaw primitives verified against local docs in reference/openclaw-docs/; Claude model IDs verified against official Anthropic provider docs fetched live)

---

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| OpenClaw Gateway | v2026.1.6+ | Multi-agent orchestration host | Only supported framework per hackathon rules; per-agent sandbox + tool restrictions available from v2026.1.6 per docs |
| Claude (Anthropic) | claude-opus-4-6 / claude-sonnet-4-5 | LLM powering all agents | Team already using Claude; docs confirm `anthropic/claude-opus-4-6` as primary and `anthropic/claude-sonnet-4-5` for cost reduction in OpenClaw config examples |
| Node.js | 20 LTS (bundled with OpenClaw Docker image) | OpenClaw runtime | OpenClaw gateway is Node.js; no choice here — runtime is embedded |

### OpenClaw Configuration Patterns (Verified against reference/openclaw-docs/)

#### Pattern 1: Orchestrator via `sessions_spawn` with `maxSpawnDepth: 2`

The Router agent (depth 0) spawns specialist agents (depth 1) using `sessions_spawn`. This is the only documented orchestrator pattern that allows sub-agents to be individually targetted by `agentId`.

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
    }
  }
}
```

**Why `maxSpawnDepth: 2`:** The Router needs to spawn specialist pipeline agents. Depth 1 sub-agents get `sessions_spawn`, `sessions_list`, `sessions_history` automatically when `maxSpawnDepth >= 2`. Depth 2 workers (if needed later for "secret addition" complexity) can never spawn further. The docs explicitly describe this as the "orchestrator pattern."

**Why `maxChildrenPerAgent: 6`:** One slot per pipeline agent (6 total). Default is 5, which is one short. Raising to 6 allows all pipeline stages to run concurrently for a single claim.

**Confidence:** HIGH — directly from `reference/openclaw-docs/tools/subagents.md`

#### Pattern 2: Per-Agent Tool Scoping (Least Privilege)

Each agent in `agents.list` gets only the tools it needs. Tool groups simplify policy:

```json5
{
  id: "finance",
  name: "Finance",
  workspace: "./workspaces/finance",
  tools: {
    allow: ["read", "write", "exec"],
    deny: ["gateway", "cron", "browser", "sessions_spawn"]
  }
}
```

**Tool groups available (from docs):**
- `group:fs` → `read`, `write`, `edit`, `apply_patch`
- `group:sessions` → `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status`
- `group:runtime` → `exec`, `bash`, `process`
- `group:automation` → `cron`, `gateway`

**Per-agent scoping rationale for insurance pipeline:**
- Front Desk: `read`, `write` (intake JSON, write claim record) — no exec
- Claims Officer: `read`, `write` (read policy data, update coverage status) — no exec
- Assessor: `read`, `write` (read photos, write damage estimate) — no exec
- Fraud Analyst: `read`, `write` (pattern matching on claim data) — no exec, explicitly deny `sessions_spawn`
- Senior Reviewer: `read`, `write`, `message` (can send escalation notifications) — no exec
- Finance: `read`, `write`, `exec` (execute payment scripts) — only agent with exec

**Why deny `sessions_spawn` on all pipeline agents:** Prevents unauthorized lateral movement. Only the Router orchestrator should spawn sub-agents. This is a security boundary matching the "least privilege" requirement the judges will evaluate.

**Confidence:** HIGH — directly from `reference/openclaw-docs/tools/multi-agent-sandbox-tools.md`

#### Pattern 3: AGENTS.md + SOUL.md Per-Agent Workspace

Each agent workspace requires:
- `AGENTS.md` — operating instructions, loaded every session. Contains role-specific claim processing rules, what data to read/write, decision criteria.
- `SOUL.md` — persona and tone. Different personalities reinforce role separation (skeptical for Fraud Analyst, precise for Finance, authoritative for Senior Reviewer).
- `TOOLS.md` — optional guidance on conventions (does NOT control tool availability).

**Important constraint from docs:** Sub-agents only get `AGENTS.md` + `TOOLS.md` injected — not `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, or `BOOTSTRAP.md`. This means `SOUL.md` personality is NOT active when agents run as sub-agents. Personality must be embedded in `AGENTS.md` for it to take effect in sub-agent runs.

**Action:** Embed role personality and constraints inside `AGENTS.md` for each specialist agent, not in `SOUL.md` alone.

**Confidence:** HIGH — from `reference/openclaw-docs/tools/subagents.md`, line: "Sub-agent context only injects `AGENTS.md` + `TOOLS.md` (no `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, or `BOOTSTRAP.md`)"

#### Pattern 4: Model Selection Per Agent Role

```json5
{
  agents: {
    defaults: {
      model: { primary: "anthropic/claude-opus-4-6" },
      subagents: {
        model: "anthropic/claude-sonnet-4-5"
      }
    }
  }
}
```

**Or per-agent override:**
```json5
{
  id: "fraud-analyst",
  model: "anthropic/claude-opus-4-6"  // override to Opus for fraud — nuanced reasoning
},
{
  id: "front-desk",
  model: "anthropic/claude-sonnet-4-5"  // Sonnet sufficient for structured intake
}
```

**Rationale by role:**

| Agent | Model | Reason |
|-------|-------|--------|
| Router/Orchestrator | claude-opus-4-6 | Orchestration logic requires planning, routing decisions, error handling — needs Opus reasoning |
| Front Desk | claude-sonnet-4-5 | Structured data intake, form parsing — Sonnet is sufficient and cheaper |
| Claims Officer | claude-sonnet-4-5 | Policy lookup against structured policy JSON — well-defined rules, Sonnet handles this |
| Assessor | claude-opus-4-6 | Photo/damage analysis, nuanced cost estimation — benefits from Opus multimodal and reasoning |
| Fraud Analyst | claude-opus-4-6 | Pattern recognition, inference from incomplete data, adversarial scenarios — requires Opus-level reasoning |
| Senior Reviewer | claude-opus-4-6 | Final decision authority, must weigh conflicting signals — high-stakes, needs best model |
| Finance | claude-sonnet-4-5 | Arithmetic, threshold checking, payment record writing — deterministic enough for Sonnet |

**Cost note from docs:** "each sub-agent has its own context and token usage. For heavy or repetitive tasks, set a cheaper model for sub-agents and keep your main agent on a higher-quality model." Use `agents.defaults.subagents.model` for the cheap default, then override per-agent for the ones that need Opus.

**Confidence:** MEDIUM — model IDs verified in OpenClaw docs and Anthropic provider page; role-to-model mapping is reasoned from capability characteristics, not from a published benchmark

#### Pattern 5: Shared State via File System (Claim JSON)

OpenClaw workspace is the agent's home directory. All agents share a mounted directory for claim state files:

```
shared/state/claims/CLM-2026-00001.json
```

Each pipeline agent:
1. Reads the claim JSON at the start of its run
2. Performs its analysis
3. Writes its section and updates `status`
4. Router reads the updated file and spawns the next agent

This is the pattern directly demonstrated in the hackathon challenge doc's `sessions_spawn` example:
```
task="Process claim CLM-2026-00001. Read shared/state/claims/CLM-2026-00001.json.
      Verify policy coverage. Update the claims_officer section and set status accordingly."
```

**Confidence:** HIGH — pattern from hackathon challenge doc + confirmed by agent workspace behavior in OpenClaw docs

### Database / State Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| JSON files (flat file) | N/A | Claim state storage | Simplest implementation; OpenClaw agents communicate via file system naturally; zero setup time; human-readable for demo; audit log appended to same file |
| SQLite | 3.x | Optional: policy mock DB, fraud pattern rules | Available via `exec` tool; zero config; no server process; adequate for hackathon scale |

**Database decision: JSON files for claim state, SQLite only if needed for policy lookup.**

**Why NOT Postgres:**
- Requires running a separate server process
- Adds connection config complexity
- Not necessary for single-demo scale (10-20 test claims)
- Setup time in a 10-hour hackathon is non-trivial
- OpenClaw agents already communicate via file system — fighting the natural pattern

**Why NOT pure in-memory / no persistence:**
- Claim state must survive agent crashes and restarts
- Audit log must be durable (regulatory requirement in insurance — judges will evaluate this)
- JSON files provide natural audit trail: append-only `audit_log` array

**Why JSON files win for claim state:**
- Zero dependencies
- Instantly readable by demo audience
- Agents can use `read` and `write` tools without any library
- Schema-validated via JSON Schema in `shared/schemas/claim.json`
- Easy to `cat` during demo to show state transitions

**Why SQLite for policy data:**
- Policy lookups may involve filtering (by policy number, coverage type, date range)
- SQLite query via `exec` + `sqlite3` CLI is fast to implement
- Alternatively: a flat JSON array of policies works for hackathon scale

**Confidence:** HIGH for "JSON files for claim state"; MEDIUM for "SQLite for policy data" (depends on complexity of policy lookup needed)

### Infrastructure

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ubuntu 22.04 LTS | 22.04 | VPS OS | OpenClaw Hetzner guide targets Ubuntu/Debian; LTS guarantees stability |
| Docker + Docker Compose | 24.x | OpenClaw deployment container | Official OpenClaw Hetzner installation method; volumes for state persistence |
| SSH tunnel | N/A | Secure access to gateway on VPS | OpenClaw docs recommend keeping gateway loopback-only (`127.0.0.1:18789`) and accessing via SSH tunnel — avoids firewall exposure |
| Hetzner CX21 or equivalent | N/A | VPS compute | 2 vCPU, 4GB RAM sufficient for gateway + all 7 agents at hackathon scale |

**Deployment approach: Docker on VPS (direct install alternative viable)**

**Why Docker over direct install:**
- Official documented path for Hetzner VPS (from live docs fetch of `docs.openclaw.ai/install/hetzner.md`)
- Volume mounts for `~/.openclaw/` provide clean separation of config from container
- Reproducible across team member machines
- `setup.sh` wraps: `git clone`, `.env` population, `docker compose up -d`

**Why NOT Kubernetes or Fly.io:**
- Over-engineered for a 10-hour hackathon demo
- OpenClaw is a single gateway process — no horizontal scaling needed
- Additional complexity = time lost

**Confidence:** HIGH — from live fetch of official Hetzner installation guide

### Supporting Libraries / Tools

| Library/Tool | Purpose | When to Use |
|-------------|---------|-------------|
| `jq` (CLI) | Parse and display claim JSON during demo | Always — install in Docker image or on VPS for demo scripts |
| `sqlite3` (CLI) | Query policy database if using SQLite | Only if policy lookup needs SQL filtering |
| `openclaw doctor` | Validate agent config before hackathon | Run on fresh VPS after setup to detect config issues |
| `openclaw agents list --bindings` | Verify agent routing is correct | After configuring `openclaw.json` |
| `/subagents list` | Inspect active sub-agent runs | During demo to show live pipeline state |
| Anthropic prompt caching (`cacheRetention: "short"`) | Reduce token cost for repeated AGENTS.md injection | Enable by default for all Anthropic API calls |

---

## Installation

```bash
# On VPS (Ubuntu): install Docker
apt-get update && apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sh

# Clone project repo
git clone https://github.com/<team>/ohio-mutual-hackathon /opt/ohio-mutual
cd /opt/ohio-mutual

# Configure environment
cp .env.example .env
# Edit .env: ANTHROPIC_API_KEY, OPENCLAW_GATEWAY_TOKEN

# Pull and start OpenClaw via Docker Compose
docker compose pull
docker compose up -d

# Verify
docker compose logs -f
openclaw doctor  # or: docker compose exec openclaw openclaw doctor
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| JSON files for claim state | SQLite for all state | If claim queries get complex (multi-claim aggregation, filtering) — add SQLite then |
| JSON files for claim state | Postgres | Only if scaling beyond hackathon to production; overkill here |
| Docker deployment | Direct Node.js install (`npm install -g openclaw`) | If Docker unavailable or VPS has < 2GB RAM; direct install is lighter |
| claude-opus-4-6 for Router + high-reasoning agents | claude-sonnet-4-5 for all agents | If token budget is constrained and demo simplicity is acceptable |
| SSH tunnel for gateway access | Public bind with token auth | If SSH access is inconvenient during demo; add firewall rule for specific IP |
| Flat file audit log in claim JSON | Separate audit database | For production — hackathon judges can read the JSON directly, which is a feature |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Postgres (or any server DB) | Requires separate server process, connection config, migration scripts — kills setup time in hackathon | JSON files for claim state, SQLite optionally for policy data |
| `maxSpawnDepth: 1` (default) | Depth 1 sub-agents do NOT get `sessions_spawn` — prevents orchestrator pattern; Router cannot spawn pipeline agents | Set `maxSpawnDepth: 2` in `agents.defaults.subagents` |
| `SOUL.md` for agent personality (alone) | Sub-agents only inject `AGENTS.md` + `TOOLS.md` — SOUL.md is NOT loaded for sub-agent runs | Embed role personality and constraints directly in `AGENTS.md` |
| Reusing `agentDir` across agents | Causes auth/session collisions per docs: "Never reuse `agentDir` across agents" | Each agent gets its own unique `agentDir` path |
| `sandbox.mode: "non-main"` default | Based on `session.mainKey`, not agent id — group/channel sessions always get sandboxed; for claims pipeline agents that should run unsandboxed, this creates confusion | Set `sandbox.mode: "off"` explicitly on pipeline agents where no sandbox isolation is needed |
| Global tool allow without per-agent override | Grants every agent the same tools — violates least-privilege principle the judges will evaluate | Use `agents.list[].tools.allow/deny` per agent |
| claude-opus-4-6 for ALL agents | Unnecessary cost for deterministic tasks (form intake, payment arithmetic) | Use Sonnet for Front Desk, Claims Officer, Finance; Opus for Assessor, Fraud Analyst, Senior Reviewer, Router |
| Fly.io / Railway / cloud PaaS | Adds DNS, TLS, billing config overhead; not justified for hackathon | Hetzner VPS with Docker Compose |

---

## Stack Patterns by Variant

**If the "secret addition" adds a new agent role (e.g., "Compliance Officer"):**
- Add new entry to `agents.list` with own workspace directory
- Add new `agentDir` path
- Router spawns new agent in sequence — no change to existing agent configs
- New workspace needs only `AGENTS.md` (with role + personality embedded)

**If the "secret addition" adds a regulatory requirement (e.g., mandatory human review step):**
- Senior Reviewer agent uses `message` tool to send escalation notification
- Router waits for explicit signal (status file update) before proceeding to Finance
- No architecture change needed — file-based state naturally supports pause/resume

**If the "secret addition" introduces concurrent claim surge:**
- `maxConcurrent: 8` already set in defaults — handles up to 8 parallel sub-agents
- Multiple Router sessions can be spawned for different claims concurrently
- File system isolation per claim ID (CLM-2026-00001, CLM-2026-00002) prevents collision

**If the "secret addition" requires fraud escalation to a human:**
- Fraud Analyst writes `"escalation_required": true` to claim JSON
- Senior Reviewer reads this flag and activates `message` tool to notify human
- System can pause at Senior Reviewer stage — natural human-in-the-loop point

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| OpenClaw v2026.1.6+ | Node.js 20 LTS | Per-agent sandbox available from v2026.1.6 per docs |
| anthropic/claude-opus-4-6 | OpenClaw Anthropic provider | Confirmed in official Anthropic provider docs |
| anthropic/claude-sonnet-4-5 | OpenClaw Anthropic provider | Confirmed in multi-agent routing docs example |
| Anthropic prompt caching | API key auth only | "API-only; subscription auth does not honor cache settings" — use API key, not setup-token |

---

## Sources

- `reference/openclaw-docs/tools/subagents.md` — sessions_spawn, maxSpawnDepth, orchestrator pattern, SOUL.md exclusion (HIGH confidence)
- `reference/openclaw-docs/concepts/multi-agent.md` — agent isolation, agentDir, tool scoping, model config (HIGH confidence)
- `reference/openclaw-docs/tools/multi-agent-sandbox-tools.md` — per-agent tool allow/deny, sandbox modes, filtering order (HIGH confidence)
- `reference/openclaw-docs/concepts/agent-workspace.md` — workspace layout, AGENTS.md/SOUL.md/TOOLS.md purpose (HIGH confidence)
- `reference/openclaw-docs/concepts/agent.md` — bootstrap file injection, sub-agent context limitations (HIGH confidence)
- `reference/openclaw-docs/concepts/memory.md` — SQLite memory store, memory_search tools (HIGH confidence)
- `reference/openclaw-docs/concepts/architecture.md` — Gateway architecture, WebSocket, systemd supervision (HIGH confidence)
- Live fetch: `https://docs.openclaw.ai/install/hetzner.md` — Docker Compose deployment, volumes, VPS setup (HIGH confidence)
- Live fetch: `https://docs.openclaw.ai/providers/anthropic.md` — API key setup, model IDs, prompt caching config (HIGH confidence)
- `reference/hackathon-challenge.md` — sessions_spawn usage example, pipeline design (source document)
- `.planning/PROJECT.md` — team constraints, deployment target, judging criteria

---
*Stack research for: OpenClaw multi-agent auto insurance claims processing*
*Researched: 2026-02-17*
