# Project Research Summary

**Project:** Ohio Mutual Hackathon — Multi-Agent Auto Insurance Claims Processing
**Domain:** Multi-agent orchestration + regulated insurance claims pipeline
**Researched:** 2026-02-17
**Confidence:** HIGH

## Executive Summary

This is a 10-hour hackathon build on the OpenClaw multi-agent framework for auto insurance claims processing. The correct approach is a sequential 6-stage pipeline: Front Desk (FNOL intake) → Claims Officer (coverage verification) → Assessor (damage estimation) → Fraud Analyst (risk scoring) → Senior Reviewer (final decision gate) → Finance (payment calculation). A Router agent orchestrates all stages using `sessions_spawn`, reading and writing a shared claim JSON file as the single source of truth. The architecture is simple by design — JSON files for state, no database, AGENTS.md as the only business logic surface — and this simplicity is a feature, not a compromise.

The judging criteria split 50/50 between business thinking and system thinking. Business credibility requires deep insurance domain knowledge baked into each agent's AGENTS.md: Ohio's 100% ACV total loss rule, FCSP regulatory timelines (10-15 day acknowledgment, 40-day decision), named fraud patterns (staged accidents, phantom passengers, paper accidents), soft vs. hard fraud distinction, subrogation logic, OEM vs. aftermarket parts decisions, and explicit human-in-the-loop escalation triggers. System coherence requires each agent to have only the tools it needs (least-privilege), unique agentDir paths, and a demonstrably working end-to-end pipeline before Hour 5.

The single biggest risk is a broken demo at presentation time. The second biggest risk is agents with hardcoded rule thresholds, which the challenge brief explicitly disqualifies. Both risks have the same mitigation: build an integration harness in Hour 1 with stub agents, run the full pipeline by Hour 5, and write AGENTS.md as reasoning frameworks rather than rule tables. The architecture naturally handles the hackathon's "secret addition" because all business logic lives in editable AGENTS.md files — no code changes required when the secret addition arrives.

## Key Findings

### Recommended Stack

The stack is defined by the hackathon constraint: OpenClaw is the only permitted framework. Within that constraint, every other choice should minimize setup time and maximize demo readability. Use `claude-opus-4-6` for the Router, Assessor, Fraud Analyst, and Senior Reviewer (high-reasoning roles), and `claude-sonnet-4-5` for Front Desk, Claims Officer, and Finance (structured, deterministic roles). This model tiering reduces token cost without sacrificing output quality where it matters.

For state management, JSON files on the shared filesystem are the correct choice — zero setup, instantly readable via `cat` during the demo, fully auditable as an append-only `audit_log` array, and natively aligned with how OpenClaw agents communicate. Postgres requires a running server process. SQLite adds debugging complexity. Neither is justified in a 10-hour build. Deployment is Docker Compose on a Hetzner CX21 VPS (Ubuntu 22.04) following the official documented path, accessed via SSH tunnel.

**Core technologies:**
- OpenClaw Gateway v2026.1.6+: multi-agent orchestration host — only supported framework per hackathon rules
- claude-opus-4-6: LLM for Router, Assessor, Fraud Analyst, Senior Reviewer — high-reasoning roles require Opus
- claude-sonnet-4-5: LLM for Front Desk, Claims Officer, Finance — deterministic enough for Sonnet
- JSON files (flat file): claim state and policy mock data — zero setup, demo-readable, audit-friendly
- Docker Compose on Hetzner CX21: deployment — official documented path, reproducible setup
- `jq` CLI: claim state inspection during demo — install in Docker image or VPS

**Critical version note:** `maxSpawnDepth` must be set appropriately. ARCHITECTURE.md recommends `maxSpawnDepth: 1` (Router at depth 0 spawns depth-1 pipeline agents; pipeline agents do not need to spawn further). STACK.md recommends `maxSpawnDepth: 2` for cases where the secret addition might require nested spawning. The safer default for a 10-hour build is `maxSpawnDepth: 1` unless nesting is confirmed needed — but PITFALLS.md confirms that failing to set this correctly breaks the entire orchestrator pattern.

