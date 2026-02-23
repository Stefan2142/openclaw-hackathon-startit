# Feature Research

**Domain:** Multi-agent auto insurance claims processing system
**Researched:** 2026-02-17
**Confidence:** HIGH (domain knowledge verified against NAIC, FCSP regulations, industry sources)
**Context:** 10-hour hackathon demo, 50% business thinking / 50% system thinking judging. Features scoped for credibility + differentiating depth, not production completeness.

---

## Hackathon Framing

The judges are looking for two things simultaneously:

1. **Business credibility** — Does the team understand why insurance claims processing works the way it does? Can they defend every decision against real regulations and industry practice?
2. **System coherence** — Do the agents have appropriate isolation, scoping, and handoff protocols?

Features below are categorized by whether they serve business credibility, system coherence, or both. Missing table stakes features will cost business credibility points. Differentiators win on both axes.

---

## Feature Landscape

### Table Stakes (Judges Won't Take You Seriously Without These)

| Feature | Why Expected | Complexity (hrs) | Notes |
|---------|--------------|------------------|-------|
| **FNOL intake with structured data capture** | The claim literally cannot start without it. Judges know FNOL is the entry point. | LOW (1-2hrs) | Policy number, date/time of loss, incident description, location, other party info, police report number, photos. Missing any of these = incomplete intake. |
| **Claim categorization at FNOL** | Real insurers triage on intake: collision, comprehensive, liability, theft, vandalism, weather. Category determines which coverage applies and which adjuster handles it. | LOW (1hr) | Determines downstream routing. Collision vs. comprehensive is a coverage-type question. Wrong category = wrong coverage check. |
| **Policy lookup and active coverage verification** | If coverage isn't verified before anything else happens, the system is operationally backward. This is the Claims Officer's primary function. | LOW (1-2hrs) | Policy number lookup, effective dates, coverage types on policy (liability, collision, comprehensive, UM/UIM), lapse check. |
| **Exclusion checking** | Every policy has exclusions. Missing them = potential bad faith exposure for the insurer. | MEDIUM (2hrs) | Common auto exclusions: intentional acts, racing/competition, commercial use on personal policy, excluded drivers, non-owned vehicle without endorsement, mechanical breakdown. |
| **Deductible determination** | Deductible is always subtracted from payout. Every adjuster knows this. Not computing it = system is not doing claims processing. | LOW (0.5hr) | Per-coverage deductibles differ (collision $500, comprehensive $250 are typical). Named-driver deductibles may vary. |
| **Damage estimate generation** | The Assessor agent exists for this. Without a dollar estimate, there's nothing for Finance to pay or Senior Reviewer to approve. | MEDIUM (2-3hrs) | Must reference labor rate + parts cost. Can use flat rate tables or photo-based estimation. |
| **Total loss determination logic** | Judges understand that if repair cost > ACV threshold, vehicle is totaled, not repaired. Getting this wrong is a major credibility failure. | MEDIUM (1-2hrs) | Most states: 70-80% of ACV triggers total loss. Ohio (the company is Ohio Mutual) uses 100% rule — if repair cost equals or exceeds ACV, it's a total loss. Must know Ohio's specific threshold. |
| **Fraud risk scoring** | The Fraud Analyst agent's entire purpose. Without a scored output, the agent doesn't add value. | MEDIUM (2-3hrs) | Pattern matching against known fraud indicators. Score drives escalation decision. |
| **Senior Reviewer decision gate** | The authorization and approval step before payment. Judges will ask "what stops bad payments?" If Senior Reviewer doesn't exist as a real gate, the system is not defensible. | MEDIUM (2hrs) | Approval / conditional approval / denial / escalate-to-human. Must have clear criteria for each path. |
| **Audit log with reasoning** | Required by FCSP regulations — every action must be documentable. Also the primary way agents communicate causation to each other. | LOW (1hr) | Every agent decision logged with: timestamp, agent ID, action taken, reasoning, any flags raised. This is regulatory, not optional. |
| **Payment calculation with deductible subtraction** | Finance agent's core function. Without correct math, the system is not doing claims processing. | LOW (1hr) | Payout = (damage estimate OR ACV for total loss) - deductible - any depreciation. |
| **Claim status tracking (pipeline state machine)** | How do judges see the claim moving through stages? Without explicit status, the demo is unreadable. | LOW (1hr) | FNOL_RECEIVED → COVERAGE_CHECKED → ASSESSED → FRAUD_ANALYZED → REVIEWED → PAYMENT_ISSUED (or DENIED). |

