# Shared State Architecture

This document defines the shared filesystem layout, path conventions, concurrency model, and mock policy database design for the Ohio Mutual Auto Claims Processing System. The shared directory is the single integration surface between all agents -- no agent-to-agent messaging, no database, no external services.

---

## 1. Directory Structure

```
shared/
├── schemas/
│   └── claim.schema.json          (from 02-01 -- the claim state contract)
├── state/
│   └── claims/                     (runtime claim files, one JSON file per claim)
│       ├── CLM-2026-00001.json
│       ├── CLM-2026-00002.json
│       └── ...
├── policies/                       (mock policy database -- 5 pre-built records)
│   ├── POL-AUT-10001.json
│   ├── POL-AUT-10002.json
│   ├── POL-AUT-10003.json
│   ├── POL-AUT-10004.json
│   └── POL-AUT-10005.json
├── uploads/                        (photo attachments organized by claim ID)
│   └── CLM-2026-00001/
│       ├── front-damage.jpg
│       ├── rear-damage.jpg
│       └── ...
└── test-claims/                    (pre-built test scenarios -- created in Phase 3)
    ├── happy-path.json
    ├── fraud-flag.json
    └── coverage-denial.json
```

### Directory Purpose

| Directory | Purpose | Created By | Read By |
|-----------|---------|------------|---------|
| `shared/schemas/` | JSON Schema contract (claim.schema.json) | Phase 2 Plan 01 | All agents (reference) |
| `shared/state/claims/` | Runtime claim files (one per active claim) | Router (creates initial), all pipeline agents (update) | All agents |
| `shared/policies/` | Mock policy database (static JSON files) | Phase 2 Plan 02 (this plan) | Claims Officer (reads during coverage verification) |
| `shared/uploads/` | Photo attachments per claim (subdirectory per claim ID) | External (simulated) | Assessor (reads photo descriptions/paths) |
| `shared/test-claims/` | Pre-built test scenario JSON files for demo | Phase 3 Plan 04 | Router (loads and submits for demo runs) |

---

## 2. Path Conventions

### Absolute Path Rule

**All agents use absolute paths.** No agent ever constructs a relative path to shared/ files.

**Why:** OpenClaw agents run inside their workspace directory (e.g., `./workspaces/front-desk/`). A relative path like `../../shared/state/claims/CLM-2026-00001.json` is fragile and workspace-dependent. Absolute paths are deterministic and independent of where the agent's workspace is located.

### Path Construction Responsibility

**The Router constructs all paths.** Pipeline agents receive absolute paths in their task messages and use them directly.

**Pattern:**
```
Router reads: claimant.policy_id = "POL-AUT-10001"
Router constructs: /opt/ohio-mutual/shared/policies/POL-AUT-10001.json
Router passes in task message: "Policy file: /opt/ohio-mutual/shared/policies/POL-AUT-10001.json"
Claims Officer reads that path directly -- no path construction logic needed
```

### Path Format

| Resource | Path Pattern | Example |
|----------|-------------|---------|
| Claim file | `{PROJECT_ROOT}/shared/state/claims/{CLAIM_ID}.json` | `/opt/ohio-mutual/shared/state/claims/CLM-2026-00001.json` |
| Policy file | `{PROJECT_ROOT}/shared/policies/{POLICY_ID}.json` | `/opt/ohio-mutual/shared/policies/POL-AUT-10001.json` |
| Photo upload | `{PROJECT_ROOT}/shared/uploads/{CLAIM_ID}/{filename}` | `/opt/ohio-mutual/shared/uploads/CLM-2026-00001/front-damage.jpg` |
| Test claim | `{PROJECT_ROOT}/shared/test-claims/{scenario}.json` | `/opt/ohio-mutual/shared/test-claims/happy-path.json` |
| Claim schema | `{PROJECT_ROOT}/shared/schemas/claim.schema.json` | `/opt/ohio-mutual/shared/schemas/claim.schema.json` |

