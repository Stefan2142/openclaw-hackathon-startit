# Q&A Defense Document

Prepared answers for every anticipated judge question at the OpenClaw Business Engineering Hackathon. Organized into 3 categories matching the judging criteria: Business Justification, Architecture Decisions, and Regulatory Knowledge.

**Usage:** Each question has a concise spoken answer (2-3 sentences for delivery) and a deep dive section with supporting evidence and artifact references for follow-up questions. The team member answering should deliver the concise answer first, then offer "I can go deeper on that if you'd like" before diving into the references.

---

## Category 1: Business Justification (50% of Judging)

### Q1: "Why 6 pipeline agents instead of 1 or 2?"

**Concise answer:** Each agent maps to a real insurance role -- an intake clerk does not do fraud analysis, and a fraud analyst does not calculate payments. Separating concerns means each agent has focused domain knowledge and scoped tools following least-privilege security, and the system mirrors how real insurance companies operate. If we merged agents, we would lose the audit trail granularity that regulators require -- every decision needs to be independently traceable to the function that made it.

**Deep dive:**
- Decision log entry #8 documents the tool scoping rationale -- each agent gets exactly the tools it needs and nothing more
- `docs/agent-documentation.md` has a "Why It Exists as a Separate Agent" section for each of the 7 agents with specific separation-of-concerns arguments
- Real insurance companies have distinct roles: intake clerk, coverage analyst, damage appraiser, SIU analyst, senior adjuster, disbursement officer -- our pipeline mirrors this organizational structure
- Merging the Fraud Analyst with the Assessor would mean the same agent checks its own work for fraud -- a conflict of interest
- Merging the Senior Reviewer with Finance would eliminate the dual-control principle (authorization separated from execution)

---

### Q2: "How does fraud detection work?"

**Concise answer:** The Fraud Analyst uses indicator convergence -- it evaluates 7 named fraud patterns and looks for patterns that converge rather than checking single rules. A single flag is noted; converging indicators from multiple patterns trigger an SIU referral. Critically, the Fraud Analyst flags and recommends -- it never denies claims. That authority belongs to the Senior Reviewer.

**Deep dive:**
- `reference/domain-knowledge/fraud-detection.md` Quick Reference table lists all 7 patterns: staged accidents, phantom passengers, paper accidents, inflated repairs, prior damage/VIN switching, owner give-up, organized fraud rings
- The indicator convergence framework is described in fraud-detection.md Section 3 -- single indicator = note, multiple from same pattern = flag, multiple patterns converging = escalation
- Hard fraud vs soft fraud distinction changes the response entirely: hard fraud = deny + SIU referral, soft fraud = negotiate reduced settlement + pay legitimate portion
- Anti-pattern warnings in fraud-detection.md Section 6: never auto-deny based on score alone (bad faith violation), never use hardcoded thresholds (hackathon disqualification), always document which patterns were evaluated even when no indicators found
- Fraud statistics for Q&A: $308.6B annual cost, staged accidents up 47% (Aviva 2024), ~10% of P&C claims have fraud element

---

### Q3: "How do you handle compliance?"

**Concise answer:** Compliance is structural, not bolted on. The Router injects FCSP timeline context into every agent's task message. The Senior Reviewer checks timeline compliance before every decision. The audit log captures every agent's reasoning with regulation references. The system cannot skip a compliance check because the pipeline architecture enforces it.

**Deep dive:**
- `reference/domain-knowledge/regulatory-compliance.md` documents three FCSP timelines: 10-15 day acknowledgment, 40-day coverage decision, 30-day payment after acceptance
- The Router constructs context-enriched task messages (documented in `docs/agent-documentation.md` Router section) that include regulatory context for each stage
- The Senior Reviewer's decision framework (agent-documentation.md Agent 6) explicitly includes FCSP timeline verification as step 2 of 6 in its decision process
- Every audit log entry includes timestamp, agent, action, reasoning, and regulation references -- this creates the documentation trail that satisfies the 5-year retention requirement
- Bad faith prevention is described in regulatory-compliance.md Section 3 with 8 specific triggers the system is designed to prevent

---

### Q4: "What happens when a claim is denied?"

**Concise answer:** The Claims Officer identifies the coverage issue, and the pipeline shortcuts -- it skips damage assessment, fraud analysis, and payment, going directly to the Senior Reviewer. The Senior Reviewer documents why the denial is defensible, assesses bad faith risk, and confirms the denial. This shortcut saves processing time while still protecting the insurer from bad faith claims.

