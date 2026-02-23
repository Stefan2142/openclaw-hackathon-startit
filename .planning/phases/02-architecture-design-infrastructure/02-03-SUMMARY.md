---
phase: 02-architecture-design-infrastructure
plan: 03
subsystem: architecture
tags: [handoff-protocol, human-in-the-loop, escalation, pipeline-transitions, FCSP, fraud-escalation, audit-trail]

# Dependency graph
requires:
  - phase: 02-architecture-design-infrastructure
    plan: 01
    provides: "claim.schema.json defining all pipeline section fields that hand-off protocol references; openclaw.json with agent IDs used in transition specs"
provides:
  - "architecture/handoff-protocol.md: Complete agent-to-agent hand-off specification for all 6 pipeline transitions with pre/post conditions, error paths, and audit log entries"
  - "architecture/human-in-the-loop.md: Escalation trigger catalog (7 triggers as reasoning principles), structured escalation output format, pipeline pause/resume mechanism, human resolution path, FCSP timeline compliance"
affects: [02-05, 03-01, 03-02, 03-03, 03-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [router-mediated-handoff, announce-validate-spawn-cycle, flag-and-escalate-not-detect-and-deny, reasoning-principles-over-thresholds]

key-files:
  created:
    - architecture/handoff-protocol.md
    - architecture/human-in-the-loop.md
  modified: []

key-decisions:
  - "Pipeline agents do not set top-level claim status directly -- Router owns all status transitions after validating agent output"
  - "Coverage denial shortcut: denied claims skip Assessor/Fraud/Finance, go directly to Senior Reviewer for denial documentation and bad faith risk review"
  - "Escalation record written by Router (not pipeline agent) to include full pipeline context the individual agent lacks"
  - "Escalation triggers expressed as reasoning principles, not numerical thresholds -- directly supports hackathon judging criteria"
  - "Four human resolution types: approve, deny, modify, investigate -- covering all possible human responses to escalation"
  - "FCSP timeline continues running during escalation -- urgency levels (normal/elevated/critical) are reasoning-based, not day-count thresholds"

patterns-established:
  - "Announce format: Status (SUCCESS/ERROR/ESCALATE) + Summary + Key findings + Next recommended action"
  - "Post-condition validation: Router checks completed_at, required fields, and data consistency before spawning next agent"
  - "Retry protocol: max 2 attempts per stage, immediate re-spawn, escalate on repeated failure"
  - "Timeout per agent: 60-120s based on task complexity (front-desk 60s, assessor 120s)"
  - "Audit log entry pattern: every agent appends timestamp + agent + action + reasoning + optional regulation_reference"
  - "Escalation output includes both key_findings and mitigating_factors for balanced human review"

requirements-completed: [ARCH-06, ARCH-07]

# Metrics
duration: 6min
completed: 2026-02-17
---

# Phase 2 Plan 3: Hand-off Protocol + HITL Escalation Design Summary

**Complete 6-transition hand-off protocol with Router validation cycle, coverage denial shortcut, and 7-trigger escalation system using reasoning principles with structured pause/resume and FCSP timeline tracking**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-17T20:39:27Z
- **Completed:** 2026-02-17T20:45:42Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Complete hand-off protocol documenting all 6 pipeline transitions with exact reads, writes, status changes, pre/post-condition validation, error paths, and audit log entry formats
- Coverage denial shortcut path documented: denied claims skip Assessor, Fraud Analyst, and Finance, going directly to Senior Reviewer for denial review
- 7-trigger escalation catalog expressed entirely as reasoning principles with no hardcoded numerical thresholds
- Structured escalation output format including key findings, mitigating factors, recommended actions, and regulatory timeline context
- Pipeline pause/resume mechanism with 4 human resolution types (approve, deny, modify, investigate)
- FCSP timeline compliance during escalation with urgency assessment

## Task Commits

Each task was committed atomically:

1. **Task 1: Create hand-off protocol specification** - `dfb7a7c` (feat)
2. **Task 2: Create human-in-the-loop escalation design** - `a49722a` (feat)

## Files Created/Modified
- `architecture/handoff-protocol.md` - Complete agent-to-agent transition specification for all 6 pipeline transitions, including announce format, Router validation cycle, retry/timeout protocols, and the coverage denial shortcut path
- `architecture/human-in-the-loop.md` - Escalation trigger catalog (7 triggers), structured escalation output format, pipeline pause/resume mechanism, human resolution path, FCSP timeline compliance, and demo scenario script

## Decisions Made
- **Router owns status transitions:** Pipeline agents write their section data but do not directly change the top-level status. Router validates and then updates status. This prevents inconsistent state from partial agent failures.
- **Coverage denial shortcut:** Denied claims skip Assessor, Fraud Analyst, and Finance stages but still go through Senior Reviewer for denial documentation and bad faith risk assessment. This reflects real insurance operations.
- **Escalation record written by Router:** The Router constructs the escalation record (not the pipeline agent) because the Router has full pipeline context including time_in_pipeline, regulatory deadlines, and stages_remaining that individual agents lack.
- **Reasoning principles for all triggers:** Every escalation trigger is expressed as a judgment principle, not a threshold. "Significant claim value" instead of "> $25,000". This directly supports the hackathon requirement and enables secret addition adaptability.
- **Four resolution types:** approve/deny/modify/investigate covers all human response patterns. "Investigate" keeps the claim in ESCALATED status, acknowledging that not all escalations resolve quickly.
- **FCSP urgency is reasoning-based:** Urgency levels (normal/elevated/critical) are assessed by the agent's reasoning about proximity to deadlines, not by comparing day counts against hardcoded thresholds.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Hand-off protocol provides the exact task message templates that AGENTS.md files will reference in Phase 3
- Escalation triggers provide the reasoning principles that Fraud Analyst and Senior Reviewer AGENTS.md templates will embed
- Coverage denial shortcut path informs Router AGENTS.md state machine logic
- Both documents are ready for architecture documentation compilation in 02-05
- No blockers identified

---
*Phase: 02-architecture-design-infrastructure*
*Completed: 2026-02-17*