**PROJECT_ROOT determination:** The Router reads its own workspace path from the environment or uses a configured base path (set in AGENTS.md or derived from the current working directory's parent). For the hackathon demo, this is `/opt/ohio-mutual` on the VPS or the local project directory during development.

---

## 3. Concurrency Model

### Sequential Pipeline -- Single Writer Per Claim

The sequential spawn pattern guarantees:
- **One agent writes to a claim file at a time.** The Router does not spawn Stage N+1 until Stage N announces completion.
- **No file locking needed.** Single-writer-at-a-time is enforced by the orchestration pattern, not by file system locks.
- **No race conditions.** Each stage reads the claim file (which includes all prior stage outputs), does its work, writes its section, and announces completion.

### Multiple Claims in Parallel

Different claims can process simultaneously because:
- Each claim has its own file (`CLM-2026-00001.json`, `CLM-2026-00002.json`)
- Different claims are in different pipeline stages at different times
- File-level isolation per claim ID means zero cross-claim interference
- `maxConcurrent: 6` in openclaw.json allows up to 6 active sub-agent sessions

### Write Pattern

Each pipeline agent follows this atomic write pattern:

```
1. Read claim file (full JSON)
2. Parse JSON
3. Add/update pipeline.{my_section} fields
4. Append to audit_log array
5. Update status field
6. Update updated_at timestamp
7. Write complete JSON back to file
```

For the hackathon, standard file write is sufficient. For production, the pattern would be:
1. Write to a temp file (`.CLM-2026-00001.json.tmp`)
2. Rename temp file to claim file (atomic on POSIX)

The hackathon's sequential pipeline makes the atomic-rename pattern unnecessary, but it is good practice and could be added as a refinement.

---

## 4. Mock Policy Database

### Overview

Five mock policy JSON files covering distinct scenarios the demo will exercise. These are static files -- they do not change during claim processing. The Claims Officer reads the policy file to verify coverage, check exclusions, determine deductible and coverage limits.

### Scenario Coverage

| Policy ID | Scenario | Key Test |
|-----------|----------|----------|
| POL-AUT-10001 | Standard active policy | Happy path -- coverage verified, claim proceeds |
| POL-AUT-10002 | Lapsed policy | Coverage denial -- policy expired outside grace period |
| POL-AUT-10003 | Excluded driver | Coverage denial -- driver on exclusion list |
| POL-AUT-10004 | High deductible | Coverage verified but large deductible reduces payment |
| POL-AUT-10005 | Comprehensive-only | No collision coverage -- collision claim denied, comp claim covered |

### Policy JSON Schema

Each policy file follows this structure:

```json
{
  "policy_id": "POL-AUT-NNNNN",
  "policyholder": {
    "name": "Full Name",
    "contact_phone": "555-...",
    "contact_email": "email@example.com",
    "address": {
      "street": "...",
      "city": "...",
      "state": "OH",
      "zip": "....."
    }
  },
  "effective_date": "YYYY-MM-DD",
  "expiration_date": "YYYY-MM-DD",
  "status": "active | lapsed | cancelled",
  "coverages": [
    {
      "type": "collision | comprehensive | liability | um_uim",
      "limit": 0,
      "deductible": 0,
      "per_person_limit": 0,
      "per_occurrence_limit": 0
    }
  ],
  "excluded_drivers": [
    {
      "name": "...",
      "reason": "..."
    }
  ],
  "vehicles": [
    {
      "year": 2024,
      "make": "...",
      "model": "...",
      "vin": "..."
    }
  ],
  "endorsements": [
    {
      "type": "...",
      "description": "..."
    }
  ]
}
```

### File Locations

All policy files live at: `shared/policies/POL-AUT-{NNNNN}.json`

The Claims Officer receives the absolute path in its task message from the Router.

---

## 5. Claim File Lifecycle

### Creation (Router)

When a claim submission arrives, the Router:
1. Generates claim_id (format: CLM-YYYY-NNNNN, e.g., CLM-2026-00001)
2. Creates initial JSON with status=FNOL_RECEIVED
3. Populates: claim_id, status, submitted_at, updated_at, claimant, incident
4. Initializes all pipeline sections with null/empty values
5. Writes first audit_log entry: "claim_registered"
6. Saves to `shared/state/claims/{CLAIM_ID}.json`

### Processing (Pipeline Agents)

Each pipeline agent:
1. Reads the full claim file
2. Validates prior stage is complete (checks pipeline.{prior_stage}.completed_at)
3. Performs analysis
4. Writes results to its pipeline section
5. Sets completed_at and agent_session
6. Updates claim status
7. Updates updated_at
8. Appends audit_log entry
9. Writes claim file back

### Completion (Router)

After the final stage (finance or denial point):
1. Router reads the completed claim
2. Verifies terminal status (PAYMENT_ISSUED or DENIED)
3. Writes final audit_log entry
4. Announces outcome to originating channel

### Archive (Future)

Completed claims remain in `shared/state/claims/`. For a production system, they would be moved to an archive directory. For the hackathon, all claims stay in place for demo visibility.

---

*Architecture specification for: Shared State Architecture*
*Phase 02, Plan 02 of Ohio Mutual Auto Claims Processing System*
