# Decision Log

Every architectural and design decision made for the Ohio Mutual Auto Claims Processing System, with alternatives considered and rationale documented. This log serves Q&A defense -- judges can ask "why did you choose X?" and every answer is here.

---

## Decision Table

| # | Decision | Options Considered | Choice | Rationale |
|---|----------|-------------------|--------|-----------|
| 1 | Database: JSON files | Postgres, SQLite, JSON files | JSON files | Zero setup, demo-readable, audit-friendly, native to OpenClaw filesystem tools |
| 2 | Model tiering | Opus everywhere, Sonnet everywhere, mixed | Mixed (Opus + Sonnet) | Cost optimization without quality sacrifice -- Opus for reasoning, Sonnet for deterministic |
| 3 | maxSpawnDepth: 1 | Depth 1, Depth 2 | Depth 1 | Router is depth-0 main agent, pipeline agents are depth-1 leaves. No nesting needed. |
| 4 | AGENTS.md only (no SOUL.md) | SOUL.md + AGENTS.md, AGENTS.md only | AGENTS.md only | Sub-agents only receive AGENTS.md + TOOLS.md. SOUL.md is invisible to depth-1 agents. |
| 5 | Sequential pipeline | Parallel stages, sequential | Sequential | Correctness: fraud analysis needs damage estimate, reviewer needs fraud score |
| 6 | Reasoning frameworks | Rule tables, reasoning frameworks | Reasoning frameworks | Challenge disqualifies hardcoded rules. LLM reasoning from principles is more adaptable. |
| 7 | agentToAgent disabled | Enable direct messaging, disable | Disabled | All communication through claim JSON + Router mediation preserves audit trail |
| 8 | Tool scoping: least privilege | Full tools for all, least privilege | Least privilege | Finance is only pipeline agent with exec. No pipeline agent can spawn. |
| 9 | VPS deployment: Docker Compose | Docker, direct install, cloud PaaS | Docker Compose | Official documented path, reproducible, volume mounts for state persistence |
| 10 | Shared filesystem for state | API calls, message passing, shared files | Shared files | Native to OpenClaw workspace model. Maximum demo legibility. |
| 11 | Router allowAgents: explicit list | Wildcard (*), explicit list | Explicit list | Least-privilege: Router can only spawn the 6 registered pipeline agent IDs |
| 12 | Prompt caching enabled | Enabled, disabled | Enabled (cacheRetention: short) | Reduces token cost for repeated AGENTS.md injection across sessions |
| 13 | Coverage denial shortcut | Process all stages, skip stages | Skip to Senior Reviewer | No point assessing damage or fraud on uncovered claims; saves tokens and time |
| 14 | Router owns status transitions | Agents set status, Router sets status | Router sets status | Prevents inconsistent state from partial agent failures |
| 15 | Escalation by Router, not agents | Agent writes escalation, Router writes | Router writes | Router has full pipeline context individual agents lack |

---

## Detailed Decision Records

### Decision 1: JSON Files for Claim State

**Context:** Need a persistence layer for claim data that all 7 agents can read and write.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| PostgreSQL | SQL queries, concurrent access, ACID | Server process, connection config, migration scripts, 30+ min setup |
| SQLite | Zero-server, SQL queries, single file | Library dependency, schema migration, harder to inspect mid-demo |
| JSON files | Zero setup, human-readable, git-trackable, native to OpenClaw read/write tools | No queries, no built-in locking, no relational features |

**Choice:** JSON files

**Rationale:** For a 10-hour hackathon, every minute of setup is a minute not spent on business logic. JSON files give us: zero dependencies, instant readability during the demo (`cat` the claim file for judges), full auditability (every field change is visible), and native compatibility with OpenClaw's `read` and `write` tools. The sequential pipeline pattern guarantees single-writer-per-claim, eliminating the need for file locking. If a judge asks "what about at scale?" -- we acknowledge the limit and explain the migration path to SQLite or Postgres for production.

**Impact:** All agents use file-system read/write. No database drivers, no connection pools, no schema migrations.

---

### Decision 2: Mixed Model Tiers (Opus + Sonnet)

**Context:** Each agent needs an LLM model. Claude offers Opus (strongest reasoning, highest cost) and Sonnet (fast, cost-efficient, good for structured tasks).

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Opus everywhere | Maximum quality on every stage | Expensive, slow for simple tasks |
| Sonnet everywhere | Fast, cheap | Insufficient reasoning for fraud detection and final decisions |
| Mixed (Opus + Sonnet) | Optimal cost-quality balance | Slightly more complex config |

