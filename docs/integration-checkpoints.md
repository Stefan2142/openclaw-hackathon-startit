# Integration Checkpoint Protocol

Two mandatory integration checkpoints during the build day. All 3 members stop their individual work and participate. Member A (Router/Infrastructure owner) leads both checkpoints. Max 30 minutes per checkpoint -- if not resolved, flag the issue and move on with a workaround.

**See also:** [day-of-timeline.md](day-of-timeline.md) for full schedule, [team-work-split.md](team-work-split.md) for workstream details.

---

## Checkpoint 1: Pipeline Skeleton (Hour 3 / ~13:00)

### Purpose

Verify the orchestration layer works: Router can spawn pipeline agents, agents can read/write claim JSON, and the first 1-2 stages of the pipeline produce valid output.

### What Must Work

1. **Router can spawn Front Desk** via `sessions_spawn`
2. **Front Desk processes a claim** and writes to `pipeline.front_desk` section in the claim JSON
3. **Router reads Front Desk output** and validates required fields: `completed_at`, `category`, `priority`
4. **Router transitions status** from `FNOL_RECEIVED` to `COVERAGE_CHECKED`
5. **Shared directory structure exists and is accessible:** `shared/state/claims/`, `shared/policies/`, `shared/schemas/`
6. **(Stretch goal) If Claims Officer ready:** Router spawns Claims Officer, it reads the policy file, and `covered=true` is set

### How to Verify

**Step 1: Submit a test claim**
```bash
./scripts/submit-claim.sh happy-path-collision
```
Expected: Claim ID generated (CLM-YYYY-NNNNN format). Claim JSON written to `shared/state/claims/`.

**Step 2: Check Front Desk output**
```bash
./scripts/check-status.sh CLM-YYYY-NNNNN
```
Expected: Status shows `COVERAGE_CHECKED` (Front Desk has completed). Look for:
```json
{
  "pipeline": {
    "front_desk": {
      "completed_at": "2026-02-21T...",
      "category": "standard_collision",
      "priority": "normal",
      "missing_info": []
    }
  }
}
```

**Step 3: Verify audit log**
```bash
jq '.audit_log' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: At least 2 entries -- one from Router (claim_registered) and one from Front Desk (intake_complete).

**Step 4: (If Claims Officer ready) Verify coverage**
```bash
jq '.pipeline.claims_officer' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: `covered=true`, `deductible_amount` and `coverage_limit` populated.

### Pass Criteria

**PASS:** Router successfully spawns Front Desk. Front Desk output is valid JSON with `category`, `priority`, and `completed_at` all populated. Audit log has entries from both Router and Front Desk.

**STRETCH PASS:** Claims Officer also spawns successfully and sets `covered=true` with deductible and limit populated.

### Fail Scenarios and Rollback Strategies

#### Failure: Router cannot spawn Front Desk

**Symptoms:** `sessions_spawn` returns error, agent not found, or timeout.

**Diagnosis checklist:**
1. Check `openclaw.json` -- does `agentDir` for front-desk point to the correct path?
   ```bash
   jq '.agents[] | select(.id=="front-desk") | .workspace' openclaw.json
   ```
2. Verify gateway is running:
   ```bash
   curl -sf http://localhost:18789/health
   ```
3. Check agent ID matches exactly (case-sensitive): `front-desk`
4. Verify AGENTS.md exists in the workspace directory:
   ```bash
   ls -la workspaces/front-desk/AGENTS.md
   ```
5. Check gateway logs for spawn errors:
   ```bash
   docker compose logs --tail=50 openclaw
   ```

**Rollback:**
- Fix the `openclaw.json` configuration
- Restart gateway: `docker compose restart`
- Re-test spawn

#### Failure: Front Desk spawns but produces invalid output

**Symptoms:** Front Desk runs but `pipeline.front_desk` section is missing fields, wrong format, or empty.

**Diagnosis checklist:**
1. Check the claim JSON file directly:
   ```bash
   jq '.pipeline.front_desk' shared/state/claims/CLM-*.json
   ```
2. Check if Front Desk wrote to the correct file path (did it find the claim file?)
3. Review AGENTS.md output format section -- does it specify the exact field names?
4. Check if Front Desk has `write` tool permission in `openclaw.json`

**Rollback:**
- Edit `workspaces/front-desk/AGENTS.md` to fix output format instructions
- Delete the test claim file: `rm shared/state/claims/CLM-*.json`
- Re-submit and re-test

#### Failure: Router does not validate or transition status

**Symptoms:** Front Desk writes correctly but Router does not proceed to next stage. Status stuck at `FNOL_RECEIVED`.

**Diagnosis checklist:**
1. Check Router AGENTS.md -- is the validation logic for front_desk output clearly specified?
2. Check if Router reads the claim file after announce (the announce-wait-read-spawn cycle)
3. Check if Router's status transition logic matches the state machine

**Rollback:**
- Edit `workspaces/router/AGENTS.md` to clarify validation and transition logic
- Re-test from fresh claim submission

#### Failure: Claims Officer cannot find policy file