### Expected Features

The hackathon requires both business credibility features (table stakes) and system differentiators. Missing any P1 table stakes feature immediately fails the Business Thinking dimension. The 3 demo scenarios (happy path collision, fraud rejection, coverage denial) must exercise all P1 features to be credible.

**Must have (table stakes):**
- FNOL intake with structured data capture and claim categorization — without this, nothing starts
- Policy lookup, coverage verification, exclusion check, deductible determination — core Claims Officer function
- Damage estimate + total loss determination using Ohio's 100% ACV rule — wrong threshold = credibility failure
- Fraud scoring with 4-5 named patterns (staged accident, phantom passenger, paper accident, inflated repair, prior damage) — generic "suspicious" is not insurance fraud
- Senior Reviewer decision gate with explicit approval / denial / escalate paths — judges will ask "what stops bad payments?"
- Finance payment calculation (estimate minus deductible, subrogation flag) — without math, the system is not processing claims
- Audit log with reasoning on every agent decision — required by FCSP; also proves the pipeline worked during demo
- 3-5 mock policy records (active, lapsed, excluded driver, high deductible, comprehensive-only) — needed to demonstrate all claim paths

**Should have (competitive differentiators):**
- Soft fraud vs. hard fraud distinction (SIU referral for hard fraud, negotiated settlement for soft) — few teams will know this
- FCSP timeline tracking — 10-15 day acknowledgment, 40-day decision, 30-day payment; show timestamps in audit log
- OEM vs. aftermarket parts recommendation (vehicles under 3 years/36K miles get OEM) — demonstrates deep domain knowledge
- Subrogation flag when third-party is at fault — adds business value to Finance agent
- Human-in-the-loop escalation with explicit triggers (fraud score > 70, claim > $25K, total loss, legal rep letter received)
- Pre-existing damage detection in Assessor output
- Rental reimbursement calculation from repair timeline estimate

**Defer (v2+ or Q&A awareness only):**
- UM/UIM routing (too complex to build, discuss in Q&A)
- Diminished value calculation (know the 17c formula for Q&A, do not compute it live)
- 50-state regulatory variation (Ohio only; state modular architecture for production)
- Real payment processing, real photo AI, customer-facing portal

### Architecture Approach

The system follows a sequential pipeline orchestration pattern: one Router agent (depth 0) spawns each of 6 specialist pipeline agents (depth 1) one at a time via `sessions_spawn`, waits for the announce, reads the updated claim JSON, then spawns the next stage. Sequential ordering is a correctness requirement — fraud analysis cannot run before the damage estimate exists to evaluate for inflation; Senior Reviewer cannot decide before Fraud Analyst scores. The shared claim JSON file is the API between agents: each agent reads the full file, writes its section, appends to `audit_log`, and announces completion. The Router owns all state transitions. Pipeline agents are stateless workers that transform the claim file.

**Major components:**
1. OpenClaw Gateway — routing, session management, WebSocket server; all agents are registered agent processes within the gateway
2. Router Agent (Orchestrator) — state machine owner; spawns pipeline agents, reads announces, decides next action, owns claim lifecycle transitions; all logic in AGENTS.md
3. 6 Pipeline Agents (Front Desk, Claims Officer, Assessor, Fraud Analyst, Senior Reviewer, Finance) — each has a unique workspace, unique agentDir, least-privilege tool set, and all operating instructions in AGENTS.md (not SOUL.md, which is invisible to sub-agents)
4. Shared Filesystem (shared/) — single cross-agent state surface; claim JSON files, mock policy JSON files, schema, test scenarios; all agents access via absolute paths
5. Demo Scripts (scripts/) — `submit-claim.sh`, `check-status.sh`, `run-demo.sh`; the pipeline must be triggerable from a single command for the presentation

