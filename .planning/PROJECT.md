# Ohio Mutual Auto — Multi-Agent Claims Processing System

## What This Is

A multi-agent claims processing system for the OpenClaw Business Engineering Hackathon (Feb 21, Belgrade). Seven specialized agents (1 orchestrator + 6 pipeline) process auto insurance claims end-to-end — from first notice of loss through payment — using OpenClaw's multi-agent architecture with Claude as the underlying LLM. All preparation artifacts (domain knowledge, architecture, agent templates, execution playbook) are complete. The team walks into Feb 21 ready to compose, not invent.

## Core Value

Every claims decision must be auditable, regulation-compliant, and defensible — the system should demonstrate that AI agents can process insurance claims with the same rigor and accountability as human adjusters, while being transparent about every decision point.

## Requirements

### Validated

- ✓ Complete FNOL lifecycle, coverage verification, damage assessment, fraud detection, regulatory compliance, payment/subrogation, and edge case knowledge — v1.0
- ✓ OpenClaw configuration with 7 agents, claim schema (9-state machine), tool scoping, model tiering — v1.0
- ✓ Router orchestrator design with sequential pipeline, error handling, retry policy — v1.0
- ✓ Agent workspace structure with AGENTS.md-only instructions (no SOUL.md) — v1.0
- ✓ Shared state architecture with JSON files, 5 mock policies, claim schema — v1.0
- ✓ Hand-off protocol and human-in-the-loop escalation design — v1.0
- ✓ 7 AGENTS.md reasoning framework templates (2,747 lines) with embedded domain knowledge — v1.0
- ✓ VPS setup script, demo scripts (submit/check/run), 3 test claim scenarios — v1.0
- ✓ Day-of timeline, team work split, integration checkpoints, secret addition framework — v1.0
- ✓ 5-minute presentation script, demo walkthroughs, Q&A defense (24 answers), backup outputs — v1.0
- ✓ Architecture documentation, decision log (15 decisions), OpenClaw tools documentation — v1.0
- ✓ Agent documentation with real insurance parallels — v1.0

### Active

(None — all v1 preparation requirements shipped. Next work is the hackathon build on Feb 21.)

### Out of Scope

- Production-grade scaling — hackathon demo, not production
- Real payment processing — mock payment execution only
- Real policy database — mock policies with representative data
- Mobile/web UI — CLI/script-driven demo
- Multi-state regulatory variations — Ohio-only via NAIC model act
- Real photo AI / computer vision — description-based reasoning instead
- Hardcoded decision rules — disqualifier per challenge brief

## Context

**Current State:** v1.0 Hackathon Prep complete. 201 files, 106K lines across 4 phases (16 plans, 84 min total execution). All artifacts ready for Feb 21 build day.

**Architecture (decided):**
- 7 agents: Router (Opus), Front Desk (Sonnet), Claims Officer (Sonnet), Assessor (Opus), Fraud Analyst (Opus), Senior Reviewer (Opus), Finance (Sonnet)
- Sequential pipeline via sessions_spawn, maxSpawnDepth=1
- JSON files for claim state (not database) — zero setup, demo-readable
- AGENTS.md only (SOUL.md invisible to sub-agents)
- Reasoning frameworks only (no numerical thresholds)

**Key Artifacts:**
- `openclaw.json` — 7 agents configured
- `shared/schemas/claim.schema.json` — 515 lines, 88 fields, 9-state machine
- `workspaces/*/AGENTS.md` — 7 reasoning framework templates
- `shared/test-claims/` — 3 scenarios (happy path, fraud, denial)
- `docs/` — architecture, decision log, presentation script, Q&A defense, backup outputs
- `scripts/` — setup.sh, submit-claim.sh, check-status.sh, run-demo.sh

## Constraints

- **Timeline**: 10-hour build on Feb 21 (10:00-20:00)
- **Platform**: OpenClaw multi-agent framework
- **LLM**: Claude (Anthropic) via OpenClaw
- **Deployment**: Linux VPS (Ubuntu/Debian) — one-touch setup.sh
- **Hackathon Rules**: No pre-built code or text — knowledge and understanding only
- **Judging**: 50/50 business thinking vs system thinking
- **Flexibility**: Must accommodate unknown "secret addition"

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| JSON files (not database) | Zero setup, human-readable, audit-friendly, single-writer guarantee | ✓ Good |
| maxSpawnDepth=1 | Router depth-0, pipeline depth-1 leaves — simplest correct model | ✓ Good |
| AGENTS.md only (no SOUL.md) | Sub-agents never see SOUL.md — OpenClaw architectural constraint | ✓ Good |
| Reasoning frameworks (no thresholds) | Challenge disqualifies hardcoded rules; reasoning is more adaptable | ✓ Good |
| Sequential pipeline (not parallel) | Correctness requires it — fraud needs damage estimate, review needs fraud score | ✓ Good |
| Opus for reasoning agents, Sonnet for deterministic | Cost optimization without quality sacrifice on complex decisions | ✓ Good |
| Router owns all status transitions | Pipeline agents write sections; Router validates and transitions — single authority | ✓ Good |
| Coverage denial shortcut | Denied claims skip Assessor/Fraud/Finance, go to Senior Reviewer for bad faith review | ✓ Good |
| Indicator convergence (not numerical scoring) | Single flag = note, converging = investigate, pattern match = SIU referral | ✓ Good |
| agentToAgent disabled | All communication through claim JSON + router mediation — simpler, auditable | ✓ Good |
| Docker Compose inline in setup.sh | Day-of flexibility for image name/tag changes | ✓ Good |
| Gateway localhost only (127.0.0.1:18789) | SSH tunnel for remote access — security first | ✓ Good |
| Per-stage timeouts (60-120s) | Prevents hanging; max 2 retries then ERROR | ✓ Good |
| Ambiguity doctrine in Claims Officer | Policy ambiguities construed against insurer — legal standard | ✓ Good |
| Senior Reviewer as sole decision authority | 4 outcomes only: APPROVE/DENY/CONDITIONAL/ESCALATE_HUMAN | ✓ Good |

---
*Last updated: 2026-02-18 after v1.0 milestone*
