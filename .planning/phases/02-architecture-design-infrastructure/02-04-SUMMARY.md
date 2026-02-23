---
phase: 02-architecture-design-infrastructure
plan: 04
subsystem: infra
tags: [bash, docker, docker-compose, vps, deployment, demo-scripts, jq]

# Dependency graph
requires:
  - phase: 02-architecture-design-infrastructure
    plan: 01
    provides: "openclaw.json configuration and claim.schema.json contract that scripts reference for paths, ports, and claim structure"
provides:
  - "scripts/setup.sh: One-touch VPS provisioning from bare Ubuntu 22.04 to running OpenClaw gateway"
  - "scripts/submit-claim.sh: Submit test claims with unique CLM-YYYY-NNNNN IDs from pre-built scenarios"
  - "scripts/check-status.sh: Color-coded claim status inspector with pipeline stage details and audit log"
  - "scripts/run-demo.sh: Full end-to-end demo orchestrator with polling, timeout, and --all flag"
  - ".env.example: Environment variable template for day-of configuration"
affects: [04-01, 04-03, 04-04]

# Tech tracking
tech-stack:
  added: [docker-compose, jq]
  patterns: [idempotent-provisioning, color-coded-demo-output, polling-with-timeout]

key-files:
  created:
    - scripts/setup.sh
    - scripts/submit-claim.sh
    - scripts/check-status.sh
    - scripts/run-demo.sh
    - .env.example
  modified: []

key-decisions:
  - "Docker Compose config created inline by setup.sh (not committed to repo) -- allows day-of customization if OpenClaw image name changes"
  - ".env.example committed with all required vars; setup.sh copies it to .env on VPS"
  - "Gateway bound to localhost only (127.0.0.1:18789) for security -- SSH tunnel for remote access per STACK.md recommendation"
  - "Claim ID generation uses timestamp-based sequence (seconds % 100000) with collision check loop"
  - "Router trigger uses OpenClaw CLI first, falls back to HTTP API, then warns if gateway not running"

patterns-established:
  - "All scripts use PROJECT_ROOT=$(cd dirname/.. && pwd) for portable path resolution"
  - "Color-coded output convention: GREEN=success/complete, YELLOW=warning/in-progress, RED=error/denied, CYAN=info"
  - "Terminal claim statuses: PAYMENT_ISSUED, DENIED, ESCALATED, ERROR"
  - "Demo polling pattern: 5s interval, 300s timeout, terminal status detection"

requirements-completed: [DEPLOY-01, DEPLOY-02]

# Metrics
duration: 4min
completed: 2026-02-17
---

# Phase 2 Plan 4: VPS Setup Script + Demo Scripts Summary

**Four bash scripts for hackathon day-of: one-touch VPS provisioning (Docker + OpenClaw + env config) and three demo runners (submit claim, check status, full pipeline) with color-coded output and jq formatting**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-17T20:39:31Z
- **Completed:** 2026-02-17T20:43:02Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Complete VPS setup script that provisions Ubuntu 22.04 from scratch: Docker, system packages (jq, git, curl), project clone, .env configuration, Docker Compose with health check, directory structure creation -- idempotent and safe to re-run
- Three demo scripts ready for hackathon day: submit-claim.sh generates unique claim IDs and triggers the router, check-status.sh displays color-coded pipeline progress with per-stage details, run-demo.sh orchestrates full pipeline with 5s polling and 5-minute timeout
- .env.example with all required variables (ANTHROPIC_API_KEY, OPENCLAW_GATEWAY_PORT, LOG_LEVEL)
- All scripts use consistent conventions: set -euo pipefail, PROJECT_ROOT detection, color-coded output, jq for JSON manipulation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create VPS setup script** - `58d242b` (feat)
2. **Task 2: Create demo runner scripts** - `fa313fd` (feat)

## Files Created/Modified
- `scripts/setup.sh` - One-touch VPS provisioning: Docker install, repo clone, .env creation, docker-compose.yml, service startup, health check
- `scripts/submit-claim.sh` - Submit test claims: scenario selection, unique CLM-YYYY-NNNNN generation, jq field injection, router trigger
- `scripts/check-status.sh` - Claim status inspector: color-coded pipeline stages, per-stage detail display, audit log tail
- `scripts/run-demo.sh` - Full demo orchestrator: submit + poll + display with timeout, --all flag for sequential scenarios
- `.env.example` - Environment variable template with ANTHROPIC_API_KEY, OPENCLAW_GATEWAY_PORT, LOG_LEVEL

## Decisions Made
- **Docker Compose created inline by setup.sh**: Rather than committing a docker-compose.yml to the repo, the setup script generates it. This allows day-of flexibility if the OpenClaw Docker image name or tag changes, without requiring a git pull to fix.
- **Gateway localhost-only binding**: Port 18789 bound to 127.0.0.1 only per STACK.md security recommendation. Team accesses via SSH tunnel during hackathon.
- **Timestamp-based claim ID sequence**: Uses `date +%s % 100000` for the 5-digit sequence number, with collision-check loop as safety. Simple, unique enough for hackathon scale (10-20 claims max).
- **Fallback router trigger chain**: submit-claim.sh tries OpenClaw CLI first, then HTTP API, then warns. This handles varying gateway states gracefully during development and demo.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Created .env.example file**
- **Found during:** Task 1 (VPS setup script)
- **Issue:** Plan mentioned "Copy .env.example" in setup.sh but .env.example did not exist in the repository. Setup script would fail on fresh clone.
- **Fix:** Created .env.example with all required environment variables (ANTHROPIC_API_KEY, OPENCLAW_GATEWAY_PORT, LOG_LEVEL)
- **Files modified:** .env.example
- **Verification:** setup.sh references .env.example and falls back to inline creation if missing
- **Committed in:** 58d242b (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for setup.sh to work correctly on fresh clone. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required during prep. ANTHROPIC_API_KEY will be entered on hackathon day.

## Next Phase Readiness
- All 4 deployment scripts ready for Phase 4 (Execution Playbook) to reference in day-of timeline
- scripts/run-demo.sh ready for Phase 4 Plan 3 (demo script) to orchestrate presentation flow
- Test claim scenarios (shared/test-claims/*.json) still needed from Phase 3 Plan 4 -- submit-claim.sh validates their existence and lists available scenarios
- No blockers identified

---
*Phase: 02-architecture-design-infrastructure*
*Completed: 2026-02-17*