### Critical Pitfalls

1. **Hardcoded rules in AGENTS.md** — Write reasoning frameworks and principles, not numerical if/then thresholds. The challenge brief explicitly calls out "thinking should not be hardcoded" as a judging criterion. AGENTS.md should say "apply judgment proportional to claim size and fraud indicators, document your reasoning" — not "if score > 70 then escalate." Verify by reading AGENTS.md aloud and counting hardcoded thresholds; target is zero.

2. **No working end-to-end pipeline at demo time** — The single most common hackathon failure mode. Build an integration harness (`run-demo.sh`) in Hour 1 that submits a test claim and watches the claim JSON file update, even before agents have real logic. Use stub agents (always succeed, write minimal JSON) initially. Target: full pipeline working no later than Hour 5.

3. **SOUL.md context loss for sub-agents** — Sub-agents spawned via `sessions_spawn` only receive `AGENTS.md` and `TOOLS.md`. SOUL.md is invisible. Any agent personality, regulatory context, or operating rules in SOUL.md will be missing at runtime for spawned agents. Put ALL critical instructions in AGENTS.md. Verify by reading a spawned sub-agent's announce output and checking that domain context is present.

4. **agentDir reuse causing session collisions** — Copy-pasting agent config in `openclaw.json` without updating `agentDir` paths causes auth profile collisions between agents. Each agent must have a unique `agentDir`. Run `openclaw agents list --bindings` to verify before any testing.

5. **Over-engineering the infrastructure** — Any time spent on message queues, retry infrastructure, or databases is time not spent on the AGENTS.md business logic that judges actually score. Commit to the minimal architecture (JSON files, sequential spawning, AGENTS.md as logic) in the first hour and do not revisit.

6. **Fraud detection that auto-denies** — Fraud Analyst must flag and escalate, not detect and deny. Finance must verify `senior_reviewer.approved === true` before issuing payment. Any path where payment occurs without Senior Reviewer approval is both an architectural failure and a regulatory compliance violation.

## Implications for Roadmap

The entire hackathon is 10 hours. The roadmap should reflect build phases that produce a demonstrable system at each integration checkpoint, not phases defined by features or agents.

### Phase 1: Foundation Lock-in (Hour 0.5-1)

**Rationale:** Every team member building independently will create schema drift and integration failures if the shared contract is not defined first. This phase produces nothing runnable but prevents integration disasters later. All three downstream parallel workstreams depend on agreement established here.

**Delivers:** Final `claim.schema.json`, `shared/` directory structure, `openclaw.json` skeleton with all 7 agents registered, each agent's unique `agentDir` verified, model assignments per agent locked, `maxSpawnDepth` set and tested with a one-agent smoke test.

**Addresses features from FEATURES.md:** None yet — this is infrastructure setup.

**Avoids pitfalls:** agentDir collision (Pitfall 8), maxSpawnDepth misconfiguration (Pitfall 4), schema drift between parallel workstreams (Pitfall 2 root cause).

**No additional research needed** — all OpenClaw configuration patterns are documented with HIGH confidence.

### Phase 2: Parallel Agent Build + Integration Harness (Hours 1-3)

**Rationale:** With schema locked, three team members can build in parallel without blocking each other. The integration harness (run-demo.sh with stub agents) is built alongside — not after — the real agents. This is the crucial difference between teams that have a working demo and teams that don't.

**Delivers (Member A — Router + Infrastructure):** Router AGENTS.md with state machine logic, sequential spawn patterns, error handling, retry policy; `setup.sh` VPS deploy script; `submit-claim.sh` and `run-demo.sh` stub harness; `shared/test-claims/` test scenarios.

**Delivers (Member B — Front Desk + Claims Officer):** `front-desk/AGENTS.md` with FNOL intake checklist, claim categorization rules, CAT event tagging; `claims-officer/AGENTS.md` with coverage verification rules, exclusion list, policy lookup protocol, lapsed policy grace period awareness; `shared/policies/` mock policy database (5 records: active, lapsed, excluded driver, high deductible, comprehensive-only).

