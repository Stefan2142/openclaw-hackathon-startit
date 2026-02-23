# Pitfalls Research

**Domain:** Multi-agent insurance claims processing — OpenClaw hackathon (10 hours)
**Researched:** 2026-02-17
**Confidence:** HIGH (OpenClaw docs) / MEDIUM (insurance domain + hackathon patterns from multiple sources)

---

## Critical Pitfalls

### Pitfall 1: Hardcoding Insurance Rules Instead of Reasoning

**What goes wrong:**
Teams encode business logic as rigid if/else conditionals in AGENTS.md — e.g., "if claim > $10,000 then flag as fraud" or "Ohio law requires 15-day acknowledgment, set timer to 15." The system works for the demo scenario but collapses the moment a judge asks "what if the state is Texas?" or "what if the secret addition changes the fraud threshold?" The judging rule "your thinking should not be hardcoded" is a direct disqualification trigger for this approach.

**Why it happens:**
Engineering instinct is to convert requirements into deterministic rules. Teams research insurance regulations and then immediately encode them as code-like conditionals in their agent instructions. It feels complete and defensible. It is the opposite of what the organizers asked for.

**How to avoid:**
Write AGENTS.md instructions as *principles and reasoning frameworks*, not rule tables. Instead of "claims over $10,000 go to fraud review," write "apply judgment proportional to claim size, claim history, and coverage tier — document your reasoning." Instead of "15-day acknowledgment timer," write "acknowledge within the regulatory window for the relevant jurisdiction; default to the most conservative applicable standard; record which regulation governs this decision." The agent should reason about the applicable rule, not execute a cached value.

**Warning signs:**
- AGENTS.md contains numerical thresholds without context ("if X > Y then Z")
- AGENTS.md references specific state names as hard-coded conditions
- The system produces the same output regardless of what reasoning context you inject
- Team cannot explain what happens when the threshold changes

**Phase to address:**
Architecture design phase (before any agent workspace is written). Must be a founding design principle, not a retrofit.

**Severity:** CRITICAL — Direct judging criterion. The explicit rule is "plan for human reasoning: your thinking should not be hardcoded."

---

### Pitfall 2: No Working End-to-End Demo at Presentation Time

**What goes wrong:**
Team builds 6 beautiful agents but the pipeline is never fully wired together and tested. At demo time (18:30–20:00), the claim gets stuck between agents or the router fails. Team shows code instead of a running system. Judges see incompleteness. 50% of score (System Thinking) requires "it works end-to-end."

**Why it happens:**
Teams divide work by agent (person A does front-desk, person B does assessor, etc.) without establishing shared integration checkpoints. Each agent works in isolation. Integration is left for the last hour when fatigue is highest and fixes are slowest. Token budget for `sessions_spawn` runs out or the timeout is too short. State file schema drifts between agents because they were built independently.

**How to avoid:**
Run an end-to-end integration test **no later than Hour 5 (15:00)**. Build a `run-demo.sh` script in Hour 1 that submits a test claim and watches the pipeline, even before agents are complete. Test with stub agents first ("Front Desk: always succeeds, writes minimal JSON"). Add real logic incrementally, keeping the pipeline runnable at every step. Assign one team member as "integration owner" whose job is specifically keeping the pipeline connected and testable.

**Warning signs:**
- No script to submit a test claim and watch it flow
- "We'll integrate everything in the last hour"
- Team members' agents have different JSON schemas for the claim state
- Router spawning works but announce results are never arriving back

**Phase to address:**
Hour 1 (setup): create the integration harness. Hours 1–3 (Phase 1): first integration test with stub agents. Hours 5–7 (Phase 3): full pipeline test before adding polish.

**Severity:** CRITICAL — A non-working demo fails 50% of the judging criteria.

---

### Pitfall 3: OpenClaw `sessions_spawn` Context Loss

