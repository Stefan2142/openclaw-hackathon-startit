# Plan: Feedback Loop & Deterministic Claim FSM

## Goal

Make the claim lifecycle fully deterministic with clear start/exit states, a collection loop for missing FNOL data, and a NEED_INFO mechanism for downstream agents to request user clarification mid-pipeline.

---

## Validated on VPS (2026-02-21)

| Test | Result |
|------|--------|
| Router session persists across `openclaw agent` calls | YES — second message continued same session |
| Router collects missing info then creates claim | YES — asked for 6 fields, received them, created CLM-2026-00003 |
| Full pipeline runs after collection | YES — CO, Assessor, Fraud, SR all executed |
| Terminal states reachable | YES — PAYMENT_ISSUED (CLM-00001), ESCALATED (CLM-00003) |
| Test claim cleaned up, VPS restored | YES — deleted CLM-00003 + traces |

Key finding: FNOL collection loop works naturally via Router session context. No custom DB state tracking needed for the intake phase.

### File Size Reality (verified)

| File | Local (git) | VPS (deployed) | Status |
|------|------------|----------------|--------|
| Router AGENTS.md | 10,658 chars | 20,234 chars | Local OK. VPS has old expanded version at limit. |
| Claims Officer AGENTS.md | 26,058 chars | 26,058 chars | OVER LIMIT. Being truncated by ~6K on VPS. |
| Assessor AGENTS.md | ~15K chars | ~15K chars | Under limit, OK. |

Key constraint: Claims Officer is 6K over the 20K OpenClaw limit and being truncated.
Router has ~9K headroom locally — no compression needed for adding new logic.
However, the VPS Router uses an old expanded version (20K) that was never in git.

---

## FSM: Start & Exit States

```
                    START
                      |
                User sends Telegram message
                      |
                      v
              +---------------+
              | Router checks |-----> Active claim exists?
              | active claims |       Route to that claim's context
              +---------------+
                      |
                No active claim
                      |
                      v
              +---------------+
              | FNOL COLLECT  |<---+
              | Parse message |    |
              | Check fields  |    | Missing fields?
              +---------------+    | Ask user, wait for response
                      |            | (max 2 rounds)
                All required    ---+
                fields present
                      |
                      v
              +---------------+
              | FNOL_RECEIVED |  <-- Claim created in DB
              +---------------+
                      |
          +-----------+-----------+
          |     PIPELINE RUNS     |
          |                       |
          v                       v
   +-------------+    +------------------+
   | Agent works  |    | Agent NEED_INFO  |
   | writes to DB |    | (needs user info)|
   +-------------+    +------------------+
          |                    |
          v                    v
   Validation OK        Router asks user
          |                    |
          v                    v
   Next stage            User responds
                               |
                               v
                      Router updates claim DB
                               |
                               v
                      Re-invoke same agent
                               |
                               v
                      Agent processes (fresh DB read)
          |
          +-------> continues through pipeline
          |
          v
   +--------------+     +---------+     +-----------+     +-------+
   | PAYMENT_     |     | DENIED  |     | ESCALATED |     | ERROR |
   | ISSUED       |     |         |     |           |     |       |
   +--------------+     +---------+     +-----------+     +-------+
     User gets $        No money       Needs human       System fail
     EXIT (final)       EXIT (final)   PAUSE (resumable) PAUSE (manual)
```

### Exit States

| State | Final? | User Outcome | How User is Told |
|-------|--------|-------------|------------------|
| PAYMENT_ISSUED | Yes | Gets money | "Your claim has been approved. Payment: $X,XXX" |
| DENIED | Yes | No money | "We're unable to approve. Reason: ..." |
| ESCALATED | No (paused) | Waiting | "Your claim needs additional review by our senior team" |
| ERROR | No (stuck) | Waiting | "We're experiencing a temporary issue" |

### Single Active Claim Rule

One claim per user at a time. Before any new message processing:
1. `db.sh get-active-claim <user_id>` — returns non-terminal claim if exists
2. If active → route message to that claim (status inquiry, additional info, or NEED_INFO response)
3. If none → treat as new FNOL submission