**Delivers (Member C — Assessor + Fraud Analyst):** `assessor/AGENTS.md` with damage estimation methodology, Ohio 100% ACV total loss rule, OEM vs. aftermarket logic, rental day calculation, pre-existing damage flag; `fraud-analyst/AGENTS.md` with named fraud patterns, soft vs. hard fraud distinction, fraud scoring rubric, SIU referral criteria.

**Addresses features from FEATURES.md:** All P1 table stakes for the first 4 pipeline stages.

**Avoids pitfalls:** SOUL.md context loss (build all instructions into AGENTS.md from the start); hardcoded rules (write reasoning frameworks, verify no numerical thresholds); over-engineering (no infrastructure beyond JSON files and shell scripts).

**No additional research needed** — all patterns documented. AGENTS.md content is rich domain knowledge already captured in FEATURES.md.

### Phase 3: First Integration Test (Hour 3)

**Rationale:** Integration failures compound if caught late. A forced checkpoint at Hour 3 — where the partial pipeline (Front Desk through Claims Officer) must run end-to-end — catches schema mismatches and path errors while there is still time to fix them without panic.

**Delivers:** Working `submit-claim.sh` → Front Desk → Claims Officer pipeline with real JSON written to `shared/state/claims/`. Verified audit_log populated. Router successfully awaits announce and reads updated claim file.

**Addresses features from FEATURES.md:** Validates FNOL intake, policy lookup, coverage verification, exclusion check, deductible determination are working correctly.

**Avoids pitfalls:** No-demo-at-presentation (Pitfall 2 — the primary kill); shared state path errors (Pitfall 5 variant).

**Research flag:** None. This is a verification milestone, not a new build phase.

### Phase 4: Senior Reviewer + Finance + Full Pipeline (Hours 3-5)

**Rationale:** The remaining two agents (Senior Reviewer and Finance) are simpler than the middle-pipeline agents and can be built while the integration test of Phase 3 is still fresh. End-to-end testing of all 6 stages must complete by Hour 5.

**Delivers (Member A — Senior Reviewer + Finance):** `senior-reviewer/AGENTS.md` with decision criteria (APPROVE/DENY/CONDITIONAL/ESCALATE_HUMAN), explicit escalation triggers (fraud score, claim value, total loss, legal rep), FCSP timeline compliance check, diminished value awareness note; `finance/AGENTS.md` with payout calculation rules (estimate minus deductible minus depreciation), subrogation flag logic, GAP awareness note, supplement payment path; `run-demo.sh` polished end-to-end script.

**Delivers (Members B + C — Integration):** Full pipeline happy path working; fraud escalation path working; coverage denial path working; audit_log validates complete chain; Senior Reviewer approval required before Finance runs (verified in Router logic).

**Addresses features from FEATURES.md:** All P1 table stakes for final 2 stages; FCSP timeline tracking (P2); human-in-the-loop escalation (P2); subrogation flag (P2).

**Avoids pitfalls:** Fraud detection without human-in-loop (Pitfall 9 — verify Finance checks `senior_reviewer.approved`); broken demo at presentation (Pitfall 2 — full pipeline must be working by Hour 5).

**No additional research needed** — patterns are standard.

### Phase 5: Secret Addition + Polish (Hours 5-7)

**Rationale:** The hackathon's secret addition arrives mid-event. The architecture's key advantage is that all business logic lives in AGENTS.md files — adding or modifying behavior requires updating 1-2 text files, not changing code. This phase is deliberately kept open. The team adapts to whatever the secret addition introduces.

**Delivers:** Secret addition incorporated into relevant AGENTS.md files; edge case testing (total loss, UM/UIM path awareness, bad faith deadline flag); P2 and P3 features added where time permits (rental reimbursement, pre-existing damage flags, FCSP timeline tracking); error handling validation (what happens when an agent times out or the claim JSON is malformed).