**What goes wrong:**
Sub-agents spawned via `sessions_spawn` only get `AGENTS.md` and `TOOLS.md` injected. They do NOT get `SOUL.md`, `IDENTITY.md`, `USER.MD`, `HEARTBEAT.md`, or `BOOTSTRAP.md`. Teams spend time crafting rich SOUL.md files for each agent and wonder why sub-agents behave inconsistently — all the personality and context they put in SOUL.md is invisible to the sub-agent at runtime.

**Why it happens:**
The OpenClaw docs make this easy to miss. Teams assume all workspace files are injected into sub-agent context, by analogy to how the main agent works. The documentation states this limitation in a sub-section of the Limitations block.

**How to avoid:**
Put ALL critical operating instructions in AGENTS.md. SOUL.md is only for main agent sessions. For sub-agents, use the task parameter in `sessions_spawn` to inject any extra context they need ("Process claim CLM-001. Coverage rules: [embed key rules here]. Write your reasoning explicitly."). Treat AGENTS.md as the only reliable injection surface for pipeline agents.

**Warning signs:**
- Sub-agents producing generic responses without domain context
- Sub-agents ignoring the persona or rules defined in SOUL.md
- Testing sub-agent directly works, but spawned versions behave differently

**Phase to address:**
Architecture design phase. Must inform how workspace files are structured from the start.

**Severity:** CRITICAL — Makes all agent personality/context configuration partly invisible at runtime.

---

### Pitfall 4: `maxSpawnDepth` Not Set — Router Cannot Spawn Pipeline Agents

**What goes wrong:**
The default `maxSpawnDepth` in OpenClaw is 1 — sub-agents cannot themselves spawn sub-agents. The intended architecture is: Main Agent (Router) → spawns pipeline agents. If the Router is itself a sub-agent (depth 1), it cannot spawn further agents. Teams configure the Router as a sub-agent of some process and then are surprised that `sessions_spawn` is blocked.

**Why it happens:**
The docs show `maxSpawnDepth: 2` as the orchestrator pattern enabler, but teams who skim docs miss this. They assume sub-agents can always spawn other sub-agents. The error is not obvious until the Router tries to spawn a pipeline agent and silently fails or returns a permissions error.

**How to avoid:**
Set `maxSpawnDepth: 2` explicitly in openclaw.json:
```json5
{
  agents: {
    defaults: {
      subagents: {
        maxSpawnDepth: 2,
        maxChildrenPerAgent: 6,
        maxConcurrent: 8
      }
    }
  }
}
```
The Router should be the main agent (depth 0), spawning pipeline agents at depth 1. Do not nest the Router as a sub-agent.

**Warning signs:**
- `sessions_spawn` calls silently fail or return permission errors
- Pipeline agents never announce results back
- Logs show depth violations

**Phase to address:**
Hour 0.5–1 (Architecture Planning) — the openclaw.json config must be correct before any code is written.

**Severity:** CRITICAL — Breaks the entire orchestrator pattern if missed.

---

### Pitfall 5: Shared State Race Conditions Between Parallel Agents

**What goes wrong:**
If multiple claims run concurrently and agents write to claim JSON files in a shared directory, two agents can simultaneously read a claim file, make changes, and overwrite each other. This is especially likely between Fraud Analyst and Assessor which may run in parallel. The audit log gets corrupted or steps are silently skipped.

**Why it happens:**
JSON files in a shared directory have no locking mechanism. Teams design the schema but don't implement atomic write patterns. Under demo conditions with one claim, this never triggers — but judges may ask "what if two claims come in simultaneously?" and the system will visibly fail if tested.

**How to avoid:**
Use claim-ID-namespaced files (one file per claim: `state/CLM-2026-00001.json`). Never write to the same file from two simultaneously running agents. If parallel stages are needed, have each write to their own section with atomic-append or let the Router coordinate sequential handoffs. For the hackathon, sequential pipeline (each agent must finish before the next starts) is safer than parallel and still demonstrates the architecture.

**Warning signs:**
- Multiple agents spawned simultaneously for the same claim
- Missing audit log entries
- Claim status set to an earlier state after a later agent writes

**Phase to address:**
Architecture design (schema design). Establish the write protocol rule: one active writer per claim at a time.

**Severity:** HIGH — Breaks demo reliability and undermines the audit trail that judges specifically look for.