---

## Changes Required

### Phase 1: Claims Officer AGENTS.md Compression (prerequisite)

Current: 26,058 chars. Limit: 20,000 chars. Being truncated by ~6K on VPS.
Must compress BEFORE adding NEED_INFO logic — otherwise the NEED_INFO
instructions will be in the truncated section and never seen by the agent.

Target: <18,000 chars (leave room for NEED_INFO section).

Action: Analyze CO AGENTS.md sections, identify verbose/redundant content,
compress while keeping all operational rules intact.

Note: Router AGENTS.md is 10,658 chars locally — well under limit.
No compression needed for Router. New logic can be added directly.

### Phase 2: db.sh — add get-active-claim

```bash
get-active-claim)
  # Returns the active (non-terminal) claim for a user.
  # Terminal states: PAYMENT_ISSUED, DENIED, ESCALATED, ERROR
  # Usage: db.sh get-active-claim telegram_user_123
  USER_ID="$2"
  $PSQL -c "SELECT claim_data FROM claims
            WHERE user_id = '$USER_ID'
            AND status NOT IN ('PAYMENT_ISSUED', 'DENIED', 'ESCALATED', 'ERROR')
            ORDER BY created_at DESC LIMIT 1;"
  ;;
```

### Phase 3: Router AGENTS.md — add new logic

Add these rules to the compressed Router AGENTS.md:

**A) Single active claim check (add to top of message handling):**
```
On EVERY incoming message:
1. Run: db.sh get-active-claim <user_id>
2. If result is non-empty → this user has an active claim
   - If you are waiting for NEED_INFO response → process as the answer
   - If claim is in pipeline → tell user: "Your claim [ID] is being processed"
   - If user asks about status → read claim, report current stage
3. If result is empty → treat as new FNOL submission
```

**B) NEED_INFO handling (add to pipeline execution):**
```
New announce status: NEED_INFO

When a pipeline agent announces NEED_INFO:
1. Parse the agent's response for questions
2. Do NOT advance the pipeline status
3. Do NOT call the next agent
4. Ask the user via Telegram (relay the agent's questions in user-friendly language)
5. Wait for user response (next incoming message)
6. Update claim_data with the user's answer (via db.sh update-step or direct JSON update)
7. Re-invoke the SAME agent with updated task message noting "Previous NEED_INFO resolved"
8. Max 1 NEED_INFO round per agent (if still unresolved, proceed and let SR handle it)
```

**C) Announce protocol update:**
```
Agent responses now have 4 possible statuses:
- SUCCESS: completed normally, proceed to next stage
- ERROR: failed, retry (up to 3 attempts)
- ESCALATE: needs human, stop pipeline
- NEED_INFO: needs user clarification, pause and ask
```

### Phase 4: Claims Officer AGENTS.md — add NEED_INFO

Add to Claims Officer operating protocol:

```
If you encounter a data mismatch or ambiguity that cannot be resolved from
the policy file alone, announce NEED_INFO instead of ERROR or SUCCESS:

Status: NEED_INFO
Summary: [what's wrong]
Questions: [specific questions for the claimant]
Data needed: [which claim_data fields need correction]

Examples of when to use NEED_INFO:
- Policy ID not found in /shared/policies/
- Incident date is outside policy effective period
- Vehicle on policy doesn't match described vehicle
- Named insured doesn't match claimant name
- Coverage type is ambiguous between collision and comprehensive
```

### Phase 5: Test Scripts

**test-fnol-loop.sh** — tests Router FNOL collection:
```
1. Reset Router session (/new)
2. Send incomplete message: "I had a car accident on Main St in Columbus"
   - Missing: policy_id, name, phone, incident_type, date
3. Verify: Router response asks for missing info (grep for "policy" in response)
4. Send follow-up: "John Smith, POL-AUT-10001, phone 555-234-5678, collision, yesterday"
5. Verify: claim created in DB (query claims table for latest by user)
6. Verify: status is progressing (not stuck at nothing)
7. Cleanup: delete test claim
```

