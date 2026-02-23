---
phase: 03-agent-specifications-test-scenarios
plan: 02
subsystem: agents
tags: [assessor, fraud-analyst, damage-estimation, fraud-detection, agents-md, ohio-acv, reasoning-frameworks]

# Dependency graph
requires:
  - phase: 01-domain-knowledge-research
    provides: "Domain knowledge for damage assessment and fraud detection embedded in AGENTS.md"
  - phase: 02-architecture-design-infrastructure
    provides: "claim.schema.json field names, handoff protocol announce format, workspace structure"
provides:
  - "Assessor AGENTS.md with complete damage estimation reasoning framework"
  - "Fraud Analyst AGENTS.md with all 7 named fraud patterns and convergence scoring"
affects: [03-agent-specifications-test-scenarios, 04-integration-testing-demo-preparation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Self-contained AGENTS.md with embedded domain knowledge (no external references)"
    - "Reasoning frameworks instead of hardcoded thresholds for all agent decisions"
    - "Indicator convergence scoring for fraud risk (not probability-based)"

key-files:
  created:
    - "workspaces/assessor/AGENTS.md"
    - "workspaces/fraud-analyst/AGENTS.md"
  modified: []

key-decisions:
  - "Photo analysis framed as description-based reasoning, not ML inference -- consistent with blocker in STATE.md"
  - "All 7 fraud patterns embedded with full indicator lists and cross-references"
  - "Pattern interaction map included showing how fraud patterns combine"
  - "Fraud scoring explicitly documented as convergence strength, not probability"
  - "Anti-pattern warnings embedded as operating constraints in Fraud Analyst"

patterns-established:
  - "AGENTS.md structure: Role > Protocol > Domain Frameworks > Output Format > Audit Log > Announce > Escalation"
  - "Cross-agent references via schema field names (e.g., Fraud Analyst reads pipeline.assessor.pre_existing_damage_flags)"

requirements-completed: [AGENT-03, AGENT-04]

# Metrics
duration: 6min
completed: 2026-02-18
---

# Phase 3 Plan 02: Assessor and Fraud Analyst AGENTS.md Summary

**Self-contained Assessor and Fraud Analyst operating instructions with Ohio 100% ACV total loss rule, OEM vs aftermarket framework, all 7 named fraud patterns, and convergence-based fraud scoring -- zero hardcoded thresholds**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-18T08:31:03Z
- **Completed:** 2026-02-18T08:37:04Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- Assessor AGENTS.md with complete damage estimation methodology, Ohio 100% ACV total loss rule, OEM vs aftermarket parts framework, rental day estimation, pre-existing damage detection, and hidden damage assessment
- Fraud Analyst AGENTS.md with all 7 named fraud patterns (staged accident, phantom passengers, paper accident, inflated repair, prior damage/VIN switching, owner give-up, organized ring), soft vs hard fraud distinction, convergence scoring framework, SIU referral criteria, and anti-pattern warnings
- Both files are fully self-contained with embedded domain knowledge, exact claim.schema.json field names, and reasoning frameworks only

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Assessor AGENTS.md** - `8834b86` (feat)
2. **Task 2: Create Fraud Analyst AGENTS.md** - `d2917b2` (feat)

## Files Created/Modified
- `workspaces/assessor/AGENTS.md` - Complete Assessor agent operating instructions (347 lines): damage estimation, Ohio total loss, OEM/aftermarket, rental days, pre-existing damage, hidden damage
- `workspaces/fraud-analyst/AGENTS.md` - Complete Fraud Analyst agent operating instructions (364 lines): 7 fraud patterns, soft/hard distinction, convergence scoring, SIU criteria, anti-patterns

## Decisions Made
- Photo analysis framed as description-based reasoning, not ML inference -- consistent with the blocker noted in STATE.md about photo/image handling by Assessor
- All 7 fraud patterns embedded with complete indicator lists, not summarized -- the Fraud Analyst needs full context to reason about each pattern
- Pattern interaction map included to show how fraud schemes combine (staged + phantom, inflated + prior damage, etc.)
- Fraud Analyst anti-pattern warnings embedded as operating constraints, not just documentation -- they are part of the agent's instructions
- Cross-reference between Assessor and Fraud Analyst via schema fields: Fraud Analyst explicitly reads `pipeline.assessor.pre_existing_damage_flags` and `pipeline.assessor.repair_estimate_usd`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Assessor and Fraud Analyst AGENTS.md files are complete and ready for deployment
- Workspace directories created at workspaces/assessor/ and workspaces/fraud-analyst/
- Remaining AGENTS.md files needed: Router (03-03), Front Desk + Claims Officer (03-01), Senior Reviewer + Finance (03-03)
- Test claim scenarios (03-04) can reference these agent specifications for expected behavior

---
*Phase: 03-agent-specifications-test-scenarios*
*Completed: 2026-02-18*
