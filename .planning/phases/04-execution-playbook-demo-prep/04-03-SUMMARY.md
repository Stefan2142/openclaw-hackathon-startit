---
phase: 04-execution-playbook-demo-prep
plan: 03
subsystem: docs
tags: [presentation, demo, walkthrough, script, narration, hackathon]

# Dependency graph
requires:
  - phase: 03-agent-specifications-test-scenarios
    provides: "Test claim JSON files (happy-path, fraud, denial) and agent documentation"
  - phase: 02-architecture-design
    provides: "Architecture docs, decision log, OpenClaw tools doc, scripts"
provides:
  - "Complete 5-minute presentation script with second-level timing marks"
  - "Three end-to-end demo claim walkthroughs with presenter narration and expected output"
  - "Demo failure fallback instructions"
affects: [04-04-backup-captures]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Timed presentation script with [ACTION] markers and spoken text"
    - "Stage-by-stage walkthrough with expected JSON output and audit log entries"

key-files:
  created:
    - docs/presentation-script.md
    - docs/demo-walkthroughs.md
  modified: []

key-decisions:
  - "Presentation script uses verbatim spoken sentences, not bullet points -- ensures consistent delivery"
  - "Walkthroughs include full JSON output blocks for each pipeline stage for backup reference"
  - "Fraud walkthrough builds tension through sequential pattern reveals"

patterns-established:
  - "Demo narration style: present tense, highlight surprising moments, connect to business value"
  - "Walkthrough structure: claim summary, per-stage narration + output + audit log, business outcome"

requirements-completed: [DEMO-01, DEMO-02]

# Metrics
duration: 5min
completed: 2026-02-18
---

# Phase 4 Plan 03: Presentation Script & Demo Walkthroughs Summary

**5-minute timed presentation script with 3 end-to-end demo walkthroughs covering happy path (subrogation), fraud (SIU referral), and coverage denial (excluded driver shortcut)**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-18T10:31:05Z
- **Completed:** 2026-02-18T10:35:57Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Complete 5-minute presentation script with second-level timing marks (0:00 through 5:00), 13 [ACTION] markers, and spoken text for verbatim delivery
- Three end-to-end demo walkthroughs with presenter narration, expected pipeline JSON output, audit log entries, and business outcome for each claim scenario
- Demo failure fallback instructions with recovery lines for seamless transition to walkthrough docs
- Presenter narration style guide with emphasis points per walkthrough scenario

## Task Commits

Each task was committed atomically:

1. **Task 1: Create 5-minute presentation script** - `d0489f0` (feat)
2. **Task 2: Create three demo claim walkthroughs** - `5459a78` (feat)

## Files Created/Modified

- `docs/presentation-script.md` - Complete 5-minute presentation script with timing marks, spoken text, [ACTION] markers, [IF DEMO FAILS] fallback, and pacing tips
- `docs/demo-walkthroughs.md` - Three end-to-end demo walkthroughs (CLM-2026-00001 happy path, CLM-2026-00002 fraud/SIU, CLM-2026-00003 denial/exclusion) with narration, expected JSON output, audit logs, and business outcomes

## Decisions Made

- Presentation script uses verbatim spoken sentences (not bullet points) so the presenter can read it aloud naturally without improvising
- Each walkthrough includes full expected JSON output blocks (not abbreviated) to serve as backup reference if the live demo fails
- Fraud walkthrough narration builds tension by revealing patterns sequentially (phantom passengers, staged accident, prior history, attorney representation) before explaining indicator convergence
- Coverage denial walkthrough explicitly marks skipped stages (Assessor, Fraud Analyst, Finance) to demonstrate the pipeline shortcut

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Presentation script ready for rehearsal
- Demo walkthroughs ready for backup capture (04-04 plan)
- Presentation script references backup captures from 04-04 in its [IF DEMO FAILS] section
- All three test claim scenarios have matching walkthrough narration

---
*Phase: 04-execution-playbook-demo-prep*
*Completed: 2026-02-18*
