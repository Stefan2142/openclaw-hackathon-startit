---
phase: 01-domain-knowledge
plan: 03
subsystem: domain-knowledge
tags: [insurance, regulatory-compliance, fcsp, bad-faith, payment, subrogation, depreciation, edge-cases, total-loss, diminished-value, um-uim]

# Dependency graph
requires:
  - phase: none
    provides: first domain knowledge plan (independent)
provides:
  - Regulatory compliance reference (FCSP timelines, documentation retention, bad faith triggers)
  - Payment/subrogation knowledge base (payout calculation, subrogation workflow, rental rules, ACV/depreciation)
  - Edge case catalog with Q&A-ready answers for 10 categories
affects: [03-agent-specifications, phase-3-senior-reviewer-agent, phase-3-finance-agent, phase-3-claims-officer-agent, phase-4-qa-defense]

# Tech tracking
tech-stack:
  added: []
  patterns: [reasoning-frameworks-not-rules, no-hardcoded-thresholds, qa-ready-one-sentence-answers]

key-files:
  created:
    - reference/domain-knowledge/regulatory-compliance.md
    - reference/domain-knowledge/payment-subrogation.md
    - reference/domain-knowledge/edge-cases.md
  modified: []

key-decisions:
  - "FCSP timelines expressed as reasoning frameworks with jurisdiction awareness, not hardcoded timers"
  - "ACV/depreciation documented as professional judgment based on market data, not a fixed formula"
  - "Edge cases structured as Q&A defense document with one-sentence prepared answers per category"
  - "Ohio framed via NAIC model act standards rather than claiming Ohio-specific regulatory precision"

patterns-established:
  - "Q&A defense format: each edge case has what-it-is, judge-motivation, system-handling, one-sentence-answer"
  - "Regulatory compliance as structural safeguard: system architecture prevents bad faith through audit trails and escalation, not just rules"
  - "Cross-document dependency: regulatory timelines create bad faith exposure when edge cases cause delays"

requirements-completed: [DOMAIN-05, DOMAIN-06, DOMAIN-07]

# Metrics
duration: 5min
completed: 2026-02-17
---

# Phase 1 Plan 3: Regulatory Compliance + Payment/Subrogation + Edge Cases Summary

**FCSP timeline tracking (10-15/40/30-day windows), subrogation workflow with deductible recovery, and 10-category edge case catalog with 17c diminished value formula and Q&A-ready one-sentence answers**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-17T19:47:43Z
- **Completed:** 2026-02-17T19:52:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Regulatory compliance reference covering three FCSP timelines (10-15 day acknowledgment, 40-day decision, 30-day payment), 5-year documentation retention, and 8 bad faith exposure triggers with system prevention mechanisms
- Payment/subrogation knowledge base covering 4 payout calculation methods (standard, ACV, RCV, total loss), complete subrogation workflow with 6-step recovery process, rental reimbursement rules, and ACV/depreciation reasoning principles
- Comprehensive edge case catalog with 10 categories, each structured as Q&A defense with prepared one-sentence answers the team can deliver during judging
- 17c diminished value formula fully documented with damage and mileage modifier tables

## Task Commits

Each task was committed atomically:

1. **Task 1: Create regulatory compliance reference and payment/subrogation knowledge base** - `0e56668` (feat)
2. **Task 2: Create comprehensive edge case catalog** - `8c0ed52` (feat)

## Files Created/Modified
- `reference/domain-knowledge/regulatory-compliance.md` - FCSP Act timelines (acknowledgment, decision, payment), documentation retention requirements, 8 bad faith exposure triggers, regulatory compliance reasoning framework, Q&A defense points
- `reference/domain-knowledge/payment-subrogation.md` - Payment calculation (standard, ACV, RCV, total loss), subrogation workflow (trigger, lien, demand, recovery, deductible return), rental reimbursement rules, ACV/depreciation principles
- `reference/domain-knowledge/edge-cases.md` - 10 edge case categories (total loss, pre-existing damage, diminished value 17c, UM/UIM, supplements, CAT events, denial bad faith, legal representation, multi-vehicle, endorsements), cross-cutting patterns, team readiness test

## Decisions Made
- FCSP timelines expressed as regulatory windows with jurisdiction awareness rather than hardcoded timers -- "acknowledge within the regulatory window for the relevant jurisdiction" instead of "set timer to 15 days"
- ACV/depreciation documented as professional judgment based on market comparables (KBB, NADA, local dealer pricing), not a fixed percentage formula -- directly supports the hackathon's "no hardcoded thinking" requirement
- Ohio regulatory answers framed around NAIC model act standards since Ohio follows NAIC, rather than claiming Ohio-specific DOI filing precision -- more defensible in Q&A
- Edge case catalog structured for Q&A defense with one-sentence prepared answers so team members can respond immediately during judging without looking anything up

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All three documents ready for embedding into AGENTS.md templates in Phase 3:
  - Regulatory compliance feeds into Senior Reviewer (FCSP timeline compliance checks) and Claims Officer (coverage decision timeline awareness)
  - Payment/subrogation feeds into Finance agent (payout calculation, subrogation flagging) and Assessor (ACV/depreciation reasoning)
  - Edge case catalog feeds into all agent AGENTS.md templates as situational awareness and Q&A defense preparation
- Complete domain knowledge base now spans 6 documents across plans 01-01, 01-02, and 01-03
- Phase 1 success criteria can now be evaluated: team should be able to state FCSP timelines, explain subrogation, cite 17c formula, and handle any edge case scenario from memory

---
*Phase: 01-domain-knowledge*
*Completed: 2026-02-17*