**Choice:** Mixed -- Opus for Router, Assessor, Fraud Analyst, Senior Reviewer; Sonnet for Front Desk, Claims Officer, Finance

**Rationale:** The Router needs complex planning and error handling. The Assessor estimates damage from descriptions. The Fraud Analyst detects adversarial patterns from incomplete data. The Senior Reviewer weighs conflicting signals for the final decision. These four roles benefit from Opus-level reasoning. The Front Desk extracts structured data. The Claims Officer matches policy fields. Finance does arithmetic. These three roles have well-defined, deterministic tasks where Sonnet performs equally well at lower cost. OpenClaw docs specifically recommend: "set a cheaper model for sub-agents and keep your main agent on a higher-quality model."

**Impact:** `agents.list[].model` field set per agent in `openclaw.json`.

---

### Decision 3: maxSpawnDepth Set to 1

**Context:** OpenClaw's `maxSpawnDepth` controls how many levels of sub-agents can exist. The Router needs to spawn pipeline agents.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| maxSpawnDepth: 1 (default) | Simple config, pipeline agents are leaves | STACK.md initially recommended 2 |
| maxSpawnDepth: 2 | Depth-1 agents could spawn depth-2 workers | Unnecessary complexity, grants session tools to pipeline agents |

**Choice:** maxSpawnDepth: 1

**Rationale:** The Router is the depth-0 main agent. Main agents always have `sessions_spawn` regardless of maxSpawnDepth. Pipeline agents are depth-1 leaf workers that should never spawn further agents. Setting depth to 2 would unnecessarily grant session tools to depth-1 agents, violating least-privilege. The STACK.md recommendation of 2 was based on the assumption that depth-1 agents need `sessions_spawn` -- they do not in our architecture because the Router (depth-0 main agent) owns all spawning.

**Impact:** Simpler configuration, fewer failure modes, pipeline agents cannot accidentally spawn sub-agents.

---

### Decision 4: AGENTS.md Only (No SOUL.md for Sub-Agents)

**Context:** OpenClaw workspace files include AGENTS.md (operating instructions) and SOUL.md (persona/personality). Both are loaded for the main agent, but sub-agents only receive AGENTS.md + TOOLS.md.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| SOUL.md + AGENTS.md | Separation of concerns (persona vs instructions) | SOUL.md invisible to depth-1 sub-agents -- critical instructions lost |
| AGENTS.md only | Single source of truth, everything injected | Longer AGENTS.md files |

**Choice:** AGENTS.md only, no SOUL.md in any workspace

**Rationale:** Sub-agents spawned via `sessions_spawn` receive ONLY AGENTS.md + TOOLS.md. SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, and BOOTSTRAP.md are NOT injected. If we put personality or critical instructions in SOUL.md, pipeline agents would never see them. For consistency, even the Router (the only depth-0 agent where SOUL.md would work) uses AGENTS.md exclusively. This eliminates the documented pitfall of split configuration.

**Impact:** All operating instructions, personality traits, and domain knowledge embedded in each agent's AGENTS.md file.

---

### Decision 5: Sequential Pipeline (Not Parallel)

**Context:** The 6 pipeline agents could theoretically run in parallel (all at once) or sequentially (one after another).

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Parallel stages | Faster end-to-end processing | Business logic mandates ordering; race conditions on shared state |
| Sequential stages | Correct ordering, single-writer, no locking | Slower for any single claim |

**Choice:** Sequential (each stage completes before the next starts)

**Rationale:** This is a correctness requirement, not a performance trade-off:
- Fraud analysis cannot run before damage assessment (needs repair estimate to flag inflation)
- Senior Reviewer cannot decide before fraud analysis (needs risk score)
- Coverage denial shortcuts the pipeline (stages 3, 4, 6 are skipped)
- Sequential guarantees single-writer-per-claim, eliminating all race conditions

For the hackathon, a single claim processes in under 5 minutes through all 6 stages. Different claims can process in parallel (each has its own file). Performance is not a concern.

**Impact:** Router uses announce-wait-read-spawn cycle. One active agent per claim at a time.

---

### Decision 6: Reasoning Frameworks (No Hardcoded Rules)

**Context:** The hackathon challenge states: "Plan for human reasoning: your thinking should not be hardcoded."

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Rule tables | Deterministic, predictable | Explicitly disqualified by challenge rules; breaks on secret addition |
| Reasoning frameworks | Adaptable, natural language audit trail | Slight non-determinism between runs |

**Choice:** Reasoning frameworks (judgment principles in AGENTS.md)