**Symptoms:** Claims Officer spawns but errors on policy lookup.

**Diagnosis checklist:**
1. Verify policy files exist:
   ```bash
   ls shared/policies/
   ```
2. Check the policy path in the Router's task message -- is it absolute?
3. Verify the policy ID in the test claim matches an existing policy file
4. Check Claims Officer `read` tool permission

**Rollback:**
- Fix policy file deployment
- Fix Router task message template for claims-officer stage
- Re-test

### Time Budget

- **Max time on Checkpoint 1:** 30 minutes (13:00-13:30)
- If not resolved by 13:30: document the issue, move on to Build Block 2, fix during integration window (15:30-17:00)
- Do NOT let Checkpoint 1 delay Member B and C from continuing their AGENTS.md typing

---

## Checkpoint 2: Full Pipeline (Hour 5 / ~15:00)

### Purpose

Verify the complete 6-stage pipeline works end-to-end. A happy-path claim should run from FNOL through payment with complete audit trail.

### What Must Work

1. **Happy path claim runs through ALL 6 pipeline stages** end-to-end
2. **Each stage writes its pipeline section** correctly (valid JSON, all required fields)
3. **Router transitions through all statuses:** FNOL_RECEIVED -> COVERAGE_CHECKED -> ASSESSED -> FRAUD_ANALYZED -> REVIEWED -> PAYMENT_ISSUED
4. **Audit log has entries from all 6 agents** (minimum 6 entries, likely 7+ including Router entries)
5. **`run-demo.sh` completes without error** for happy-path scenario

### How to Verify

**Step 1: Run the full demo**
```bash
./scripts/run-demo.sh happy-path-collision
```
Expected: Script submits claim, polls status, reaches `PAYMENT_ISSUED` within 5 minutes.

**Step 2: Verify final status**
```bash
./scripts/check-status.sh CLM-YYYY-NNNNN
```
Expected: `"status": "PAYMENT_ISSUED"`

**Step 3: Verify all pipeline sections populated**
```bash
jq '.pipeline | keys' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: `["front_desk", "claims_officer", "assessor", "fraud_analyst", "senior_reviewer", "finance"]`

**Step 4: Verify all sections have completed_at**
```bash
jq '.pipeline | to_entries[] | {stage: .key, completed: .value.completed_at}' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: All 6 stages show a `completed_at` timestamp.

**Step 5: Verify audit log completeness**
```bash
jq '.audit_log | length' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: 6 or more entries.

```bash
jq '[.audit_log[].agent] | unique' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: All agent names appear (router, front-desk, claims-officer, assessor, fraud-analyst, senior-reviewer, finance).

**Step 6: Verify finance output**
```bash
jq '.pipeline.finance | {payment: .payment_amount_usd, subrogation: .subrogation_candidate}' shared/state/claims/CLM-YYYY-NNNNN.json
```
Expected: `payment_amount_usd > 0`, `subrogation_candidate = true` (happy-path collision with at-fault other party).

### Pass Criteria

**PASS:** Happy path claim reaches `PAYMENT_ISSUED`. All 6 pipeline sections have `completed_at` timestamps. Audit log has entries from all 6 pipeline agents. Finance section has `payment_amount_usd > 0`.

### Fail Scenarios and Rollback Strategies

#### Failure: Pipeline stalls at a specific stage

**Symptoms:** `run-demo.sh` shows status stuck at one of the intermediate statuses (COVERAGE_CHECKED, ASSESSED, FRAUD_ANALYZED, REVIEWED).

**Diagnosis:**
1. Identify which stage stalled -- the status tells you the LAST successful stage:
   - `COVERAGE_CHECKED` = Assessor failed (Stage 3)
   - `ASSESSED` = Fraud Analyst failed (Stage 4)
   - `FRAUD_ANALYZED` = Senior Reviewer failed (Stage 5)
   - `REVIEWED` = Finance failed (Stage 6)
2. Check the failing agent's pipeline section -- is it partially written?
3. Check gateway logs for the spawned agent session
4. Check the AGENTS.md for the failing agent -- is the output format correct?

**Rollback:**
- Fix the failing agent's AGENTS.md (most common fix)
- Delete the test claim and re-run from scratch
- If the agent is fundamentally broken: temporarily modify Router AGENTS.md to skip that stage (emergency workaround)

#### Failure: Router hangs between stages

**Symptoms:** One stage completes but Router does not spawn the next stage. Gateway logs show Router is idle.

**Diagnosis:**
1. Check Router AGENTS.md -- is the announce-wait-read-spawn cycle clear for all transitions?
2. Check if the previous agent's announce message format matches what Router expects
3. Check per-stage timeout -- did the stage run out of time?
4. Check Router's validation logic -- is it rejecting valid output?

**Rollback:**
- Fix Router AGENTS.md validation/transition logic for the specific stage pair
- Restart the pipeline from a fresh claim

#### Failure: Agent produces wrong output format

**Symptoms:** Stage completes but Router rejects the output (missing required fields).