**Deep dive:**
- Decision log entry #13 documents the coverage denial shortcut rationale: no point assessing damage or analyzing fraud on uncovered claims, but every denial still needs supervisory review
- `docs/ARCHITECTURE.md` Section 2 includes a dedicated "Denial Path" diagram showing the shortcut flow
- The Claims Officer documents the specific policy provision that supports the denial (not just "excluded") -- this is a FCSP requirement documented in regulatory-compliance.md
- The Senior Reviewer's denial review includes bad faith risk assessment, ambiguity doctrine check, and FCSP compliance verification
- The denial walkthrough (CLM-2026-00003 in demo-walkthroughs.md) shows this path in action: Front Desk, Claims Officer, Senior Reviewer -- three agents processed, three skipped

---

### Q5: "How do you handle edge cases like total loss or pre-existing damage?"

**Concise answer:** Each edge case is handled by reasoning principles embedded in the relevant agent. The Assessor knows Ohio's 100% ACV total loss threshold and flags pre-existing damage for the Fraud Analyst. The Senior Reviewer escalates to human review when edge cases exceed the system's confidence. We documented 10 categories of edge cases during preparation.

**Deep dive:**
- `reference/domain-knowledge/edge-cases.md` catalogs 10 edge case categories with "What It Is," "Why Judges Might Ask," "What the System Does," and a one-sentence answer for each
- Ohio's total loss threshold: 100% ACV (one of the stricter thresholds -- most states use 70-80%)
- Total loss payout: ACV minus deductible, with salvage retention option and GAP insurance awareness
- Pre-existing damage: Assessor flags indicators (rust on fresh damage, paint oxidation, damage in non-impact zones), then Fraud Analyst cross-references these flags against the inflated repair and prior damage patterns
- Cross-cutting edge cases documented: total loss + GAP + rental, CAT event + pre-existing + fraud, multi-vehicle + UM/UIM, supplements + rental extension, legal representation + denial

---

### Q6: "What if the system makes a wrong decision?"

**Concise answer:** Every decision is logged with reasoning in the audit trail. The Senior Reviewer acts as a safety net before any payment or denial. High-risk claims -- fraud flags, significant value, total loss, legal representation -- are escalated to human review. The system is designed to be conservative: it escalates rather than guesses.

