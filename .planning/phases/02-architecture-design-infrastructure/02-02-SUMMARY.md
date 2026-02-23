---
phase: 02-architecture-design-infrastructure
plan: 02
subsystem: architecture
tags: [router, orchestration, state-machine, workspace, policy-mock, shared-state, agent-design]

# Dependency graph
requires:
  - phase: 01-domain-knowledge
    provides: "Insurance domain knowledge informing router context enrichment, policy mock data, and agent workspace scoping"
  - phase: 02-architecture-design-infrastructure
    plan: 01
    provides: "openclaw.json agent config (workspace paths, tool scoping) and claim.schema.json (status states, pipeline sections)"
provides:
  - "architecture/router-design.md: Complete router orchestration spec with state machine, spawn patterns, error handling, and context enrichment"
  - "architecture/workspace-structure.md: All 7 agent workspace layouts with tool scoping rationale and AGENTS.md content scope"
  - "architecture/shared-state.md: Shared filesystem layout, path conventions, concurrency model, and policy database design"
  - "shared/policies/*.json: 5 mock policy records covering active, lapsed, excluded driver, high deductible, and comprehensive-only scenarios"
affects: [02-03, 02-04, 02-05, 03-01, 03-02, 03-03, 03-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [announce-wait-read-spawn, router-as-state-machine, absolute-path-convention, single-writer-per-claim]

key-files:
  created:
    - architecture/router-design.md
    - architecture/workspace-structure.md
    - architecture/shared-state.md
    - shared/policies/POL-AUT-10001.json
    - shared/policies/POL-AUT-10002.json
    - shared/policies/POL-AUT-10003.json
    - shared/policies/POL-AUT-10004.json
    - shared/policies/POL-AUT-10005.json
  modified: []

key-decisions:
  - "Router constructs all absolute paths -- pipeline agents never build paths themselves"
  - "No SOUL.md in any workspace: sub-agents only receive AGENTS.md + TOOLS.md, so all instructions go in AGENTS.md"
  - "Sequential pipeline guarantees single-writer-per-claim, eliminating need for file locking"
  - "Router enriches task messages with regulatory context and prior-stage results per stage"
  - "Per-stage timeouts: front-desk 60s, claims-officer 90s, assessor 120s, fraud-analyst 90s, senior-reviewer 90s, finance 60s"
  - "Max 2 retries per stage, then ERROR status with audit log entry"
  - "Early termination: if claims-officer finds covered=false, pipeline stops at DENIED (no assessor/fraud stages)"

patterns-established:
  - "Announce-wait-read-spawn: Router writes audit log, spawns agent, waits for announce, reads claim, validates, decides, spawns next"
  - "Task message template: claim file path + additional file references + stage-specific context + regulatory context + instructions"
  - "Policy file path convention: shared/policies/POL-AUT-{NNNNN}.json"
  - "Mock policy scenarios: 5 distinct policies covering all demo edge cases (active/lapsed/excluded/high-deductible/comp-only)"

requirements-completed: [ARCH-03, ARCH-04, ARCH-05]

# Metrics
duration: 6min
completed: 2026-02-17
---

# Phase 2 Plan 2: Router Design + Workspace Structure + Shared State Summary

**Router state machine with 9 statuses and announce-wait-read-spawn cycle, 7 agent workspace specs with tool scoping, and shared filesystem with 5 mock policy records for demo scenarios**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-17T20:39:31Z
- **Completed:** 2026-02-17T20:45:36Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Complete router orchestration design: 9-state machine, sequential spawn pattern, per-stage task message templates, error handling with 2-retry policy, and regulatory context enrichment
- All 7 agent workspaces fully specified with tool scoping rationale, read/write access patterns, and AGENTS.md content scope for Phase 3
- Shared state architecture with directory layout, absolute path conventions, and single-writer concurrency model
- 5 mock policy JSON files ready for hackathon demo: standard active, lapsed, excluded driver, high deductible, comprehensive-only
- SOUL.md exclusion documented and justified (sub-agents only receive AGENTS.md + TOOLS.md)

## Task Commits

Each task was committed atomically:

1. **Task 1: Router orchestration design + workspace structure** - `e18f6ef` (feat)
2. **Task 2: Shared state architecture + mock policy database** - `2099526` (feat)

## Files Created/Modified
- `architecture/router-design.md` - Complete router orchestration spec: state machine, spawn patterns, task message templates, error handling, context enrichment
- `architecture/workspace-structure.md` - All 7 agent workspace layouts with tool scoping, read/write access, and AGENTS.md content scope
- `architecture/shared-state.md` - Shared filesystem layout, path conventions, concurrency model, mock policy database design
- `shared/policies/POL-AUT-10001.json` - Standard active policy: collision+comp+liability, $500/$250 deductible, John Smith
- `shared/policies/POL-AUT-10002.json` - Lapsed policy: expired 2025-12-01, Jane Doe
- `shared/policies/POL-AUT-10003.json` - Excluded driver: Michael Johnson excluded, Robert Wilson
- `shared/policies/POL-AUT-10004.json` - High deductible: $2K collision, $1K comp, Sarah Brown
- `shared/policies/POL-AUT-10005.json` - Comprehensive-only: no collision coverage, David Lee

## Decisions Made
- **Router constructs all paths:** Pipeline agents receive absolute paths in task messages. No agent constructs its own path to shared/ files. This eliminates workspace-relative path bugs.
- **No SOUL.md anywhere:** Even the Router (depth-0) uses AGENTS.md only for consistency. Sub-agents never see SOUL.md, so putting instructions there is a documented pitfall.
- **Early termination on denial:** If claims-officer finds covered=false, the Router skips assessor, fraud-analyst, senior-reviewer, and finance stages. Sets DENIED immediately. This saves tokens and reflects real insurance workflow.
- **Per-stage timeouts based on complexity:** Assessor gets 120s (most complex reasoning), front-desk and finance get 60s (structured operations). Timeouts documented per stage.
- **Policy files as static data:** Mock policies are read-only during claim processing. Only Claims Officer reads them, via path injected by Router.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Router design spec ready for Phase 3 (Router AGENTS.md will implement the state machine and spawn patterns from this document)
- Workspace structure spec ready for Phase 3 (each agent's AGENTS.md content scope is defined)
- Shared state architecture ready for 02-03 (hand-off protocol builds on path conventions and validation patterns)
- Mock policies ready for Phase 3 test scenarios (claims can reference these 5 policy IDs)
- All architecture/ documents ready for 02-05 (architecture documentation plan)
- No blockers identified

---
*Phase: 02-architecture-design-infrastructure*
*Completed: 2026-02-17*
