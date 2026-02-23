# Day-of Timeline -- Feb 21, 2026

Hour-by-hour execution plan for 3 team members from 9:00 arrival through 20:00 presentation. Every half-hour block assigns each member a named deliverable. No coordination overhead -- follow the plan.

**Members:**
- **Member A:** Router + Infrastructure owner (Workstream A)
- **Member B:** Front Desk + Claims Officer + Policies owner (Workstream B)
- **Member C:** Assessor + Fraud Analyst + Senior Reviewer + Finance owner (Workstream C)

**See also:** [team-work-split.md](team-work-split.md) for workstream details, [integration-checkpoints.md](integration-checkpoints.md) for checkpoint protocol.

---

## 9:00 - 10:00 | Setup Hour (All 3 Members)

*Arrive early before the 10:00 official start. Environment must be ready before the clock starts.*

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 9:00-9:15 | VPS provisioning: run `setup.sh` on the Hetzner VPS, verify Docker + OpenClaw gateway starts | Git clone repo on VPS, verify directory structure exists (`shared/`, `workspaces/`, `scripts/`) | Set up local environment: editor, terminal, SSH tunnel to VPS for each member |
| 9:15-9:30 | Configure `.env` with Anthropic API key, verify gateway health check passes (`curl localhost:18789/health`) | Deploy `openclaw.json` to VPS, verify 7 agents registered | Deploy `claim.schema.json` to `shared/schemas/`, deploy 5 policy JSON files to `shared/policies/` |
| 9:30-9:45 | Deploy test claim files to `shared/test-claims/`, verify scripts are executable (`chmod +x scripts/*.sh`) | Verify `submit-claim.sh` can trigger Router (dry run or quick test) | Deploy `.env.example`, verify all shared directory paths match architecture spec |
| 9:45-10:00 | Buffer: troubleshoot any setup issues. Gateway must be healthy. | Buffer: verify all policy files are valid JSON (`jq . shared/policies/*.json`) | Buffer: verify schema file is valid JSON, test claims parse correctly |

**Exit criteria:** Gateway healthy on port 18789. All 7 agent workspaces exist (empty AGENTS.md files or placeholder). Shared directory structure complete. All scripts executable.

---

## 10:00 - 10:30 | Secret Addition Revealed (All 3 Members)

*Official start. Secret addition announced. All 3 members collaborate.*

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 10:00-10:10 | Read secret addition together. Discuss as a team: what does it change? | Read secret addition together. Which agents are affected? | Read secret addition together. Does it affect the pipeline flow? |
| 10:10-10:20 | Decide adaptation approach (see 04-02 secret addition framework). Determine which AGENTS.md files need modification. | Note which Front Desk / Claims Officer behavior changes | Note which Assessor / Fraud Analyst / Senior Reviewer / Finance behavior changes |
| 10:20-10:30 | Update Router AGENTS.md plan if pipeline flow changes. Document adaptation in shared scratchpad. | Plan AGENTS.md modifications for their agents | Plan AGENTS.md modifications for their agents |

**Exit criteria:** Team has a clear plan for how secret addition affects each agent. Each member knows what to add/change in their AGENTS.md files. Adaptation notes written down.

---

## 10:30 - 13:00 | Parallel Build Block 1 (Split into Workstreams)

*This is the core build window. Members work independently on their assigned agents.*

### 10:30 - 11:30

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 10:30-11:00 | **Type Router AGENTS.md** (Part 1): Role identity, state machine definition, sequential spawn protocol | **Type Front Desk AGENTS.md** (Full): Role identity, FNOL processing checklist, categorization, priority framework, completeness assessment, domain knowledge, output format, announce protocol | **Type Assessor AGENTS.md** (Part 1): Role identity, damage assessment methodology, total loss framework, parts recommendation criteria |
| 11:00-11:30 | **Type Router AGENTS.md** (Part 2): Task message construction templates, error handling, retry policy, escalation protocol, audit logging, regulatory context injection | **Type Claims Officer AGENTS.md** (Full): Role identity, policy lookup protocol, coverage verification, exclusion analysis, denial documentation, UM/UIM routing, domain knowledge, output format, announce protocol | **Type Assessor AGENTS.md** (Part 2): Pre-existing damage detection, photo analysis protocol, domain knowledge, output format, announce protocol. Integrate secret addition if applicable. |

