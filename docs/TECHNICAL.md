# Technical Documentation

## How It Works

### Platform
- **OpenClaw** multi-agent platform — each agent runs in its own workspace with isolated AGENTS.md, IDENTITY.md, SOUL.md, TOOLS.md
- Agents communicate via `sessions_send` (synchronous RPC through Router)
- Deployed on Hetzner VPS (Ubuntu)

### Communication Model
- **Router** is the only agent that receives external messages (Telegram)
- Pipeline agents are invoked by Router via `sessions_send` with constructed task messages
- Agents write results to PostgreSQL, Router validates before calling the next agent
- No direct agent-to-agent communication — all orchestration flows through Router

### Models
- Agents use the LLM model configured in OpenClaw (typically Claude)
- Each agent has a specialized system prompt (AGENTS.md) that defines its behavior, domain knowledge, and output format

### Shared State
- **PostgreSQL** with JSONB `claim_data` column stores the full claim document
- Single `claims` table — each row is one claim with full pipeline state
- `claim_media` table for photo/document references
- `agent_traces` table for observability logging
- All agents read/write via `db.sh` CLI wrapper — no direct SQL

### Tool Permissions
- Each agent's TOOLS.md defines which tools it can access
- All agents can run `bash /shared/scripts/db.sh` commands
- Assessor uses `get-claim-assessor` (stripped data) while all others use `get-claim` (full data)
- Router has additional permissions for `sessions_send` to call other agents

### Observability
- **agent_traces** table logs START/STEP/END/ERROR events per agent per claim
- Each trace includes JSONB `details` with structured data (input summary, decisions, output)
- Query: `db.sh get-traces <claim_id> [agent_name]`
- **audit_log** array inside each claim document provides business-level audit trail
- Combined: traces show HOW an agent processed; audit_log shows WHAT decisions were made and WHY

### Testing
- **Pin-test framework** at `shared/test-scripts/` — tests each agent in isolation
- Seeds pre-populated claim data up to the agent's entry point
- Invokes the agent with a realistic task message
- Verifies output fields in the database after agent completes
- Available tests: test-claims-officer.sh, test-assessor.sh, test-fraud-analyst.sh, test-senior-reviewer.sh, test-finance.sh, test-need-info.sh, test-fnol-loop.sh, test-single-claim.sh

---

## Claim States (FSM)

### Pipeline States (current)

```
FNOL_RECEIVED → COVERAGE_CHECKED → ASSESSED → FRAUD_ANALYZED → REVIEWED → PAYMENT_ISSUED
       |               |                                            |
       |               +→ DENIED                                    +→ DENIED
       |
       +→ (from any stage) → ESCALATED
       +→ (from any stage) → ERROR
```

| State | Set By | Meaning |
|-------|--------|---------|
| FNOL_RECEIVED | Router | Claim created, FNOL intake complete |
| COVERAGE_CHECKED | Router (after CO) | Claims Officer verified coverage |
| ASSESSED | Router (after Assessor) | Damage assessment complete |
| FRAUD_ANALYZED | Router (after Fraud) | Fraud analysis complete |
| REVIEWED | Router (after SR) | Senior Reviewer made decision |
| PAYMENT_ISSUED | Router (after Finance) | Payment disbursed, pipeline done |
| DENIED | Router | Claim denied (at coverage or review) |
| ESCALATED | Router | Paused for human adjuster |
| ERROR | Router | Unrecoverable failure after max retries |

### Terminal States

| State | Can Resume? | What Happens |
|-------|-------------|-------------|
| PAYMENT_ISSUED | No | Claim settled (supplementals possible as new flow) |
| DENIED | No | Claim rejected, appeal rights communicated |
| ESCALATED | Theoretically yes | Needs human resolution, then manual restart |
| ERROR | Manual only | Requires investigation and manual intervention |

### FNOL Collection Loop (implemented)

When a user submits incomplete information, the Router enters a collection loop before creating the claim. The Router's session context tracks the conversation naturally — no custom DB state needed.

```
USER_MESSAGE → PARSE → VALIDATE
                          |
                  (all required present) → CREATE_CLAIM → PIPELINE_START
                          |
                  (fields missing) → ASK_USER → USER_RESPONDS → PARSE (attempt 2)
                          |
                  (attempt 2, still missing) → CREATE_CLAIM with missing_info noted
```

Required FNOL fields:
- policy_id, claimant_name, claimant_phone
- incident_date, incident_location, incident_description, incident_type

Validated: Router asks for missing fields, collects them in follow-up message, then creates claim and starts pipeline.

### NEED_INFO Feedback Loop (implemented)

Pipeline agents can announce `NEED_INFO` instead of `SUCCESS` when they need user clarification mid-pipeline:

```
AGENT_PROCESSING → NEED_INFO announced
     ↓
Router relays questions to user via Telegram
     ↓
User responds
     ↓
Router updates claim_data in DB
     ↓
Router re-invokes same agent (new turn, reads updated DB)
     ↓
AGENT_PROCESSING (retry with corrected data)
```