---

### Pitfall 6: Over-Engineering the Architecture

**What goes wrong:**
Teams spend 3–4 hours designing a beautiful microservices-style pipeline with message queues, retry logic, dead-letter queues, and distributed state management. They run out of time to implement even 2 of the 6 agents. The demo shows architecture diagrams but no working code. Judges see ambition but no execution.

**Why it happens:**
Multi-agent systems invite architectural thinking. 3 engineers together will naturally want to design something impressive. The hackathon's framing ("build a pipeline") biases toward infrastructure thinking rather than working-product thinking.

**How to avoid:**
Use the YAGNI principle aggressively. For 10 hours: shared JSON files are the state store. Sequential pipeline is the concurrency model. The Router reads a file and spawns the next agent. That's it. No message queues. No retry infrastructure. No database. Every hour spent on infrastructure is an hour not spent on the business logic that judges actually score.

**Warning signs:**
- 90+ minutes into the hackathon and no agent has been tested yet
- Team discussing distributed systems patterns
- More time spent on config than on AGENTS.md content
- Database being installed on VPS

**Phase to address:**
Hour 0.5–1 (Architecture Planning) — decide on minimal shared-file approach and commit to it.

**Severity:** HIGH — Frequently kills hackathon teams. An hour-3 working MVP beats a beautiful unfinished design.

---

### Pitfall 7: Missing Insurance Compliance Knowledge That Judges Will Probe

**What goes wrong:**
Teams build a technically functional pipeline but cannot defend their decisions from a regulatory perspective. Judges ask: "What timeline does your Claims Officer agent enforce?" "What is the Fair Claims Settlement Practices Act?" "How do you handle bad faith allegations?" The team says "we simulate that" or gives a wrong answer. Business Thinking score collapses.

**Why it happens:**
Engineers trust their intuition about how claims "should" work. The insurance domain has very specific regulatory requirements that are counterintuitive to outsiders. For example: California requires acknowledgment within 15 calendar days. Acceptance or denial within 40 calendar days of proof of loss. Payment within 30 days of accepted claim. Missing even one of these makes the system non-compliant. Teams assume fraud detection is about finding "suspicious patterns" without knowing what patterns are legally actionable.

**How to avoid:**
The specific compliance items to bake into agent instructions before the hackathon:
- **FNOL acknowledgment:** 10–15 business days (state-dependent; default to 15 calendar days as conservative)
- **Claim decision:** 40 calendar days from proof of loss (California standard, conservative default)
- **Payment after acceptance:** 30 calendar days
- **Documentation retention:** minimum 5 years (varies by state)
- **Fair Claims Settlement Practices Act (UCSPA):** prohibits misrepresentation, unreasonable delays, good-faith requirement
- **Fraud patterns to detect:** staged accidents, phantom passengers, inflated repair estimates, prior damage claimed as new, VIN switching, paper accidents, "jump-in" claims
- **Total loss threshold:** typically 75% of ACV (actual cash value) — varies by state

**Warning signs:**
- AGENTS.md does not reference specific regulations by name
- The system makes claim decisions without recording the regulatory basis
- Team cannot answer "what happens if this takes 50 days?"

**Phase to address:**
Pre-hackathon research (now). Then bake into every relevant AGENTS.md before Feb 21.

**Severity:** HIGH — 50% of the score is Business Thinking. Regulatory ignorance fails this dimension.

---

### Pitfall 8: `agentDir` Reuse Causing Auth/Session Collisions

**What goes wrong:**
Multiple agents share the same `agentDir` path in openclaw.json, causing auth profile collisions. Session state from one agent bleeds into another. The Claims Officer might pick up the Front Desk's session history, producing nonsensical decisions. The issue is subtle and hard to debug under hackathon pressure.

**Why it happens:**
Teams copy-paste the agent configuration in openclaw.json and forget to change the `agentDir` field for each agent. The OpenClaw docs are explicit: "Never reuse `agentDir` across agents (it causes auth/session collisions)." But when building quickly, this is easy to miss.