### 11:30 - 12:30

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 11:30-12:00 | **Router AGENTS.md complete.** Test Router can start (verify gateway accepts it). Begin integration testing: try spawning Front Desk if Member B has it ready. | **Front Desk + Claims Officer AGENTS.md complete.** Signal Member A: "Front Desk ready for integration." Verify policy files load correctly for Claims Officer. | **Type Fraud Analyst AGENTS.md** (Full): Role identity, fraud pattern catalog (all 7 patterns), indicator convergence framework, risk scoring, soft vs hard fraud, SIU referral, cross-reference analysis, domain knowledge, output format, announce protocol |
| 12:00-12:30 | **Integration pre-test:** Attempt to spawn Front Desk via Router for a test claim. Debug any spawn failures. If Front Desk works, try Claims Officer. | **Help Member A debug** if Front Desk integration fails. Otherwise: review and polish both AGENTS.md files. Add secret addition modifications. | **Fraud Analyst AGENTS.md complete.** Begin **Senior Reviewer AGENTS.md**: Role identity, evidence weighing framework, decision criteria (APPROVED/DENIED/CONDITIONAL/ESCALATE_HUMAN), FCSP timeline compliance |

### 12:30 - 13:00

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 12:30-13:00 | **Prepare for Checkpoint 1.** Verify Router can spawn Front Desk successfully. Document any issues found. | **Prepare for Checkpoint 1.** Ensure Claims Officer is ready if possible. Have Front Desk definitely working. | **Senior Reviewer AGENTS.md** (Part 2): Bad faith risk assessment, escalation judgment, domain knowledge, output format, announce protocol. Senior Reviewer complete. |

**Exit criteria:** Router AGENTS.md typed and deployed. Front Desk AGENTS.md typed and deployed. Claims Officer AGENTS.md typed and deployed. Assessor AGENTS.md typed and deployed. Fraud Analyst AGENTS.md typed and deployed. Senior Reviewer AGENTS.md typed and deployed. Router can spawn at least Front Desk.

---

## 13:00 - 13:30 | INTEGRATION CHECKPOINT 1 -- Pipeline Skeleton

*All 3 members stop work and participate. Member A leads. See [integration-checkpoints.md](integration-checkpoints.md) for full protocol.*

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 13:00-13:15 | **Lead checkpoint:** Submit happy-path test claim via `submit-claim.sh`. Verify Router spawns Front Desk. Check Front Desk output in claim JSON. | **Support:** Monitor Front Desk output. Debug if categorization/priority missing. | **Support:** Observe pipeline flow. Note any patterns relevant to later agents. |
| 13:15-13:30 | If Front Desk works: test Claims Officer spawn. Verify coverage check runs. | **Debug Claims Officer** if spawn fails. Check policy file path, exclusion analysis. | **If time:** Quick test of Assessor spawn (may not have all dependencies yet). |

**Pass criteria:** Router spawns Front Desk. Front Desk writes valid pipeline section with category, priority, completed_at. If Claims Officer ready: coverage check runs with covered=true.

**Fail action:** See [integration-checkpoints.md](integration-checkpoints.md) rollback strategies. Fix the failing component. Max 30 minutes on checkpoint.

---

## 13:30 - 15:00 | Parallel Build Block 2 (Continue Workstreams)