---

### Differentiators (Competitive Advantage — Shows Deep Business Understanding)

| Feature | Value Proposition | Complexity (hrs) | Notes |
|---------|-------------------|------------------|-------|
| **Fraud pattern specificity — named fraud types** | Shows deep domain research. Generic "suspicious" is not insurance fraud. Named patterns (staged accident, jump-in, paper accident, inflated repair) demonstrate real understanding. | MEDIUM (2-3hrs) | Staged accidents up 47% in 2024 (Aviva Canada data). Patterns: swoop-and-squat, drive-down, side-swipe setup, curb drive-down, paper accident (never happened). Phantom passengers, VIN switching, ReVINing (altered stolen VINs). |
| **Soft fraud vs. hard fraud distinction** | Hard fraud = fabricated claims. Soft fraud = exaggeration of real claims. Different response protocols, different legal exposure. Few teams will make this distinction. | LOW (0.5hr) | Hard fraud: refer to SIU (Special Investigations Unit) + deny. Soft fraud: negotiate reduced settlement + flag. System should distinguish which path to recommend. |
| **FCSP-compliant timeline tracking** | Regulatory compliance is 50% of the "business thinking" score. Knowing that acknowledgment must happen within 10-15 business days (state-dependent) and decision within 40 calendar days is a differentiator. | LOW (0.5hr) | Embed timestamps on FNOL receipt, coverage determination, and payment. Show these in audit log. States: CA = 15-day ack, 40-day decision. NAIC model = 10-day ack. Frame as "we track compliance timelines automatically." |
| **OEM vs. aftermarket parts decision logic** | Adjusters face this choice on every collision claim. OEM = safety and fit, costs more. Aftermarket = cheaper, may affect vehicle value. Knowing that some states require OEM for vehicles under certain age or mileage shows domain depth. | LOW (0.5hr) | Assessor logic: vehicle under 3 years old or under 36K miles → recommend OEM. Older → aftermarket acceptable with policyholder disclosure. Document in estimate. |
| **Diminished value awareness** | Most teams won't know this concept. After a collision repair, the car is worth less even when fixed. Some states require insurers to address DV claims proactively. | LOW (0.5hr) | 17c formula: base DV = 10% of pre-accident ACV. Modifiers for damage severity and mileage. Senior Reviewer should flag if DV claim is expected and address it. |
| **Subrogation flag on liability claims** | When the insured is not at fault, the insurer pays, then recovers from the at-fault party's insurer. Finance should flag subrogation opportunity when fault is determined. | LOW (0.5hr) | Subrogation = insurer steps into insured's shoes to recover from third party. Flag condition: at-fault is a third party with identified insurance. Adds business value story to Finance agent. |
| **Pre-existing damage detection in assessment** | A classic source of claim disputes. Assessor should note which damage is consistent with the described incident and which appears older. | MEDIUM (1-2hrs) | Rust on fresh impact areas, paint oxidation on damaged panels, damage in non-impact zones = pre-existing flags. Logged as conditional approval pending inspection. |
| **Rental reimbursement handling** | Many policies include rental coverage during repair period. Assessor must estimate repair days to compute rental entitlement. | LOW (0.5hr) | Standard: $30-50/day rental allowance, typically 30-day cap. Repair estimate drives days. Total loss = 10 days max (time to locate replacement). |
| **Uninsured/underinsured motorist routing** | When at-fault party has no insurance (or insufficient insurance), the claim routes to the policyholder's own UM/UIM coverage — a completely different coverage check path. | MEDIUM (1-2hrs) | UM = at-fault has no insurance. UIM = at-fault has insufficient insurance. Different deductibles, different caps. Claims Officer must identify this scenario and route correctly. |
| **Human-in-the-loop escalation with explicit triggers** | HITL is expected, but teams that define WHEN escalation happens score higher than teams that say "sometimes a human reviews it." | LOW (0.5hr) | Explicit triggers: fraud score above threshold (e.g., >70), claim value above $25K, total loss, legal representation letter received, bad faith risk flag, prior claim within 12 months on same vehicle, UM/UIM claim. |
| **Claim reopening / supplemental claim logic** | Damage discovered during repair that wasn't visible in initial estimate. Standard in the industry — hidden damage supplements are common. | LOW (0.5hr) | Assessor can flag "hidden damage likely" for structural damage. Senior Reviewer approves supplement authority. Finance has supplement payment path. |
| **Bad faith risk detection** | If the insurer delays beyond statutory timelines without documented reason, they face bad faith liability. System should flag when a claim is approaching deadline. | LOW (0.5hr) | Calculate elapsed time from FNOL. If approaching 40-day decision deadline without resolution, escalate to Senior Reviewer with urgency flag. This is a compliance and liability management feature. |
| **Weather/CAT (catastrophic) event tagging** | When claims surge (hailstorm, flood), individual claim context matters. A CAT tag changes priority and sometimes changes coverage (comprehensive vs. collision distinction is critical — weather is comprehensive). | LOW (0.5hr) | Front Desk tags claim with CAT event if: date/location matches known weather event, multiple claims from same area in same window. Affects routing priority. |