**Rationale:** The challenge explicitly disqualifies hardcoded rules. All AGENTS.md files use reasoning principles instead of numerical thresholds. Examples:
- "When repair cost approaches or exceeds the threshold relative to ACV" (not "if repair > 75% * ACV")
- "When multiple indicators converge" (not "if risk_score > 70")
- "Acknowledge within the regulatory window for the applicable jurisdiction" (not "15 days")

This approach adapts naturally to the secret addition (business context changes don't require code changes -- just update the principle context) and produces natural language reasoning in the audit log that judges can evaluate.

**Impact:** Every AGENTS.md template uses principles and frameworks. Zero numerical if/then thresholds.

---

### Decision 7: agentToAgent Disabled

**Context:** OpenClaw supports direct agent-to-agent messaging (`tools.agentToAgent.enabled`). Should pipeline agents talk directly to each other?

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Enable direct messaging | Faster agent-to-agent communication | Breaks audit trail, Router loses visibility, complex debug |
| Disable (Router mediates all) | Complete audit trail, Router has full control | Slightly more overhead per transition |

**Choice:** Disabled (`tools.agentToAgent.enabled: false`)

**Rationale:** All inter-agent communication flows through the shared claim file and Router mediation. If the Fraud Analyst could message the Senior Reviewer directly, those messages would not appear in the claim file audit log. The Router would lose visibility into what pipeline agents are telling each other. For judges evaluating audit trail completeness, every decision must be traceable through the claim JSON. Router mediation also enables context enrichment -- the Router injects regulatory context and prior-stage summaries that individual agents would not know to share.

**Impact:** No `message` tool on any pipeline agent. All data flows through claim JSON.

---

### Decision 8: Least-Privilege Tool Scoping

**Context:** Each agent needs tools to do its job. OpenClaw allows per-agent `tools.allow` and `tools.deny` lists.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Full tools for all agents | Simple config | Finance could browse the web; Fraud Analyst could spawn sub-agents |
| Least privilege per agent | Security, demonstrates awareness | More lines in openclaw.json |

**Choice:** Least privilege -- each agent gets exactly what it needs

**Rationale:**
- **Router:** read, write, exec, all sessions tools (orchestration requires spawning)
- **Pipeline agents (5 of 6):** read, write only (reasoning from JSON, not executing scripts)
- **Finance:** read, write, exec (mock payment simulation requires exec)
- **All pipeline agents:** sessions_spawn explicitly denied (must not spawn sub-agents)

This demonstrates security awareness to judges. In real insurance systems, the finance function should not have access to spawn agents, and the fraud detection function should not be able to execute arbitrary scripts.

**Impact:** 7 distinct tool configurations in `openclaw.json`.

---

### Decision 9: Docker Compose on Hetzner VPS

**Context:** Need to deploy the OpenClaw gateway on a server for the hackathon demo.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Docker Compose on Hetzner | Official documented path, reproducible, volume mounts | Requires Docker installation |
| Direct Node.js install | Lighter, no Docker overhead | Not the official path, harder to reproduce |
| Cloud PaaS (Fly.io, Railway) | Managed infrastructure | DNS/TLS/billing overhead, not documented for OpenClaw |

**Choice:** Docker Compose on Hetzner VPS (Ubuntu 22.04)

**Rationale:** This is the officially documented deployment path for OpenClaw. The `setup.sh` script handles Docker installation, project clone, environment configuration, and Docker Compose startup in a single command. Volume mounts for `~/.openclaw/` provide clean separation of config from container. The gateway binds to `localhost:18789` only -- team accesses via SSH tunnel for security. A Hetzner CX21 (2 vCPU, 4GB RAM) is more than sufficient for the hackathon demo scale.

**Impact:** `scripts/setup.sh` provisions from bare Ubuntu to running gateway.

---

### Decision 10: Shared Filesystem for Agent Communication

**Context:** How do agents share data between pipeline stages?

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| API calls between agents | Real-time, request/response | Complex infrastructure, no persistence, hard to audit |
| Message passing | Async, decoupled | Message queue overhead, no persistent state |
| Shared filesystem (JSON files) | Native to OpenClaw, zero setup, fully auditable | No real-time queries |

**Choice:** Shared filesystem with JSON files

**Rationale:** OpenClaw agents naturally operate on a shared filesystem. Every agent has `read` and `write` tools that work on files. The claim JSON file IS the shared state, the audit trail, and the integration contract between agents. During the demo, the team can `cat` the claim file and show judges exactly what each agent wrote. This is maximum legibility -- judges see real data, not API responses hidden behind abstractions.

**Impact:** `shared/state/claims/` directory holds all active claims. All agents read/write to it via absolute paths provided by the Router.

---

### Decision 11: Router allowAgents as Explicit List

**Context:** The Router's `subagents.allowAgents` setting controls which agents it can spawn.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Wildcard `["*"]` | Simple, flexible | Router could spawn any agent, including itself |
| Explicit list of 6 IDs | Least-privilege, documents valid targets | More config, must update if adding agents |

**Choice:** Explicit list: `["front-desk", "claims-officer", "assessor", "fraud-analyst", "senior-reviewer", "finance"]`

**Rationale:** The Router should only spawn the 6 registered pipeline agents. A wildcard would allow spawning any agent ID, including agents that don't exist or the Router itself (potentially causing infinite loops). The explicit list documents the valid spawn targets and enforces least-privilege. If the secret addition requires a new agent, adding its ID to the list is a one-line change.

**Impact:** `openclaw.json` Router config includes `subagents.allowAgents` with 6 IDs.

---

### Decision 12: Prompt Caching Enabled

**Context:** Anthropic's prompt caching can reduce token cost for repeated system prompt injection.

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Enabled (cacheRetention: short) | Reduced cost on repeated AGENTS.md injection | Minimal -- already default for API key auth |
| Disabled | None | Higher token cost |

**Choice:** Enabled explicitly (`cacheRetention: "short"` on both Opus and Sonnet model configs)

**Rationale:** While prompt caching is the default for Anthropic API key authentication, making it explicit in `openclaw.json` ensures it is not accidentally overridden and documents the decision. Each sub-agent session injects AGENTS.md as the system prompt -- prompt caching reduces the cost of this repeated injection across multiple claims. At hackathon scale (10-20 claims), the cost savings are modest but the principle is sound.

**Impact:** `models` block in `openclaw.json` sets `cacheRetention: "short"` for both model configs.

---

### Decision 13: Coverage Denial Shortcut Path

**Context:** When the Claims Officer determines a claim is not covered (`covered=false`), should the pipeline continue through all remaining stages?

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Process all stages | Consistent pipeline, all agents run | Wastes tokens assessing damage and fraud on uncovered claims |
| Skip to Senior Reviewer | Efficient, reflects real insurance operations | Slightly more complex Router logic |

**Choice:** Skip Assessor, Fraud Analyst, and Finance; go directly to Senior Reviewer

**Rationale:** In real insurance operations, denied claims do not go through damage assessment or fraud analysis -- there is nothing to assess or investigate. However, denied claims DO get supervisory review to prevent bad faith exposure. The Senior Reviewer reviews the denial reasoning and confirms or overrides the decision. This shortcut saves tokens and processing time while maintaining compliance.

**Impact:** Router logic checks `covered` field after Claims Officer. If false, status is set to DENIED and only Senior Reviewer is spawned with a modified task message.

---

### Decision 14: Router Owns All Status Transitions

**Context:** Should pipeline agents update the claim's top-level `status` field, or should the Router do it after validation?

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Agents set status directly | Simpler agent logic | Partial failure leaves inconsistent status; no validation gate |
| Router sets status after validation | Validated, consistent transitions | Router must parse and validate each stage's output |

**Choice:** Router owns all status transitions

**Rationale:** If a pipeline agent crashes mid-write, the claim status could be advanced even though the agent's section data is incomplete. By having the Router validate the agent's output before transitioning status, we guarantee that every status change corresponds to a complete, validated stage output. This is a safety net that prevents inconsistent claim state.

**Impact:** Pipeline agents write their section data but do not change the top-level `status` field. The Router reads, validates, and transitions.

---

### Decision 15: Escalation Record Written by Router

**Context:** When a pipeline agent triggers an escalation, who constructs the escalation record?

**Options Considered:**

| Option | Pros | Cons |
|--------|------|------|
| Pipeline agent writes escalation | Agent has immediate context | Agent lacks full pipeline context (time_in_pipeline, stages_remaining, regulatory deadlines) |
| Router writes escalation | Full pipeline context available | Slight delay between agent announce and record creation |

**Choice:** Router constructs and writes the escalation record

**Rationale:** Individual pipeline agents only know about their own stage. The Router has the complete picture: how long the claim has been in the pipeline, which stages completed, which remain, regulatory deadline proximity, and escalation urgency. The Router constructs a richer escalation record that gives human reviewers everything they need to make a decision. The agent announces ESCALATE with its findings; the Router wraps those findings in full pipeline context.

**Impact:** Escalation JSON structure includes `stages_completed`, `stages_remaining`, `time_in_pipeline`, `regulatory_context` -- all of which only the Router knows.

---

*Decision log for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*Every decision documented for Q&A defense at OpenClaw Business Engineering Hackathon, Feb 21, 2026*