DB state during NEED_INFO: claim stays at current status, agent has NOT written update-step or completed_at. This is a clean restart point if the session dies.

Max 1 NEED_INFO round per agent (to prevent infinite loops). Currently implemented for Claims Officer (e.g., policy not found, name mismatch).

### Single Active Claim Rule (implemented)

The Router enforces one active claim per user. On every incoming message:
1. Run `db.sh get-active-claim <user_id>` — returns non-terminal claim if exists
2. If active claim exists → route message to that claim's context (status inquiry, NEED_INFO response, or "claim in progress" message)
3. If no active claim → treat as new FNOL submission

---

## Known Technical Limitations

### 1. No Parallel Processing
Pipeline agents run sequentially. Each agent must complete before the next starts. This is by design (each stage depends on the previous) but means total processing time is the sum of all agents.

**Impact:** A full pipeline run takes ~2-3 minutes. Acceptable for insurance claims where regulatory timelines are in days/weeks.

### 2. AGENTS.md Caching
OpenClaw caches AGENTS.md at session start. Changes to an agent's instructions require running `/new` on that agent to pick up updates. Without `/new`, the agent continues using the cached version.

**Impact:** Deploying agent updates requires cycling agent sessions. In production, this would need a deployment protocol.

### 3. No ESCALATED State Resumption
When a claim is escalated to a human adjuster (ESCALATE_HUMAN), the pipeline stops. There is no built-in mechanism to resume the pipeline after human resolution.

**Impact:** Escalated claims require manual re-triggering. In production, this would need a human-in-the-loop workflow with a callback mechanism.

### 4. Non-Deterministic Responses
LLM outputs vary between runs. The same claim may get slightly different estimates, risk scores, or decision reasoning each time. Agent specifications constrain the output format but not the exact values.

**Impact:** Pin-tests validate field presence and type, not exact values. Two runs of the same claim may produce different but both-valid outcomes.

### 5. Single-Turn Agent Interaction
Each agent receives one task message and produces one response. There is no multi-turn conversation between Router and pipeline agents. If an agent's output is incomplete, the Router retries with the same message.

**Impact:** Complex claims that might benefit from iterative refinement get the same single-shot treatment as simple claims. The retry mechanism (up to 3 attempts) partially mitigates this.

### 6. No File-Level Access Control
While `get-claim-assessor` strips financial data at the SQL level, there is no mechanism preventing an agent from reading files it shouldn't (e.g., policy files). The separation of duties relies on agents following their AGENTS.md instructions for file access.

**Impact:** Data segregation is enforced for database reads but not for file system access. The Assessor could theoretically read policy files directly. OpenClaw's TOOLS.md restrictions partially mitigate this.

### 7. Timeout Risk
Agent invocations have a configurable timeout (default 120 seconds, increased on retry). Complex claims with extensive reasoning may approach or exceed the timeout, especially for Fraud Analyst and Senior Reviewer which must analyze the entire pipeline.

**Impact:** Router increases timeout by 30s on each retry. After 3 failed attempts, the claim enters ERROR state and requires manual intervention.

### 8. Telegram Allowlist Only
The system only accepts messages from pre-configured Telegram users. There is no self-service registration or authentication beyond Telegram's built-in user identity.

**Impact:** Adding new users requires VPS configuration change. Acceptable for demo/hackathon; would need proper auth in production.

---

## Database Schema

### claims table
```sql
CREATE TABLE claims (
    id SERIAL PRIMARY KEY,
    claim_id TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'FNOL_RECEIVED',
    channel TEXT,
    user_id TEXT,
    policy_id TEXT,
    claim_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### claim_media table
```sql
CREATE TABLE claim_media (
    id SERIAL PRIMARY KEY,
    claim_id TEXT REFERENCES claims(claim_id),
    file_path TEXT NOT NULL,
    media_type TEXT DEFAULT 'image',
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
```

### agent_traces table
```sql
CREATE TABLE agent_traces (
    id SERIAL PRIMARY KEY,
    claim_id TEXT NOT NULL,
    agent_name TEXT NOT NULL,
    event_type TEXT NOT NULL,  -- START, STEP, END, ERROR
    summary TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## db.sh Commands Reference

| Command | Purpose | Used By |
|---------|---------|---------|
| create-claim | Create new claim with full JSON | Router |
| get-claim | Read full claim data | All agents except Assessor |
| get-claim-assessor | Read claim with financial fields stripped | Assessor only |
| update-status | Set claim status | Router (and agents for backwards compat) |
| update-step | Write agent results to pipeline section | All pipeline agents |
| append-audit | Add audit log entry | All agents |
| list-claims-by-user | Get all claims for a user | Fraud Analyst |
| count-user-claims | Get claim count stats for a user | Fraud Analyst |
| get-active-claim | Get active (non-terminal) claim for a user | Router |
| list-claims-by-status | Get claims by status | Router |
| add-media | Record media file reference | Router |
| get-media | Get media files for a claim | Assessor |
| log-trace | Write observability trace | All agents |
| get-traces | Read traces for a claim | Debugging/monitoring |
