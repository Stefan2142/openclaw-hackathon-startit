# Plan: Session Cleanup on New Claim

## Problem

Pipeline agents retain conversation history from previous claims in their session files (`~/.openclaw/agents/<id>/sessions/*.jsonl`). This causes memory bleed — agents reference old claims that no longer exist in the DB, leading to incorrect decisions (e.g., Senior Reviewer escalating due to "cross-claim patterns" from deleted test claims).

## Solution

When the Router creates a new claim and is about to start the pipeline, it runs a single bash command to wipe all pipeline agent session files:

```bash
rm -f ~/.openclaw/agents/{claims-officer,assessor,fraud-analyst,senior-reviewer,finance}/sessions/*.jsonl*
```

- Instant (no LLM calls needed)
- The next `sessions_send` auto-creates a fresh session
- Router's own session stays intact (needs user conversation context)
- Only pipeline agents get wiped

## Status

IMPLEMENTED — added as step 7b in Router AGENTS.md FNOL Intake section.

---

## Full Nuclear Reset (for testing / debugging)

When things go wrong and you need a fully clean slate, here's the complete procedure:

### Step 1: Clear DB
```bash
PGPASSWORD=$DB_PASS psql -U openclaw -d openclaw_claims -h localhost -t -c "DELETE FROM agent_traces; DELETE FROM claims;"
```

### Step 2: Wipe ALL session files + metadata
```bash
rm -f ~/.openclaw/agents/*/sessions/*.jsonl*
rm -f ~/.openclaw/agents/*/sessions/sessions.json
```

**IMPORTANT:** You must also remove `sessions.json` (the metadata/index file). If you only remove `.jsonl` files, the gateway will still show stale session entries with old model assignments.

### Step 3: Restart gateway
```bash
openclaw gateway restart
```

**WHY:** The gateway caches session state in memory. Even after deleting files, the gateway continues to report stale sessions until restarted. Without restart, `openclaw status` shows phantom sessions with wrong models.

### Step 4: Reset Router
```bash
openclaw agent --agent router --message '/new' --timeout 30
```

Only the Router needs `/new` — pipeline agents get fresh sessions automatically on first `sessions_send`.

### Step 5: Verify
```bash
openclaw status
```

Check the Sessions table — should show only `agent:router:main` with the correct model. Other agents should not appear until the pipeline creates them.

---

## Caveats & Lessons Learned

### 1. Sessions lock to their creation-time model
When a session is created, it binds to whatever model was configured at that moment. If you change `model` in `openclaw.json` afterward, **existing sessions keep the old model**. You must:
- Delete the session files (`.jsonl` + `sessions.json`)
- Restart the gateway (clears memory cache)
- New sessions will pick up the updated model from config

### 2. Gateway caches session state in memory
`openclaw status` reads from the gateway's in-memory state, not directly from disk. After deleting session files:
- The gateway still reports old sessions until restarted
- A running pipeline can create new session files between your `rm` and `gateway restart`
- **Always restart the gateway after wiping sessions**

### 3. `sessions.json` is a hidden gotcha
Each agent has `~/.openclaw/agents/<id>/sessions/sessions.json` — a metadata index file that tracks session info (model, creation time, token counts). This is NOT a `.jsonl` file, so `rm -f *.jsonl*` misses it. The gateway uses it to reconstruct session state on restart. **Delete it too** during a full reset.

### 4. In-flight pipelines survive briefly after gateway restart
If a pipeline is mid-execution when you restart the gateway, the running LLM call may complete and write a new session file. To be safe:
- Restart gateway first (kills in-flight requests)
- Wait 3-5 seconds
- Then wipe session files
- Then restart gateway again (or just do: wipe → restart → `/new`)

### 5. `/new` vs `rm -f`
| | `/new` | `rm -f` |
|---|---|---|
| Speed | 5-15s (sends LLM message) | Instant |
| What it does | Renames old `.jsonl` to `.reset` suffix, creates fresh session | Deletes files completely |
| Gateway state | Updated immediately (gateway sees the new session) | Stale until gateway restart |
| When to use | Quick single-agent reset during testing | Full pipeline reset / model change |

### 6. The complete "scorched earth" one-liner
```bash
# Full reset: stop gateway → clear DB (order matters: media → traces → claims) → wipe sessions → start gateway → reset router
openclaw gateway stop && \
sleep 2 && \
PGPASSWORD=$DB_PASS psql -U openclaw -d openclaw_claims -h localhost -c "DELETE FROM claim_media; DELETE FROM agent_traces; DELETE FROM claims;" && \
rm -f ~/.openclaw/agents/*/sessions/*.jsonl* && \
rm -f ~/.openclaw/agents/*/sessions/sessions.json && \
openclaw gateway start && \
sleep 4 && \
openclaw agent --agent router --message '/new' --timeout 30
```

**CRITICAL order:**
1. **Stop gateway FIRST** — otherwise in-flight pipelines re-create rows between your DELETE and restart
2. **DELETE claim_media BEFORE claims** — foreign key constraint `claim_media_claim_id_fkey` blocks claim deletion if media rows reference them
3. **Wait after gateway stop** — gives in-flight LLM calls time to drain
4. **Wait after gateway start** — gateway needs ~3-4s to initialize before accepting agent commands

Use this before any clean test run or demo.