**Addresses features from FEATURES.md:** Remaining P2 features; Q&A preparation for P3 features (diminished value formula, UM/UIM routing explanation, CAT event tagging).

**Avoids pitfalls:** Secret addition breaking architecture (the AGENTS.md-first approach is the mitigation); over-engineering (resist scope creep into new infrastructure).

**Research flag:** The secret addition content is unknown. If it introduces a new agent role, a new regulatory requirement, or a concurrent claim surge requirement, the team needs to know the adaptation patterns — all three are documented in STACK.md's "Stack Patterns by Variant" section. No external research needed; the research already covers these scenarios.

### Phase 6: Demo Preparation (Hours 7-8.5)

**Rationale:** A system that works but cannot be demonstrated clearly loses to a simpler system that tells a good story. The demo script must be rehearsed with someone who has not seen the system, the three claim scenarios must each be verified runnable end-to-end, and Q&A preparation must cover the regulatory domain questions judges will ask.

**Delivers:** Three rehearsed demo scenarios (happy path collision, fraud rejection with SIU escalation, coverage denial on commercial use exclusion); pre-run backup outputs ready in case of live API failure; team can answer regulatory Q&A without looking anything up; presentation narrative drafted.

**Avoids pitfalls:** Weak demo narrative (UX Pitfall — narrate agent decisions live as they happen); demo depending on live internet (pre-run backup); showing code instead of running system.

**Research flag:** None. This is execution, not research.

### Phase Ordering Rationale

- Foundation must come first because three parallel workstreams cannot safely operate without a locked claim schema and shared directory structure.
- Parallel agent build in Phase 2 is the only way to complete 6 agent workspaces in 10 hours with 3 team members.
- Integration checkpoints at Hours 3 and 5 are non-negotiable — skipping them is the primary cause of broken hackathon demos.
- Secret addition in Phase 5 is correctly placed after the full pipeline works — attempting to incorporate it before the pipeline runs end-to-end is a trap.
- Demo prep gets 1.5 hours, which matches the industry pattern (16-20% of hackathon time) for events where presentation quality matters as much as technical completeness.

### Research Flags

Phases needing deeper research during planning:
- **Phase 5 (Secret Addition):** Unknown content. If the secret addition introduces a compliance officer role, a regulatory reporting requirement, or a concurrent surge scenario, review STACK.md's "Stack Patterns by Variant" section before building. No external research should be needed — the research already covers all three documented scenarios.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** All OpenClaw config patterns verified against official docs with HIGH confidence. No unknowns.
- **Phase 2 (Parallel Agent Build):** Domain knowledge is fully captured in FEATURES.md. AGENTS.md writing is content creation, not research.
- **Phase 3 (Integration Test):** Verification milestone only.
- **Phase 4 (Senior Reviewer + Finance + Full Pipeline):** Standard patterns, documented.
- **Phase 6 (Demo Prep):** Execution only.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | OpenClaw config patterns verified directly against local reference docs; Claude model IDs verified against Anthropic provider docs; Docker/Hetzner deployment verified against live official docs |
| Features | HIGH | Domain knowledge verified against NAIC, FCSP regulations, NICB, and insurance industry sources; Ohio-specific rules (100% ACV threshold) confirmed; fraud pattern statistics from cited 2024 data |
| Architecture | HIGH | All architectural decisions reference specific OpenClaw doc sections; claim schema is fully specified; build order with team member assignments is concrete |
| Pitfalls | HIGH (OpenClaw) / MEDIUM (insurance domain) | OpenClaw-specific pitfalls verified against official docs; insurance compliance pitfalls based on multiple cited sources but not verified against Ohio-specific regulatory filings |

**Overall confidence:** HIGH

### Gaps to Address