**test-need-info.sh** — tests CO NEED_INFO response:
```
1. Seed a claim with policy_id = "POL-FAKE-99999" (doesn't exist in /shared/policies/)
2. Invoke Claims Officer with standard task message
3. Verify: CO response contains "NEED_INFO" (grep response text)
4. Verify: CO did NOT write completed_at (should be null)
5. Cleanup: delete test claim
```

**test-single-claim.sh** — tests single active claim enforcement:
```
1. Seed a claim in ASSESSED status for user "test-user-001"
2. Send new message to Router as same user: "I had another accident"
3. Verify: Router does NOT create a second claim
4. Verify: Router references the existing claim
5. Cleanup: delete test claim
```

### Phase 6: TECHNICAL.md Update

Already partially done (states documented). After implementation:
- Update "planned" labels to "implemented"
- Add NEED_INFO flow to the states section
- Document get-active-claim in db.sh reference table

---

## Implementation Order

```
1. Compress Claims Officer AGENTS.md (prerequisite — it's 6K over limit)
2. Add get-active-claim to db.sh
3. Update Router AGENTS.md with single-claim + NEED_INFO logic (~9K headroom, no compression needed)
4. Update Claims Officer AGENTS.md with NEED_INFO announce (after compression)
5. Deploy to VPS (db.sh, Router AGENTS.md, CO AGENTS.md)
6. Reset agent sessions (/new on router, claims-officer)
7. Run test-fnol-loop.sh
8. Run test-need-info.sh
9. Run test-single-claim.sh
10. Update TECHNICAL.md with final state
11. Commit + push
```

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| CO AGENTS.md compression loses critical instructions | CO misbehaves | Verify with test-claims-officer.sh after compression |
| CO truncation hides NEED_INFO instructions | CO never announces NEED_INFO | NEED_INFO section must be near the top, not bottom |
| LLM doesn't reliably parse NEED_INFO from CO response | Feedback loop breaks | Structured announce format + explicit parsing rules |
| NEED_INFO creates infinite loop (agent keeps asking) | Claim stuck forever | Max 1 NEED_INFO round per agent per claim |
| User sends garbage during NEED_INFO wait | Claim corrupted | Router validates response before updating claim |
| Rate limits during long pipeline run | Timeouts | Already handled: embedded fallback + retry logic |
| VPS has different AGENTS.md than git repo | Behavior mismatch | Deploy from git, /new all agents after deploy |

---

## NEED_INFO Database Behavior

During a NEED_INFO round, the DB state is:

```
BEFORE:  status = FNOL_RECEIVED (CO hasn't completed)
         pipeline.claims_officer.completed_at = null

CO ANNOUNCES NEED_INFO:
         → CO does NOT write update-step (hasn't finished)
         → CO does NOT change status (hasn't concluded)
         → Status stays: FNOL_RECEIVED
         → pipeline.claims_officer stays: all null

ROUTER ASKS USER:
         → No DB change. Questions live in Router session context.

USER RESPONDS:
         → Router updates claim_data (e.g., corrects policy_id)
         → Status stays: FNOL_RECEIVED

ROUTER RE-INVOKES CO:
         → CO reads fresh claim_data from DB
         → CO processes normally with corrected data
         → CO writes update-step (completed_at, covered, etc.)
         → Router validates, transitions to COVERAGE_CHECKED

AFTER:   status = COVERAGE_CHECKED
         pipeline.claims_officer.completed_at = <timestamp>
```

The claim is always in a valid DB state. If the Router session dies during NEED_INFO
wait, the claim stays at FNOL_RECEIVED with no CO data — a clean restart point.

---

## What We Are NOT Building

- No custom DB state tracking for FNOL collection (session context handles it)
- No multi-round NEED_INFO (max 1 round per agent — keeps it simple)
- No parallel claim processing (single claim per user enforced)
- No ESCALATED resumption (still requires manual restart)
- No changes to Assessor, Fraud Analyst, Senior Reviewer, or Finance (NEED_INFO starts with CO only)
