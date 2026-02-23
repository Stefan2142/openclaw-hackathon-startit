---
phase: 02-architecture-design-infrastructure
plan: 01
subsystem: infra
tags: [openclaw, json-schema, multi-agent, claude, configuration]

# Dependency graph
requires:
  - phase: 01-domain-knowledge
    provides: "Insurance domain knowledge (FNOL lifecycle, fraud patterns, compliance, payment/subrogation) that informed schema field design"
provides:
  - "openclaw.json: Complete OpenClaw gateway configuration for all 7 agents with model assignments, tool scoping, and workspace paths"
  - "claim.schema.json: JSON Schema contract defining every field every agent reads and writes, including 9-state status machine and audit log format"
affects: [02-02, 02-03, 02-04, 02-05, 03-01, 03-02, 03-03, 03-04]

# Tech tracking
tech-stack:
  added: [openclaw-gateway, json-schema-draft-07]
  patterns: [sequential-pipeline-orchestration, claim-file-as-integration-contract, least-privilege-tool-scoping]

key-files:
  created:
    - openclaw.json
    - shared/schemas/claim.schema.json
  modified: []

key-decisions:
  - "maxSpawnDepth resolved to 1 (not 2): Router is depth-0 main agent, pipeline agents are depth-1 leaves. No nesting needed."
  - "Router allowAgents explicitly lists all 6 pipeline agent IDs for sessions_spawn targeting"
  - "Prompt caching enabled via cacheRetention: short on both Opus and Sonnet model configs"
  - "agentToAgent disabled: all inter-agent communication through claim JSON file + router mediation"
  - "risk_score defined as integer 0-100 representing indicator convergence, not probability"
  - "Fraud flags structured as objects with pattern/description/severity for machine-readable analysis"

patterns-established:
  - "Agent workspace paths: ./workspaces/{agent-id}/ convention"
  - "Claim ID format: CLM-YYYY-NNNNN (regex-validated in schema)"
  - "Pipeline section naming: snake_case agent IDs matching OpenClaw agent IDs (front_desk, claims_officer, etc.)"
  - "Every pipeline section includes completed_at and agent_session for traceability"
  - "Audit log entries require timestamp, agent, action, reasoning (regulation_reference optional)"

requirements-completed: [ARCH-01, ARCH-02]

# Metrics
duration: 4min
completed: 2026-02-17
---

# Phase 2 Plan 1: OpenClaw Configuration + Claim Schema Summary

**Complete OpenClaw gateway config (7 agents, Opus/Sonnet model tiers, least-privilege tools) and JSON Schema contract (88 documented fields, 9-state machine, 6 pipeline sections)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-17T20:33:02Z
- **Completed:** 2026-02-17T20:36:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Complete openclaw.json with all 7 agents registered, correct model assignments, tool scoping, and maxSpawnDepth resolved to 1
- Complete claim.schema.json defining every pipeline section, all 9 status states, audit log format, and 6 incident types
- Resolved maxSpawnDepth discrepancy (STACK.md recommended 2, ARCHITECTURE.md recommended 1) in favor of 1 -- Router at depth 0 always has sessions_spawn, pipeline agents are depth-1 leaves that don't need it
- Router configured with allowAgents listing all 6 pipeline agent IDs for cross-agent spawning

## Task Commits

Each task was committed atomically:

1. **Task 1: Create OpenClaw configuration spec** - `dcae891` (feat)
2. **Task 2: Create claim state JSON schema** - `f7f0930` (feat)

## Files Created/Modified
- `openclaw.json` - Complete OpenClaw gateway configuration with all 7 agents, model assignments, tool scoping, subagent config, and agent-to-agent settings
- `shared/schemas/claim.schema.json` - JSON Schema (draft-07) defining the claim state contract between all agents: root fields, claimant, incident, 6 pipeline sections, and audit log

## Decisions Made
- **maxSpawnDepth = 1:** The Router is the main agent at depth 0 (always has sessions_spawn). Pipeline agents are depth-1 sub-agents that don't need to spawn further. Setting maxSpawnDepth to 2 would unnecessarily grant session tools to depth-1 agents.
- **Router allowAgents explicit list:** Rather than using `["*"]`, the Router's allowAgents lists exactly the 6 pipeline agent IDs. This is least-privilege and documents the valid spawn targets.
- **cacheRetention: short on both models:** While this is already the default for Anthropic API key auth, making it explicit in the config ensures it's not accidentally overridden and documents the decision.
- **risk_score as integer 0-100:** Defined as integer (not float) with min/max constraints. Represents indicator convergence strength, not mathematical probability, consistent with the "no hardcoded thresholds" principle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Router subagents.allowAgents configuration**
- **Found during:** Task 1 (OpenClaw configuration)
- **Issue:** Plan specified Router should spawn pipeline agents but did not mention allowAgents. OpenClaw docs confirm that by default, sessions_spawn can only target the same agent ID -- the Router cannot spawn different agent IDs without explicit allowAgents config.
- **Fix:** Added `subagents.allowAgents` to Router config listing all 6 pipeline agent IDs
- **Files modified:** openclaw.json
- **Verification:** Config includes allowAgents with all 6 pipeline agent IDs
- **Committed in:** dcae891 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for correct operation -- without allowAgents, the Router could not spawn any pipeline agents. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Both foundational artifacts are ready for all remaining Phase 2 plans (02-02 through 02-05)
- Agent workspace paths (./workspaces/{agent-id}/) established for Phase 2 Plan 02 (workspace structure)
- Claim schema field names locked for Phase 3 (AGENTS.md templates will reference these exact fields)
- No blockers identified

---
*Phase: 02-architecture-design-infrastructure*
*Completed: 2026-02-17*