### 13:30 - 14:30

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 13:30-14:00 | **Fix any Checkpoint 1 issues.** If clean: test Router spawning Claims Officer, Assessor (as they become ready). Iteratively integrate each agent. | **Fix any Checkpoint 1 issues** for Front Desk / Claims Officer. If clean: polish AGENTS.md, add edge case handling, integrate secret addition. | **Type Finance AGENTS.md** (Full): Role identity, payment calculation, deductible application, depreciation methodology, subrogation assessment, payment method, domain knowledge, output format, announce protocol |
| 14:00-14:30 | **Continue integration:** Test Assessor + Fraud Analyst spawns as Member C completes them. Each successful spawn = one more pipeline stage verified. | **All agents complete.** Help Member A with integration testing. Run Claims Officer with different policy scenarios (lapsed, excluded driver). | **Finance AGENTS.md complete.** All 4 agents typed. Signal Member A: "Assessor, Fraud Analyst, Senior Reviewer, Finance all ready." Help with integration testing. |

### 14:30 - 15:00

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 14:30-15:00 | **Prepare for Checkpoint 2.** Attempt full pipeline run: happy-path claim through all 6 stages. Document which stages pass and which fail. | **Support full pipeline test.** Monitor Claims Officer behavior during end-to-end run. | **Support full pipeline test.** Monitor Assessor, Fraud Analyst, Senior Reviewer, Finance during end-to-end run. Debug failures in their agents. |

**Exit criteria:** All 7 AGENTS.md files typed and deployed. Router has been tested spawning each agent at least once. Ready for full pipeline test.

---

## 15:00 - 15:30 | INTEGRATION CHECKPOINT 2 -- Full Pipeline

*All 3 members stop work. Member A leads. See [integration-checkpoints.md](integration-checkpoints.md) for full protocol.*

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 15:00-15:15 | **Lead checkpoint:** Run `./scripts/run-demo.sh happy-path-collision`. Monitor pipeline progress. Check final status = PAYMENT_ISSUED. | **Monitor** stages 1-2 (Front Desk, Claims Officer) during full pipeline run. | **Monitor** stages 3-6 (Assessor, Fraud Analyst, Senior Reviewer, Finance) during full pipeline run. |
| 15:15-15:30 | Verify: audit_log has 6+ entries, all pipeline sections have completed_at, finance has payment_amount > 0. | **Debug** any failure in stages 1-2. | **Debug** any failure in stages 3-6. |

**Pass criteria:** Happy path claim reaches PAYMENT_ISSUED with complete audit trail. All 6 pipeline sections populated.

**Fail action:** Isolate failing agent. See [integration-checkpoints.md](integration-checkpoints.md) rollback strategies. Priority: fix the specific failing agent. If time pressure: temporarily skip the failing stage in Router and come back.

---

## 15:30 - 17:00 | Integration, Secret Addition, Polish

### 15:30 - 16:30

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 15:30-16:00 | **Fix any Checkpoint 2 failures.** If clean: run fraud-flag scenario (`run-demo.sh fraud-flag`). Verify ESCALATED status and SIU referral. | **SECRET ADDITION INTEGRATION:** Apply secret addition changes to Front Desk and Claims Officer AGENTS.md. Test with a claim that exercises the secret addition. | **SECRET ADDITION INTEGRATION:** Apply secret addition changes to Assessor, Fraud Analyst, Senior Reviewer, Finance AGENTS.md. Test individual agent behavior. |
| 16:00-16:30 | **Run no-coverage scenario** (`run-demo.sh no-coverage`). Verify DENIED status and denial shortcut (skips Assessor/Fraud/Finance). Test all 3 scenarios work. | **Help test secret addition** end-to-end. Verify secret addition claim flows through entire pipeline correctly. | **Help test secret addition** end-to-end. Debug any issues in later pipeline stages with secret addition. |

### 16:30 - 17:00

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 16:30-17:00 | **Run all 3 scenarios** (`run-demo.sh --all`). All must reach terminal status. Capture output for backup. | **Polish AGENTS.md files.** Ensure all domain knowledge is embedded, audit log reasoning is thorough. | **Polish AGENTS.md files.** Ensure fraud patterns, assessment methodology, and financial calculations produce convincing audit trail. |