**Diagnosis:**
1. Compare agent output against `claim.schema.json` field definitions
2. Check if the field name is mismatched (e.g., `repair_estimate` vs `repair_estimate_usd`)
3. Check if the agent wrote to the correct pipeline section name

**Rollback:**
- Fix the agent's AGENTS.md output format section to match schema field names exactly
- Re-run the pipeline

#### Failure: Timeout (pipeline takes too long)

**Symptoms:** `run-demo.sh` hits its 5-minute timeout before reaching terminal status.

**Diagnosis:**
1. Check which stage is slow -- the status at timeout tells you
2. Check per-stage timeout settings in Router AGENTS.md
3. Some agents may need longer timeouts (Assessor: 120s is allocated)
4. Check if the model is responding slowly (API latency)

**Rollback:**
- Increase per-stage timeout in Router AGENTS.md
- Simplify the slow agent's AGENTS.md (less text = faster inference)
- Increase `run-demo.sh` timeout if needed: edit `TIMEOUT_SECONDS` variable

### Priority Order for Fixing Failures

If multiple issues exist, fix in this order:

1. **Fix the specific failing agent** (most common root cause -- 80% of failures)
2. **Check Router validation logic** (Router may reject valid output due to field name mismatch)
3. **Check tool permissions** (agent may lack read or write access)
4. **Check file paths** (Router may construct wrong absolute paths)
5. **Restart gateway** (last resort -- clears all state)

### Emergency Workaround: Skip a Failing Stage

If a specific agent cannot be fixed within the checkpoint time budget, temporarily bypass it:

1. Edit Router AGENTS.md to skip the failing stage in the spawn sequence
2. The pipeline will have a gap (e.g., no fraud analysis) but will still complete
3. Fix the agent during the integration window (15:30-17:00)
4. Re-enable the stage in Router AGENTS.md after fixing
5. Re-run all scenarios to verify

**This is an emergency measure only.** The goal is a complete 6-stage pipeline for the demo.

### Time Budget

- **Max time on Checkpoint 2:** 30 minutes (15:00-15:30)
- If not resolved by 15:30: document the issue, proceed to integration window, fix during 15:30-17:00
- The integration window (15:30-17:00) is specifically designed for fixing Checkpoint 2 failures

---

## General Checkpoint Rules

### Before Every Checkpoint

1. **All 3 members stop their individual work** -- no exceptions
2. **Clean the test environment:** Delete any leftover test claims from `shared/state/claims/`
3. **Verify gateway is healthy:** `curl -sf http://localhost:18789/health`
4. **Have all diagnostic commands ready** (copy-paste from this document)

### During Every Checkpoint

1. **Member A leads** -- runs all commands, calls out results
2. **Member B monitors** stages 1-2 output (Front Desk, Claims Officer)
3. **Member C monitors** stages 3-6 output (Assessor, Fraud Analyst, Senior Reviewer, Finance)
4. **Document what works and what fails** in a shared scratchpad (text file or shared screen)

### After Every Checkpoint

1. **Record results:** What passed, what failed, what was fixed, what was deferred
2. **Update the shared scratchpad** with current pipeline status
3. **Return to individual workstreams** unless fixing a blocking issue

### Shared Scratchpad Template

Keep a running log during checkpoints (simple text file on VPS):

```
# Checkpoint Log -- Feb 21

## Checkpoint 1 (13:00)
- Router -> Front Desk: [PASS/FAIL] [notes]
- Front Desk output valid: [PASS/FAIL] [notes]
- Router -> Claims Officer: [PASS/FAIL/NOT TESTED] [notes]
- Coverage check: [PASS/FAIL/NOT TESTED] [notes]
- Issues found: [list]
- Issues fixed: [list]
- Issues deferred: [list]

## Checkpoint 2 (15:00)
- Full pipeline (happy-path): [PASS/FAIL] [notes]
- All 6 stages complete: [PASS/FAIL] [notes]
- Audit log complete: [PASS/FAIL] [notes]
- Finance payment correct: [PASS/FAIL] [notes]
- Issues found: [list]
- Issues fixed: [list]
- Issues deferred: [list]
```

---

## Quick Diagnostic Reference

Common issues and their one-line fixes:

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `sessions_spawn` returns "agent not found" | Agent ID mismatch in `openclaw.json` | Fix agent `id` field to match spawn call |
| Agent cannot read claim file | Wrong file path in task message | Fix Router task message template (use absolute paths) |
| Agent cannot write to claim file | Missing `write` tool permission | Fix `openclaw.json` tool scoping for that agent |
| Claims Officer cannot find policy | Policy files not deployed or wrong path | Deploy to `shared/policies/`, fix path in Router task |
| Output missing required fields | AGENTS.md output format unclear | Edit output format section to list exact field names |
| Status does not transition | Router validation too strict or field name mismatch | Fix Router validation logic for that stage |
| Agent timeout | AGENTS.md too long or model slow | Increase `runTimeoutSeconds` or simplify AGENTS.md |
| Gateway not responding | Container crashed | `docker compose restart` and check logs |

---

*Integration checkpoint protocol for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