**How to avoid:**
Each agent must have a unique `agentDir`:
```
~/.openclaw/agents/router/agent
~/.openclaw/agents/front-desk/agent
~/.openclaw/agents/claims-officer/agent
... etc
```
Use the `openclaw agents list` command to verify all agents have distinct paths before testing.

**Warning signs:**
- Two agents producing identical or swapped outputs
- Session history from one agent appearing in another
- `openclaw doctor` warnings about auth collisions

**Phase to address:**
Hour 0.5–1 — openclaw.json initial setup. Verify with `openclaw agents list --bindings` before proceeding.

**Severity:** HIGH — Causes subtle bugs that are very hard to diagnose mid-hackathon.

---

### Pitfall 9: Fraud Detection That Exposes Liability

**What goes wrong:**
Teams implement fraud detection that either (a) flags too aggressively, creating a system that would wrongly deny legitimate claims at a high rate, or (b) is so vague ("look for suspicious patterns") that it has no defensible business logic. Both versions lose Business Thinking points. The more dangerous version makes automatic denial decisions without a human-in-the-loop, which violates good-faith claims handling requirements.

**Why it happens:**
Fraud detection feels like a technical problem (pattern matching, scoring algorithms). Teams implement it as one without recognizing that insurance fraud detection is a legally constrained domain where false positives cost the company more than false negatives in some regulatory regimes.

**How to avoid:**
Design fraud detection as a **flag and escalate** system, not a **detect and deny** system. The Fraud Analyst agent raises a fraud score with documented reasoning and escalates to Senior Reviewer. The Senior Reviewer makes the human-in-the-loop decision. The Finance agent never pays without Senior Reviewer approval. This is both correct insurance practice and a stronger architectural story for judges.

**Warning signs:**
- Fraud Analyst agent has write access to "deny claim" status
- No human-in-the-loop in the fraud escalation path
- Fraud scoring thresholds are hard-coded numbers

**Phase to address:**
Architecture design + AGENTS.md authoring for Fraud Analyst and Senior Reviewer.

**Severity:** HIGH — Both a regulatory compliance failure and a Business Thinking scoring miss.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| No input validation on claim intake | Saves 30 min | Downstream agents fail with cryptic errors on malformed input | Never — add minimal required field checking in Front Desk |
| Sequential-only pipeline | Simple to reason about | Cannot handle concurrent claims | Acceptable for hackathon demo |
| No runTimeoutSeconds on sessions_spawn | One less config | Stuck agents block forever if they hang | Set 120s minimum — 2 minutes is enough to detect failures |
| Hardcoded model in each sessions_spawn | Quick to write | Cannot upgrade centrally | Use `agents.defaults.subagents.model` instead |
| SOUL.md-heavy persona configuration | Rich personality | SOUL.md not injected in sub-agents — persona lost | Put all operating-critical content in AGENTS.md only |
| Skip cleanup: "delete" on sessions_spawn | Simplifies | Transcript gone immediately, hard to debug failures | Use `cleanup: "keep"` during hackathon |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| sessions_spawn | Assuming it blocks until complete | It returns immediately (`status: "accepted"`); result comes via announce |
| Agent-to-agent messaging | Enabling without explicit allowlist | Set `tools.agentToAgent.enabled: true` + `allow: ["router", "front-desk", ...]` explicitly |
| Shared claim state files | Agents constructing their own file paths | Use absolute paths from a shared schema; relative paths resolve to agent workspace root |
| VPS deployment | Copying openclaw.json to VPS without `agentDir` adjustments | Paths are host-relative; test full deployment from fresh VPS state before hackathon day |
| Model selection | Using `claude-opus-4-6` for every agent | Sub-agents accumulate token cost fast; use Sonnet for simpler agents (Assessor, Front Desk), Opus only for Senior Reviewer |

---

## Performance Traps