**Exit criteria:** All 3 test scenarios reach correct terminal status. Secret addition integrated and tested. AGENTS.md files polished.

---

## 17:00 - 18:00 | Demo Preparation

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 17:00-17:30 | **Run all 3 test scenarios** one final time. Capture complete claim JSON output files for backup display. Save to `shared/backup-outputs/`. | **Review audit logs** from all 3 scenarios. Ensure the reasoning text is judge-worthy -- clear, domain-aware, regulatory-conscious. | **Review claim JSON output** for all 3 scenarios. Ensure financial calculations are correct, fraud flags make sense, decisions are well-reasoned. |
| 17:30-18:00 | **Prepare demo environment.** Clean state directory. Have submit command ready. Know the exact sequence of commands for live demo. | **Draft talking points** for pipeline stages 1-2 (what to say as Front Desk and Claims Officer run). | **Draft talking points** for pipeline stages 3-6 (what to say as Assessor, Fraud Analyst, Senior Reviewer, Finance run). |

**Exit criteria:** Backup outputs saved. Demo commands tested and ready. Each member knows their talking points.

---

## 18:00 - 19:00 | Presentation Polish

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 18:00-18:30 | **Rehearse 5-min presentation** (see 04-03 demo script). Practice the full flow: problem setup, architecture, live demo, secret addition framing. Time it. | **Rehearse their section** of the presentation. Practice explaining business logic and domain knowledge to judges. | **Rehearse their section** of the presentation. Practice explaining agent reasoning and decision-making to judges. |
| 18:30-19:00 | **Q&A practice** (see 04-04 Q&A defense). Team quizzes each other on: Why this architecture? Why these agents? What about [edge case]? How does [regulatory requirement] work? | **Q&A practice:** Focus on business thinking questions -- FCSP Act, bad faith, coverage disputes, claim denial justification. | **Q&A practice:** Focus on system thinking questions -- agent isolation, tool scoping, state management, error handling, model selection. |

**Exit criteria:** Presentation rehearsed and timed at 5 minutes or less. Team can answer anticipated Q&A questions confidently.

---

## 19:00 - 20:00 | Buffer and Presentation

| Time | Member A | Member B | Member C |
|------|----------|----------|----------|
| 19:00-19:30 | **Final checks.** One last test run if needed. Verify backup outputs are accessible. Check gateway is still healthy. | **Final review** of talking points. Calm down. Stay sharp. | **Final review** of talking points. Have backup output files ready to screen-share if live demo fails. |
| 19:30-20:00 | **PRESENT.** Lead the demo: show architecture, run live claim, narrate the pipeline. | **PRESENT.** Explain business logic: why these decisions, what regulations, how domain expertise shows. | **PRESENT.** Explain system thinking: agent design, tool scoping, error handling, secret addition adaptation. |

**Exit criteria:** Presentation delivered. Questions answered. Done.

---

## Quick Reference: Agent Assignments

| Agent | Member | Workstream | Build Window |
|-------|--------|------------|--------------|
| Router | A | A (Router + Infra) | 10:30-11:30 |
| Front Desk | B | B (Front Desk + Claims Officer) | 10:30-11:30 |
| Claims Officer | B | B (Front Desk + Claims Officer) | 10:30-11:30 |
| Assessor | C | C (Assessor + Fraud + SR + Finance) | 10:30-11:30 |
| Fraud Analyst | C | C (Assessor + Fraud + SR + Finance) | 11:30-12:30 |
| Senior Reviewer | C | C (Assessor + Fraud + SR + Finance) | 12:00-13:00 |
| Finance | C | C (Assessor + Fraud + SR + Finance) | 13:30-14:00 |

---

*Day-of timeline for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