**Deep dive:**
- `docs/ARCHITECTURE.md` Section 2 documents the Escalation Path with 7 reasoning-based triggers (no hardcoded thresholds)
- `architecture/human-in-the-loop.md` (referenced in architecture) describes 4 human resolution types: approve, deny, modify, investigate
- The Senior Reviewer is the ONLY decision authority -- 4 possible outcomes: APPROVED, DENIED, CONDITIONAL, ESCALATE_HUMAN (documented in agent-documentation.md Agent 6)
- Finance has a HARD CONSTRAINT: never pay without Senior Reviewer approval (APPROVED or CONDITIONAL only)
- The escalation record is written by the Router (not the pipeline agent) to include full pipeline context: stages completed, stages remaining, time in pipeline, regulatory deadline proximity (Decision #15)
- Bad faith awareness embedded: denying a legitimate claim carries worse consequences than paying a marginal one

---

### Q7: "What's the business value of this system?"

**Concise answer:** Three outcomes demonstrate value: the happy path processes a claim in minutes with a complete audit trail instead of weeks with scattered paperwork; the fraud detection catches converging indicators a human might miss reviewing each in isolation; and the denial path protects the insurer from bad faith exposure with documented reasoning on every decision. Each outcome saves money, reduces risk, and satisfies regulators.

**Deep dive:**
- Happy path (CLM-2026-00001): 6 agents, full audit trail, subrogation recovery identified -- the system recovers costs from the at-fault party's insurer
- Fraud detection (CLM-2026-00002): 4 converging fraud patterns detected that individual reviewers might miss -- $308.6B annual fraud cost to the industry
- Coverage denial (CLM-2026-00003): 3 stages skipped (token/time savings), bad faith assessment still performed, denial documentation ready for regulatory audit
- FCSP compliance: automated timeline tracking prevents the delay-based bad faith triggers that cost insurers millions in litigation
- Scalability: different claims process in parallel (each has its own file), even though individual claims process sequentially

---

## Category 2: Architecture Decisions (50% of Judging)

### Q8: "Why JSON files instead of a database?"

**Concise answer:** For a 10-hour hackathon, every minute of infrastructure setup is a minute not spent on business logic. JSON files are zero-setup, human-readable during the demo -- judges can cat the file -- and natively compatible with OpenClaw's read/write tools. The sequential pipeline guarantees single-writer-per-claim, so we do not need locking. For production, we would migrate to SQLite or Postgres.

**Deep dive:**
- Decision log entry #1 documents the full decision matrix: PostgreSQL (30+ min setup, connection config, migrations), SQLite (library dependency, schema management), JSON files (zero dependencies)
- The sequential pipeline pattern (Decision #5) guarantees single-writer-per-claim, eliminating the need for file locking or transactions
- Demo legibility: `cat shared/state/claims/CLM-2026-00001.json` shows judges every field written by every agent in real time
- Git-trackable: claim files can be version-controlled for development debugging
- Native to OpenClaw: agents use the built-in `read` and `write` tools directly on JSON files -- no ORM, no driver, no connection pool

---

### Q9: "Why sequential pipeline instead of parallel?"

**Concise answer:** Correctness requires it. Fraud analysis needs the damage estimate to detect inflated repair claims. The Senior Reviewer needs the fraud score to decide. Payment needs the approval. Parallelizing would either require complex synchronization or produce incorrect results. Sequential is simple, correct, and easy to debug.

**Deep dive:**
- Decision log entry #5 documents the correctness argument with specific dependency chains
- The Fraud Analyst reads `pipeline.assessor.repair_estimate_usd` and `pipeline.assessor.pre_existing_damage_flags` -- these fields do not exist until the Assessor completes
- Coverage denial shortcuts the pipeline (stages 3, 4, 6 skipped) -- this branching logic is only possible with sequential execution where the Router can decide the next step based on the previous step's output
- Single-writer-per-claim eliminates all race conditions. No file locking, no conflict resolution, no partial writes
- For multiple claims: different claims CAN process in parallel (each has its own JSON file). Sequential applies within a single claim only.

---

### Q10: "How does state management work between agents?"

**Concise answer:** Every claim is a single JSON file. Each agent reads the file, writes to its pipeline section, and appends an audit log entry. The Router validates the output after each agent completes. This gives us a complete state snapshot at every point in the pipeline -- if something breaks, we can see exactly where and why.

**Deep dive:**
- `shared/schemas/claim.schema.json` defines 88 fields across all sections, providing a strict contract between agents
- The claim JSON has 6 pipeline sections (one per agent) plus the audit_log array -- each agent writes ONLY to its own section (enforced by AGENTS.md instructions)
- The Router performs output validation between every stage (documented in ARCHITECTURE.md Section 2): checks that required fields are populated and well-formed before advancing the state machine
- Decision #14: Router owns all status transitions -- pipeline agents write their section data but do NOT change the top-level `status` field. This prevents inconsistent state from partial agent failures.
- Decision #7: `agentToAgent` disabled -- all communication flows through the claim JSON + Router mediation, preserving complete audit trail

---

### Q11: "Why Opus for some agents and Sonnet for others?"

**Concise answer:** Cost optimization without quality sacrifice. Agents doing complex reasoning -- Assessor, Fraud Analyst, Senior Reviewer, Router -- use Opus. Agents doing structured data tasks -- Front Desk, Claims Officer, Finance -- use Sonnet. This cuts token cost roughly in half while keeping quality where it matters.

**Deep dive:**
- Decision log entry #2 documents the model tiering rationale with per-agent justification
- OpenClaw docs recommend: "set a cheaper model for sub-agents and keep your main agent on a higher-quality model" -- we go further with per-agent optimization
- Opus assignments: Router (complex orchestration + error recovery), Assessor (multi-category damage estimation from descriptions), Fraud Analyst (adversarial pattern recognition from incomplete data), Senior Reviewer (holistic evidence weighing for high-stakes decisions)
- Sonnet assignments: Front Desk (structured extraction from FNOL), Claims Officer (policy field matching against structured JSON), Finance (arithmetic: estimate minus deductible minus depreciation)
- Both models have `cacheRetention: "short"` enabled (Decision #12) to reduce cost of repeated AGENTS.md injection across sessions

---

### Q12: "How do you handle errors and retries?"

**Concise answer:** Each agent has a per-stage timeout -- 60 to 120 seconds depending on task complexity. If an agent fails, the Router retries up to 2 times with a fresh session. If it still fails, the claim goes to ERROR status with a full audit log of what happened. For the demo, the happy path is reliable, but the system handles failures gracefully.

**Deep dive:**
- Per-stage timeouts: Front Desk 60s, Claims Officer 90s, Assessor 120s, Fraud Analyst 90s, Senior Reviewer 90s, Finance 60s (documented in STATE.md accumulated decisions)
- Retry is immediate re-spawn with a fresh session -- no state carried from the failed attempt
- The Router uses `sessions_history` to read the full transcript of a failed session before retrying (documented in openclaw-tools.md Section 3) -- this helps diagnose whether the failure was transient or systemic
- After 2 retries exhausted: claim transitions to ERROR status, full audit log preserved, human operator notified
- Emergency workaround during the hackathon: skip failing pipeline stage temporarily in Router AGENTS.md (documented in day-of-timeline.md)

---

### Q13: "Why not use SOUL.md?"

**Concise answer:** Sub-agents spawned via sessions_spawn do not receive SOUL.md -- they only get AGENTS.md and TOOLS.md. This is an OpenClaw architectural constraint, not a choice. All operating instructions go in AGENTS.md. We documented this explicitly so the team does not waste time debugging why SOUL.md instructions are ignored by pipeline agents.

**Deep dive:**
- Decision log entry #4 documents this critical behavior: SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, and BOOTSTRAP.md are NOT injected into depth-1 sub-agent sessions
- `docs/openclaw-tools.md` Section 6 explains the workspace structure and which files are loaded at each depth level
- For consistency, even the Router (the only depth-0 agent where SOUL.md would work) uses AGENTS.md exclusively -- single source of truth eliminates the documented pitfall of split configuration
- This is a common gotcha for OpenClaw teams -- knowing about it and designing around it demonstrates framework mastery

---

### Q14: "How does the Router control the pipeline?"

**Concise answer:** The Router uses a state machine with 9 states. It spawns each agent via sessions_spawn with an enriched task message containing the claim file path, prior stage results, and regulatory context. After each agent announces completion, the Router reads the claim file, validates required fields, transitions the status, and decides what to spawn next -- or whether to shortcut or escalate.

**Deep dive:**
- `docs/ARCHITECTURE.md` Section 4 documents the complete state machine with 9 states and the full transition table
- The 9 states: FNOL_RECEIVED, COVERAGE_CHECKED, ASSESSED, FRAUD_ANALYZED, REVIEWED, PAYMENT_ISSUED, DENIED, ESCALATED, ERROR
- Terminal states: PAYMENT_ISSUED, DENIED, ESCALATED, ERROR (pipeline stops)
- Non-terminal states: first 5 (pipeline continues)
- Context enrichment: Router injects per-stage regulatory context into each task message (Decision documented in STATE.md: "Router task messages include per-stage regulatory context injection for FCSP compliance awareness")
- `docs/openclaw-tools.md` Section 1 documents the announce-wait-read-spawn cycle with concrete examples of the sessions_spawn call pattern
- The announce protocol: agents report Status (SUCCESS/ERROR/ESCALATE), Summary, Key findings, and Next recommended action

---

### Q15: "What about security?"

**Concise answer:** Security follows least-privilege throughout. Each agent gets only the tools it needs -- most pipeline agents have just read and write. Only the Router can spawn agents. Only Finance can execute scripts. The Router's allowAgents list explicitly names the 6 valid targets -- no wildcards. And agentToAgent messaging is disabled so all communication flows through the auditable claim file.

**Deep dive:**
- Decision log entry #8 (tool scoping), #11 (allowAgents explicit list), #7 (agentToAgent disabled)
- `docs/openclaw-tools.md` Section 5 has the complete tool access matrix showing allow/deny per agent
- `docs/ARCHITECTURE.md` Section 5 explains the least-privilege rationale for each tool assignment
- Finance is the ONLY pipeline agent with `exec` -- for payment simulation. No other pipeline agent can execute scripts.
- Pipeline agents have `sessions_spawn` explicitly denied -- enforced by BOTH tool scoping AND maxSpawnDepth: 1 (defense in depth)
- Gateway bound to localhost only (127.0.0.1:18789) -- team accesses via SSH tunnel (Decision #9, documented in setup.sh)

---

## Category 3: Regulatory Knowledge

### Q16: "What are the FCSP timelines?"

**Concise answer:** Ohio follows the NAIC model. Acknowledgment within 10-15 business days of receipt. Investigation decision within a reasonable time -- most states interpret as 40 days. Payment within 30 days of settlement. Our system processes claims in minutes, well within all deadlines, and the Router tracks these timelines at every stage.

**Deep dive:**
- `reference/domain-knowledge/regulatory-compliance.md` Section 1 documents all three timelines with sources
- 10-15 business days: NAIC model says 10, California extends to 15 calendar days. System defaults to most conservative applicable standard.
- 40 calendar days: Clock starts when proof of loss is complete and accepted, not when FNOL is filed
- 30 calendar days: After acceptance. Delays beyond this create bad faith liability.
- The Front Desk records the claim receipt timestamp (start of regulatory clock)
- The Claims Officer records when proof of loss is received
- The Senior Reviewer checks all three timelines before making a final decision
- If approaching deadline without resolution: system escalates with documented urgency

---

### Q17: "What is the total loss threshold in Ohio?"

**Concise answer:** Ohio uses 100% ACV -- a vehicle is a total loss when repair costs equal or exceed its actual cash value. Some states use 75% or 80%, but Ohio is 100%. The Assessor knows this and flags total loss when the estimate hits ACV. Total loss claims are automatically escalated to human review by the Senior Reviewer.

**Deep dive:**
- `reference/domain-knowledge/edge-cases.md` Section 1 documents total loss handling in detail
- Ohio's 100% ACV rule is one of the stricter thresholds nationally
- Total loss payout calculation: ACV minus deductible. If policyholder retains salvage, salvage retention credit also deducted.
- Rental on total loss: typically 10-day cap after declaration (time to locate replacement)
- GAP insurance awareness: Finance notes when loan balance exceeds ACV, indicating GAP coverage would cover the difference
- The Assessor uses Ohio's 100% threshold as a reasoning principle: "when repair cost approaches or exceeds ACV" -- not hardcoded as a numeric comparison

---

### Q18: "What is bad faith exposure?"

**Concise answer:** Bad faith occurs when an insurer unreasonably denies, delays, or underpays a claim. Common triggers: denying without investigation, missing FCSP deadlines, failing to explain denial reasons, lowballing estimates. Our system mitigates bad faith risk by documenting every decision with reasoning, checking FCSP compliance at every stage, and escalating ambiguous cases to human review rather than auto-denying.

**Deep dive:**
- `reference/domain-knowledge/regulatory-compliance.md` Section 3 catalogs 8 specific bad faith triggers in three categories: delay-related, decision-related, documentation-related
- Delay-related: unreasonable delay in acknowledging claim, failing to investigate promptly, failing to communicate status
- Decision-related: denying without reasonable basis, lowballing, misrepresenting policy provisions
- Documentation-related: failing to provide written denial explanation, incomplete investigation documentation
- System prevention mechanisms (5 structural safeguards documented in regulatory-compliance.md): documented reasoning on every decision, timeline tracking, escalation triggers, denial documentation requirements, complete audit trail
- The Senior Reviewer's decision framework explicitly includes bad faith risk assessment -- this is step 3 in the denial review path

---

### Q19: "How does subrogation work?"

**Concise answer:** When our policyholder is not at fault, we pay the claim and then pursue recovery from the at-fault party's insurer. The Finance agent identifies subrogation candidates by checking for other-party information and fault indicators. The subrogation target -- insurer, policy number -- is recorded in the claim for the recovery team. This reduces the net cost of the claim.

**Deep dive:**
- `docs/agent-documentation.md` Finance section documents subrogation assessment as step 6 of the Finance agent's decision process
- Subrogation requires: other party identified, other party at fault, other party insured
- In the happy path demo (CLM-2026-00001): Maria Rodriguez was at fault, insured by State Farm (SF-98-7654321). Finance flags subrogation_candidate=true and records the target.
- Recovery includes: insurer's costs ($3,700 payment) plus the claimant's deductible ($500)
- Multi-vehicle subrogation: when multiple at-fault parties exist, recovery may involve multiple third-party insurers (documented in edge-cases.md Section 9)

---

### Q20: "What about diminished value?"

**Concise answer:** Diminished value is the loss in a vehicle's market value after repair. The 17c formula -- base value times damage modifier times mileage modifier -- is the standard calculation. Our Senior Reviewer flags DV awareness on applicable claims. For this demo, we focus on repair and total loss rather than DV calculation, but we can explain the framework in detail.

**Deep dive:**
- `reference/domain-knowledge/edge-cases.md` Section 3 documents the complete 17c formula with all modifier tables
- 17c formula: (10% of pre-accident retail value) x damage modifier (0.00-1.00 based on severity) x mileage modifier (0.00-1.00 based on odometer)
- Example calculation documented: $25,000 vehicle, moderate structural damage (0.50), 35,000 miles (0.80) = $2,500 x 0.50 x 0.80 = $1,000 diminished value
- The system flags DV awareness -- it does not compute DV automatically. This is an honest scope limitation appropriate for a hackathon demo.
- Knowing the 17c formula by name and being able to walk through a calculation demonstrates domain depth that most teams will not have

---

### Q21: "What happens if the other driver doesn't have insurance?"

**Concise answer:** If the at-fault party is uninsured or underinsured, the Claims Officer identifies this early and routes the claim to the policyholder's own UM or UIM coverage, which has separate limits and deductibles from collision coverage. UM covers when the other driver has no insurance at all; UIM covers the gap when their limits are too low.

**Deep dive:**
- `reference/domain-knowledge/edge-cases.md` Section 4 documents UM/UIM routing
- UM (Uninsured Motorist): other driver has NO insurance. The insured's own UM coverage pays.
- UIM (Underinsured Motorist): other driver's limits are insufficient. The insured's UIM coverage pays the gap.
- Different coverage path: UM/UIM has its own limits and deductibles separate from collision
- The claim schema includes `um_uim_route` field (values: UM, UIM, not_applicable) showing the system is designed for this routing
- The Claims Officer makes this determination during coverage verification (Stage 2) based on whether the other party has identified insurance

---

### Q22: "What about claim supplements?"

**Concise answer:** About 30 to 40 percent of collision claims have supplements -- hidden damage found when the shop opens up the vehicle. Our Assessor flags when hidden damage is likely. The Senior Reviewer can pre-authorize a supplement threshold. Finance issues supplemental payments on the same claim ID. No new claim is opened.

**Deep dive:**
- `reference/domain-knowledge/edge-cases.md` Section 5 documents the supplement path
- 30-40% of collision claims have supplements (industry statistic)
- The Assessor's `hidden_damage_likely` field flags claims where the initial assessment involves structural damage, deep panel deformation, or airbag deployment
- In the happy path demo (CLM-2026-00001): hidden_damage_likely=true because "damage extends into the wheel well area," and Finance flags supplement_eligible=true
- Supplements are additional estimates and payments on the existing claim -- same claim ID, same audit trail
- This demonstrates the system handles the real-world complexity of claims that evolve during repair

---

## Cross-Category Questions

### Q23: "How does the secret addition change your system?"

**Concise answer:** The secret addition is handled by updating the relevant AGENTS.md files -- no code changes required. Our architecture separates business logic (in AGENTS.md) from infrastructure (in openclaw.json and scripts). When the secret arrives, we update the reasoning frameworks in the affected agents. The next claim processed uses the updated instructions immediately.

**Deep dive:**
- `docs/secret-addition-framework.md` documents three anticipated scenarios with time estimates: Scenario A (new agent, 30 min), Scenario B (new rule, 15 min), Scenario C (volume surge, 20 min)
- 8 architectural invariants defined as DO NOT CHANGE: sequential pipeline, claim JSON format, maxSpawnDepth, agentToAgent disabled, tool scoping, JSON file state, Router status ownership, announce protocol
- Decision #6 (reasoning frameworks): reasoning from principles is more adaptable than rule tables. The secret addition may change business context -- reasoning frameworks accommodate this naturally.
- AGENTS.md is the primary adaptation surface -- no code changes, no schema changes, no configuration changes for most business logic modifications

---

### Q24: "How did you prepare for this hackathon?"

**Concise answer:** We spent our pre-hackathon time on domain knowledge and architecture decisions, not on code. We researched Ohio auto insurance regulations, fraud patterns, and claims processing workflows. We designed the full pipeline architecture with 15 documented decisions. We wrote complete AGENTS.md specifications for all 7 agents. On hackathon day, we implement what we designed.

**Deep dive:**
- Phase 1 (Domain Knowledge): 3 research plans covering regulatory compliance, fraud detection, damage assessment, edge cases, and payment/subrogation
- Phase 2 (Architecture Design): 5 design plans covering OpenClaw configuration, claim schema, Router design, handoff protocol, human-in-the-loop, scripts, and documentation
- Phase 3 (Agent Specifications): 4 specification plans covering all 7 agents with complete AGENTS.md content and 3 test claim scenarios
- Phase 4 (Execution Playbook): 4 preparation plans covering day-of timeline, secret addition framework, demo walkthroughs, presentation script, and this Q&A defense document
- 15 decisions in the decision log, each with alternatives considered, choice made, and rationale documented
- 10 edge case categories documented with one-sentence answers ready for Q&A

---

*Q&A defense document for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*24 prepared answers across 3 categories + cross-category questions*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