Patterns that work at small scale but fail during demo.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No timeout on sessions_spawn | One bad agent hangs pipeline forever | Set `runTimeoutSeconds: 120` on all spawns | Immediately when an agent gets stuck |
| All agents using Opus model | Slow pipeline, high token cost | Use model tiers; Sonnet for simple agents | When running 2+ claims simultaneously |
| Large AGENTS.md files | Injected at every session start, token burn | Keep each AGENTS.md under 2000 characters; `bootstrapMaxChars` default is 20000 | Not at demo scale, but wastes budget |
| claim.json grows unbounded | Audit log fills entire file with each step | Cap audit log at last 20 entries, or use append-only log file | After 10+ test runs on same claim |
| Demo running 5+ claims simultaneously | maxChildrenPerAgent (default 5) exceeded | For demo, run one claim at a time sequentially | When judge asks "show me parallel claims" |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Finance agent has read/write access to all agent workspaces | Any agent that writes to Finance workspace can trigger payment | Finance agent tools: `allow: ["read", "write"]` scoped to its own workspace only; deny exec |
| No audit trail on who triggered payment | Cannot demonstrate regulatory compliance | Every Finance agent action must log: agent ID, claim ID, amount, authorization chain, timestamp |
| Senior Reviewer can be bypassed | Fraud-flagged claims paid without review | Router must check fraud_analyst status before spawning Finance; Finance must verify senior_reviewer.approved === true |
| Shared `agentDir` exposes auth tokens across agents | Auth compromise of one agent exposes all | Unique agentDir per agent (see Pitfall 8) |
| Broad tool allowlist on Finance agent | Finance could exec arbitrary commands | Finance: `allow: ["read", "write"]`, `deny: ["exec", "browser", "gateway", "cron"]` explicitly |

---

## UX Pitfalls

Common user experience mistakes in the demo context.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing logs during demo | Judges see walls of text, not business value | Prepare a clean summary view: claim status, current stage, key decisions |
| Demo claim too boring ("fender bender, approved") | Doesn't exercise fraud or escalation paths | Prepare 3 demo claims: happy path, fraud flag + escalation, coverage denial |
| Showing code during 5-minute presentation | Judges lose the business narrative | Show the system running, not the code powering it |
| Not explaining what each agent is deciding | System looks like a black box | Live narrate decisions as they happen: "Fraud Analyst just flagged phantom passenger pattern" |
| Demo depends on live internet/API call | Network failure during presentation | Pre-run one demo claim and have the output ready as backup |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Audit Trail:** Each agent writes its reasoning to the audit_log in the claim JSON — verify the log captures decisions, not just status changes
- [ ] **Fraud Escalation Path:** Fraud Analyst raises flag, Senior Reviewer gets escalation, Finance never pays without Senior Reviewer approval — verify the chain is enforced in the Router
- [ ] **Regulatory Acknowledgment Timing:** Front Desk must record the claim receipt timestamp; Claims Officer must reference it when making timeline decisions
- [ ] **Coverage Denial Path:** Not all claims get approved — verify the pipeline handles "no coverage" and terminates cleanly with a documented reason
- [ ] **Tool Scoping:** Finance agent cannot spawn sub-agents, cannot exec, cannot reach browser — verify deny lists are actually working with a test
- [ ] **maxSpawnDepth Config:** Verify `maxSpawnDepth: 2` is set and that the Router (depth 0) can spawn pipeline agents (depth 1) — test before the hackathon begins
- [ ] **AGENTS.md Sub-Agent Content:** All critical operating instructions are in AGENTS.md, not SOUL.md — verify by reading sub-agent announce output and checking for personality/context presence
- [ ] **Secret Addition Flexibility:** Each agent's AGENTS.md references "current applicable policy" rather than hardcoded values — verify one agent can change behavior when given a new policy context via task injection

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| End-to-end pipeline broken at Hour 8 | HIGH | Simplify: remove one agent, make Router call remaining agents directly; reduce to 4-agent demo rather than 6 |
| sessions_spawn silently failing | MEDIUM | Check maxSpawnDepth config; check agents_list to see which agentIds are spawnable; add explicit error handling in Router task |
| Shared state corruption | MEDIUM | Reset claim to a clean JSON template; establish write protocol rule (one agent per claim at a time); use timestamped backup files |
| Demo claim hangs during presentation | LOW | Kill session (`/subagents kill all`); restart with pre-prepared backup output; narrate what "would have happened" |
| Wrong agentDir collision | MEDIUM | Run `openclaw agents list --bindings` to identify collisions; update openclaw.json; restart gateway |
| Secret addition breaks architecture | MEDIUM | Acknowledge in presentation: "The secret addition required us to add X"; explain how your flexible design handled it; even partial adaptation scores well |