---

### Anti-Features (Deliberately Do NOT Build)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Real-time photo AI damage estimation** | Building a working computer vision model in 10 hours is impossible. Claiming you have it is a credibility risk if judges probe. | Have the Assessor agent accept photo descriptions or metadata and apply estimation rules. Frame as "photo analysis input → structured assessment" rather than claiming live ML inference. |
| **50-state regulatory variation** | Each state has different FCSP timelines, total loss thresholds, coverage requirements. Trying to handle all 50 is scope creep that adds complexity without demo value. | Pick ONE state (Ohio, since it's Ohio Mutual). Know Ohio's rules deeply. State you'd add state-specific modules in production. |
| **Real payment processing / banking integration** | Not possible in 10 hours and not needed for the demo. | Mock payment execution that logs "PAYMENT_INITIATED: $X to account ending XXXX" with check/ACH notation. |
| **Real policy database integration** | No time to build or mock a real policy database with full schema validation. | Create 3-5 mock policy records in JSON covering: standard, comprehensive only, lapsed, high-deductible, excluded driver. These are all you need for the demo scenarios. |
| **Customer-facing portal / mobile app** | This is a backend pipeline demo, not a customer experience demo. Building UI costs time and distracts from the agent logic judges actually care about. | CLI-driven demo or simple web terminal. Show the claim JSON flowing through the pipeline. |
| **Hardcoded decision rules** | Challenge explicitly says "plan for human reasoning: your thinking should not be hardcoded." Hardcoded if-then rules for fraud or coverage are the opposite of what judges want. | Write agent AGENTS.md with rich context, principles, and examples. Let Claude reason. Provide reference data (fraud patterns, exclusion lists) as documents agents read, not code. |
| **Concurrent multi-claim stress testing** | Showing 100 claims in parallel is engineering theater that wastes demo time without adding business value. | Show 2-3 claims in sequence: happy path, fraud rejection, total loss. Each tells a business story. |
| **SIU (Special Investigations Unit) full simulation** | Real SIU involves field investigation, recorded statements, surveillance. This cannot be simulated in 10 hours and will look fake. | Fraud Analyst refers to SIU and outputs a referral document. That's enough — the referral is the output, not the investigation. |
| **Diminished value calculation as a formal claim type** | DV claims are complex (17c formula requires KBB value, damage modifiers, mileage modifiers). Building a full DV calculator is hours of work for minimal demo payoff. | Senior Reviewer mentions DV awareness in their decision note when applicable. Show you know it exists. Don't build the calculator. |
| **GAP insurance / loan payoff integration** | If vehicle ACV is less than loan balance, GAP insurance covers the difference. Real but very niche — adds complexity without improving demo score. | Note in total loss handling that "GAP coverage would apply if loan balance exceeds ACV — Finance notifies lending institution." Awareness, not implementation. |

---

## Feature Dependencies

```
[FNOL Intake]
    └──requires──> [Policy Lookup]
                       └──requires──> [Mock Policy Database (3-5 records)]
                       └──enables──> [Coverage Verification]
                                         └──requires──> [Exclusion Check]
                                         └──produces──> [Deductible Determination]

[Coverage Verified = TRUE]
    └──enables──> [Damage Assessment]
                       └──requires──> [Claim Category from FNOL]
                       └──produces──> [Repair Estimate OR Total Loss Determination]
                       └──produces──> [OEM vs Aftermarket Recommendation]
                       └──produces──> [Rental Days Estimate]

[Coverage Verified = FALSE]
    └──routes──> [Senior Reviewer: Denial]

[Damage Assessment]
    └──enables──> [Fraud Analysis]
                       └──requires──> [Claim data from all prior stages]
                       └──produces──> [Fraud Score + Named Pattern Flags]

[Fraud Analysis]
    └──enables──> [Senior Review]
                       └──requires──> [All prior stage outputs]
                       └──evaluates──> [Fraud Score threshold]
                       └──evaluates──> [Claim value threshold]
                       └──evaluates──> [FCSP timeline compliance]
                       └──produces──> [APPROVED / DENIED / ESCALATE_HUMAN / CONDITIONAL]

[Senior Review = APPROVED]
    └──enables──> [Finance: Payment Calculation]
                       └──requires──> [Damage estimate]
                       └──requires──> [Deductible]
                       └──applies──> [Depreciation (ACV policy) or none (RCV policy)]
                       └──flags──> [Subrogation opportunity if third-party fault]
                       └──produces──> [Payment record]

[Audit Log] ──enhances──> [Every Stage] (all agents write to it)
[FCSP Timeline Tracker] ──enhances──> [Senior Review] (bad faith risk flag)
[Human-in-the-Loop Escalation] ──triggered by──> [Senior Review decision = ESCALATE_HUMAN]
[CAT Tag from FNOL] ──enhances──> [Damage Assessment] (adjusts priority and coverage type)
[Subrogation Flag] ──conflicts with──> [Final payment closure] (payment is provisional pending recovery)
```

### Dependency Notes

- **Policy Lookup requires Mock Policy Database:** Without at least 3-5 real mock records, coverage verification cannot be demonstrated meaningfully.
- **Damage Assessment requires Claim Category:** Collision damage is estimated differently from comprehensive damage. Assessor needs the category to apply the right estimation logic.
- **Fraud Analysis requires all prior outputs:** Fraud scoring uses claim value, claimant history, incident description, damage pattern, and timeline. It's a synthesis step — it cannot run before coverage and assessment.
- **Senior Review requires Fraud Score:** Senior Reviewer must see fraud risk to make a defensible approval decision. Approving a high-fraud-score claim without review is bad faith exposure.
- **FCSP Timeline Tracker enhances Senior Review:** If the claim is near the regulatory deadline, Senior Reviewer urgency changes. This is not blocking but is a differentiator if shown in the demo.
- **Subrogation Flag conflicts with payment closure:** Subrogation means the payment is made but recovery is pending. Finance must note the claim as open for subrogation recovery, not fully closed.

---

## MVP Definition

### Launch With (Demo Core — Build First)

- [ ] **FNOL intake + claim categorization** — Without this, nothing else runs. Collision / comprehensive / liability / theft triage.
- [ ] **Policy lookup + coverage verification + exclusion check + deductible** — Core Claims Officer function. Must work for mock policies: covered, lapsed, excluded driver, no collision coverage.
- [ ] **Damage estimate + total loss determination** — Ohio threshold (100% ACV rule). OEM vs. aftermarket note.
- [ ] **Fraud scoring with 4-5 named patterns** — Staged accident, phantom passenger, prior damage, inflated repair, paper accident. Score produces clear recommendation.
- [ ] **Senior Reviewer decision gate** — Approval / denial / escalate. Explicit fraud score threshold (e.g., >70 = escalate).
- [ ] **Finance payment calculation** — Damage estimate minus deductible. Subrogation flag if third-party fault.
- [ ] **Audit log on every agent** — Timestamp + reasoning on every decision. Required for regulatory credibility.
- [ ] **3-5 mock policy records** — Covers: standard covered, lapsed, excluded driver, high deductible, comprehensive-only.

### Add After Core Works (Hour 6-7 If Time Permits)

- [ ] **FCSP timeline tracking** — Calculate elapsed time from FNOL, flag if approaching 40-day deadline. Low effort, high business score.
- [ ] **Pre-existing damage flag in Assessor** — Adds credibility to damage assessment. Describe what indicators trigger it.
- [ ] **Rental reimbursement calculation** — Easy to add once repair days are estimated. Shows policy awareness.
- [ ] **Human-in-the-loop escalation message** — When Senior Reviewer escalates, output a structured escalation notice (claim ID, reason, urgency level) formatted as a human-readable alert.

### Future Consideration (Do Not Build — Know Enough to Discuss)

- [ ] **UM/UIM routing** — Complex enough that understanding it is sufficient for Q&A. Don't build.
- [ ] **Diminished value claim handling** — Know the 17c formula for Q&A. Don't compute it live.
- [ ] **Bad faith litigation risk scoring** — Be able to describe the concept. Audit log already addresses the underlying concern.
- [ ] **CAT event tagging** — Mention in the architecture as a planned feature. Show the field exists in the claim schema.

---

## Feature Prioritization Matrix

| Feature | Business Value | Implementation Cost | Priority |
|---------|---------------|---------------------|----------|
| FNOL intake + categorization | HIGH | LOW | P1 |
| Policy lookup + coverage verification | HIGH | LOW | P1 |
| Deductible + exclusion check | HIGH | LOW | P1 |
| Total loss determination | HIGH | MEDIUM | P1 |
| Fraud scoring with named patterns | HIGH | MEDIUM | P1 |
| Senior Reviewer decision gate | HIGH | MEDIUM | P1 |
| Audit log with reasoning | HIGH | LOW | P1 |
| Payment calculation | HIGH | LOW | P1 |
| Mock policy database (3-5 records) | HIGH | LOW | P1 |
| OEM vs. aftermarket logic | MEDIUM | LOW | P2 |
| Soft vs. hard fraud distinction | MEDIUM | LOW | P2 |
| FCSP timeline tracking | MEDIUM | LOW | P2 |
| Subrogation flag | MEDIUM | LOW | P2 |
| Rental reimbursement | MEDIUM | LOW | P2 |
| Pre-existing damage detection | MEDIUM | MEDIUM | P2 |
| Human-in-the-loop escalation triggers | MEDIUM | LOW | P2 |
| Claim reopening / supplement path | LOW | LOW | P3 |
| Diminished value awareness | LOW | LOW | P3 |
| CAT event tagging | LOW | LOW | P3 |
| Bad faith risk flag | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch — missing these means the demo is not credible
- P2: Should have — adds significant business thinking score
- P3: Nice to have — worth mentioning in Q&A even if not built

---

## Agent-by-Agent Feature Allocation

### Front Desk Agent
**Table stakes:** Policy number capture, date/time of loss, incident location, incident description, other party info, police report reference, photo metadata capture, claim categorization (collision / comprehensive / liability / theft / vandalism / weather).
**Differentiators:** CAT event tag, rental coverage flag (does the policy include it?), initial claim ID generation, urgency flag (injury reported → expedite).
**Output:** Structured FNOL JSON written to shared state.

### Claims Officer Agent
**Table stakes:** Policy active status check (not lapsed), coverage type verification (does policy include the claimed coverage type?), exclusion check, deductible lookup, coverage limits lookup.
**Differentiators:** Lapsed policy grace period awareness (most states allow 10-30 day grace), UM/UIM identification when third-party has no insurance, endorsement check (e.g., rental car endorsement, roadside assistance).
**Output:** Coverage determination (COVERED / DENIED / CONDITIONAL), deductible amount, applicable limits.

### Assessor Agent
**Table stakes:** Damage estimate (labor + parts), total loss determination (Ohio 100% ACV rule), OEM vs. aftermarket recommendation, repair timeline (days).
**Differentiators:** Pre-existing damage flag, rental day calculation, hidden damage likelihood flag, salvage value estimate for total loss.
**Output:** Repair estimate OR total loss + ACV + salvage value, OEM/aftermarket recommendation, rental entitlement.

### Fraud Analyst Agent
**Table stakes:** Fraud score (0-100), pattern flags (staged accident, phantom passenger, inflated repair, paper accident, prior damage claim on same vehicle).
**Differentiators:** Soft fraud vs. hard fraud classification, SIU referral recommendation for hard fraud, organized ring indicator (multiple claimants same event), AI-generated document suspicion flag.
**Output:** Fraud score, named flags, recommendation (CLEAR / INVESTIGATE / REFER_SIU).

### Senior Reviewer Agent
**Table stakes:** Final decision (APPROVE / DENY / CONDITIONAL_APPROVE / ESCALATE_HUMAN), written rationale, review of fraud score and coverage determination.
**Differentiators:** FCSP timeline check before decision, explicit escalation trigger list, claim value threshold check (>$25K = human review), diminished value awareness note, supplemental claim authorization threshold.
**Output:** Decision + rationale + any conditions (e.g., "approved pending physical inspection").

### Finance Agent
**Table stakes:** Payout calculation (estimate minus deductible minus depreciation if ACV policy), payment record with claim reference.
**Differentiators:** Subrogation flag with third-party insurer info, GAP insurance awareness note for total loss, rental reimbursement separate line item, supplement payment path.
**Output:** Payment record (amount, recipient, method, date), subrogation flag if applicable.

---

## Demo Scenario Requirements (What Needs to Work for the Presentation)

Three scenarios that tell complete business stories:

**Scenario 1 — Happy Path Collision (6 minutes)**
- Insured rear-ended at stop light, other driver at fault
- Policy active, collision coverage present
- Damage estimate: $4,200, deductible $500, no fraud flags
- Senior Reviewer approves, Finance pays $3,700
- Subrogation flag: pursue recovery from other driver's insurer
- Shows: full pipeline, normal operation, subrogation awareness

**Scenario 2 — Fraud Rejection (4 minutes)**
- Whiplash claim, 3 passengers in a 2-door car, no police report
- Damage inconsistent with described collision speed
- Fraud score: 85 (phantom passengers + staged accident pattern)
- Senior Reviewer escalates to human / denies pending SIU investigation
- Shows: fraud detection specificity, escalation path, regulatory compliance (document the denial)

**Scenario 3 — Coverage Denial (3 minutes)**
- Policyholder uses personal vehicle for Uber (commercial use on personal policy exclusion)
- Claims Officer identifies commercial use exclusion in policy
- Senior Reviewer denies on coverage grounds
- Shows: exclusion knowledge, non-fraud denial path, audit trail

These three scenarios exercise every agent, cover the three most common claim outcomes (pay / fraud reject / coverage deny), and each demonstrates a specific piece of insurance domain knowledge judges will recognize.

---

## Insurance Domain Knowledge Quick Reference (For Q&A Defense)

### Key Numbers to Know
- **Claim acknowledgment:** 10-15 business days (NAIC model: 10; California: 15 calendar days)
- **Coverage decision:** 40 calendar days after proof of loss (California FCSP, representative of most states)
- **Payment after approval:** 30 calendar days
- **Ohio total loss threshold:** 100% of ACV (vehicle is totaled when repair cost equals or exceeds ACV — Ohio is one of the stricter states)
- **Typical total loss threshold:** 70-80% of ACV in most states
- **Standard deductibles:** Collision $500, comprehensive $250 (can vary)
- **Auto fraud cost:** $308.6 billion annually to U.S. economy (Coalition Against Insurance Fraud)
- **Staged accidents trend:** Up 47% in Q4 2024 (Aviva Canada data)
- **SIU referral threshold:** Typically fraud score >70 or claim value >$50K with flags

### Key Terms to Use Correctly
- **ACV (Actual Cash Value):** Replacement cost minus depreciation. What the vehicle is worth at time of loss.
- **RCV (Replacement Cost Value):** What a new equivalent vehicle costs. Higher payouts, higher premiums.
- **Subrogation:** Insurer pays claimant, then steps into claimant's shoes to recover from at-fault party.
- **FNOL:** First Notice of Loss — the initial report that opens a claim.
- **SIU:** Special Investigations Unit — internal team that investigates suspected fraud.
- **FCSP:** Fair Claims Settlement Practices — state regulations governing how insurers must handle claims.
- **CAT:** Catastrophic event — hurricane, hail storm, flood — triggers surge processing.
- **Diminished value:** Loss in resale value after a repaired collision, even with OEM parts.
- **Subrogation lien:** Insurer's right to recovery placed on the claim until third-party liability is resolved.

---

## Sources

- NAIC (National Association of Insurance Commissioners) — Claims Settlement Provisions Chart, Spring 2024 (state-by-state timelines): https://content.naic.org/sites/default/files/model-law-chart-mc-50-claims-settlement-provisions.pdf
- California Department of Insurance — Fair Claims Settlement Practices Regulations (Section 2695.7, 2695.8): https://www.insurance.ca.gov/01-consumers/130-laws-regs-hearings/05-CCR/fair-claims-regs.cfm
- Aviva Canada — 2024 Fraud Prevention Report (staged accident statistics, 47% increase Q4 2024): https://www.aviva.ca/en/press-releases/2025/fraud-prevention-month-trends/
- Coalition Against Insurance Fraud / Roundtables.us — $308.6B annual fraud cost: https://roundtables.us/the-rising-cost-of-auto-insurance-fraud-in-the-u-s-and-how-lpr-data-fights-back/
- NICB (National Insurance Crime Bureau) — Staged Auto Accident Fraud patterns: https://www.nicb.org/prevent-fraud-theft/staged-auto-accident-fraud
- Total Loss Appraisals — Total Loss Threshold chart (state-by-state), OEM vs. aftermarket analysis: https://totallossappraisals.com/how-insurers-devalue-cars-with-non-oem-parts/
- MWL Law — Automobile Total Loss Thresholds by state (PDF): https://www.mwl-law.com/wp-content/uploads/2018/02/AUTOMOBILE-TOTAL-LOSS-THRESHOLDS-CHART.pdf
- Investopedia — FNOL process overview: https://www.investopedia.com/terms/f/first-notice-loss-fnol.asp
- Moxo — FNOL workflow best practices (severity scoring, adjuster assignment): https://www.moxo.com/blog/fnol-workflow-intake-triage
- Appraisal Engine — Diminished value and 17c formula: https://appraisalengine.com/appraiser-blog/reopen-diminished-value-claim/
- Justia — Bad faith insurance law overview: https://www.justia.com/injury/insurance-bad-faith/
- NAIC — Replacement Cost vs. ACV explainer: https://content.naic.org/article/rebuilding-after-storm-know-difference-between-replacement-cost-and-actual-cash-value-when-it-comes

---

*Feature research for: Multi-agent auto insurance claims processing system (Ohio Mutual Auto)*
*Researched: 2026-02-17*
*Hackathon context: OpenClaw Business Engineering Hackathon, Feb 21 2026, Belgrade*