- **maxSpawnDepth discrepancy:** STACK.md recommends `maxSpawnDepth: 2` as the orchestrator enabler; ARCHITECTURE.md recommends `maxSpawnDepth: 1` (pipeline agents are leaves). Resolve in Phase 1 by confirming whether the Router is itself a sub-agent or the main agent. If Router is the depth-0 main agent (recommended), then `maxSpawnDepth: 1` is correct. If any scenario requires the Router to be spawned as a sub-agent of another process, `maxSpawnDepth: 2` is needed. Resolve this in the first 30 minutes.

- **Photo/image handling by Assessor:** The Assessor agent needs to analyze vehicle damage photos. Research is clear that live computer vision ML is an anti-feature. However, the exact mechanism for the Assessor to process photo metadata (path references vs. structured descriptions vs. image file reading) is not fully specified. Resolve in Phase 2 when writing Assessor AGENTS.md: treat photos as path references and description inputs, not live ML inference.

- **Finance agent exec scope:** Finance is the only agent with `exec` permission (for payment simulation). The exact script it calls (`exec` tool on what command) is not defined. Resolve in Phase 4: write a minimal `simulate-payment.sh` script that logs payment parameters and returns success; this is sufficient for demo purposes.

- **Ohio-specific fraud regulations:** Research covers FCSP timelines and common fraud patterns from national sources. Ohio-specific SIU referral requirements and bad faith exposure specifics were not verified against Ohio Department of Insurance filings. For the Q&A, frame answers around NAIC model law (which Ohio follows) rather than claiming Ohio-specific regulatory precision.

## Sources

### Primary (HIGH confidence)
- `reference/openclaw-docs/tools/subagents.md` — sessions_spawn, maxSpawnDepth, announce protocol, sub-agent context injection limits
- `reference/openclaw-docs/concepts/multi-agent.md` — agent isolation, agentDir, bindings, tool scoping, model config
- `reference/openclaw-docs/tools/multi-agent-sandbox-tools.md` — per-agent tool allow/deny, tool groups, filtering precedence
- `reference/openclaw-docs/concepts/agent-workspace.md` — workspace layout, AGENTS.md injection scope, what sub-agents receive
- `reference/openclaw-docs/concepts/agent.md` — bootstrap file injection, sub-agent context limitations
- `reference/openclaw-docs/concepts/architecture.md` — gateway architecture, WebSocket, session flow
- Live fetch: `https://docs.openclaw.ai/install/hetzner.md` — Docker Compose deployment, VPS setup
- Live fetch: `https://docs.openclaw.ai/providers/anthropic.md` — API key setup, model IDs, prompt caching
- `reference/hackathon-challenge.md` — challenge requirements, judging criteria, secret addition timing
- NAIC Claims Settlement Provisions Chart (Spring 2024) — state-by-state FCSP timelines
- California FCSP Regulations (CCR Title 10, Sections 2695.1-2695.14) — 40-day decision, 30-day payment timelines

### Secondary (MEDIUM confidence)
- Aviva Canada 2024 Fraud Prevention Report — staged accident 47% increase, fraud pattern descriptions
- NICB (National Insurance Crime Bureau) — staged auto accident fraud patterns
- Total Loss Appraisals — state-by-state total loss threshold chart, OEM vs. aftermarket analysis
- MWL Law — automobile total loss thresholds by state (Ohio 100% rule confirmed)
- Coalition Against Insurance Fraud / Roundtables.us — $308.6B annual fraud cost figure

### Tertiary (referenced for Q&A preparation)
- Appraisal Engine — diminished value 17c formula explanation
- Investopedia — FNOL process overview
- Justia — bad faith insurance law overview
- MAST (Multi-Agent System Failure Taxonomy), ICLR 2025 Workshop — multi-agent LLM failure modes
- mathco.com — hardcoded rules vs. policy reasoning distinction in insurance AI

---
*Research completed: 2026-02-17*
*Ready for roadmap: yes*