---

## Pitfall-to-Phase Mapping

How hackathon phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Hardcoded rules | Pre-hackathon (AGENTS.md authoring) | Read AGENTS.md aloud and count hardcoded thresholds — should be zero |
| No working demo | Hour 1 (integration harness) + Hour 5 (full test) | `run-demo.sh CLM-TEST-001` produces complete audit log in under 5 minutes |
| sessions_spawn context loss (SOUL.md) | Architecture design (Hour 0.5–1) | Spawn a sub-agent, read its output — does it reference AGENTS.md content? |
| maxSpawnDepth not set | Config setup (Hour 0.5–1) | Router spawns one sub-agent; it succeeds |
| Shared state race conditions | Schema design (Hour 0.5–1) | Two simultaneous claims produce two distinct, uncorrupted JSON files |
| Over-engineering | Hour 0.5–1 (commit to minimal architecture) | Every 90 minutes: "do we have something working we could demo right now?" |
| Missing compliance knowledge | Pre-hackathon research (today) | Can team answer "what regulation governs your 15-day timer?" without looking it up? |
| agentDir reuse | Config setup (Hour 0.5–1) | `openclaw agents list` shows unique agentDir per agent |
| Fraud detection without human-in-loop | Architecture design | Trace fraud-flagged claim through pipeline — Finance cannot proceed without Senior Reviewer flag |
| Weak demo narrative | Hour 8.5–10 (demo prep) | 5-minute dry run with someone who hasn't seen the system — do they understand what's happening? |

---

## Sources

- OpenClaw documentation (local reference): `/reference/openclaw-docs/tools/subagents.md` — sub-agent context injection limits, maxSpawnDepth, tool policy by depth
- OpenClaw documentation (local reference): `/reference/openclaw-docs/concepts/multi-agent.md` — agentDir isolation, workspace scope, auth profile collision
- OpenClaw documentation (local reference): `/reference/openclaw-docs/tools/multi-agent-sandbox-tools.md` — tool filtering order, "non-main" sandbox pitfall, per-agent restrictions
- OpenClaw documentation (local reference): `/reference/openclaw-docs/concepts/agent-workspace.md` — workspace file map, what sub-agents do and don't receive
- MAST (Multi-Agent System Failure Taxonomy), ICLR 2025 Workshop — empirical failure modes in multi-agent LLM systems including specification issues, reasoning-action mismatch, task verification failures
- California Fair Claims Settlement Practices Regulations (CCR Title 10, Sections 2695.1–2695.14) — 15-day acknowledgment, 40-day decision, 30-day payment timelines
- rxhistories.com — "Top 5 Mistakes in Building Claims AI for P&C Insurance" — domain expertise gap, hardcoded rules accumulation, workflow misalignment
- digiqt.com — "AI Agents in Insurance: Critical Pitfalls" — integration complexity, unrealistic expectations, deepfake fraud as emerging vector
- towardsdatascience.com — "Why Your Multi-Agent System is Failing" — flat topology problems, hallucination loops without orchestrator
- Hackathon execution patterns — automateathon.com, mojoauth.com hackathon guide — demo-driven development, last-hour integration failure pattern, demo prep allocation (typically 16–20% of time)
- mathco.com — "Transforming Health Insurance with AI Claims Automation" — hardcoded rules vs policy reasoning distinction
- Hackathon challenge brief (local): `/reference/hackathon-challenge.md` — judging criteria, secret addition timing, pipeline requirements

---

*Pitfalls research for: Multi-agent auto insurance claims processing — OpenClaw Business Engineering Hackathon*
*Researched: 2026-02-17*
