# Demo Claim Walkthroughs

Three end-to-end scripted walkthroughs for the Ohio Mutual Auto demo. Each walkthrough includes the claim summary, presenter narration for each stage, expected agent output with realistic field values, audit log entries, and the announced business outcome.

**Usage:** The presenter reads the narration text aloud while the pipeline processes (or while describing expected output if the live demo is unavailable). Each walkthrough corresponds to a test claim JSON file in `shared/test-claims/`.

---

## Walkthrough 1: Happy Path Collision (CLM-2026-00001)

**Test claim file:** `shared/test-claims/happy-path-collision.json`

### Claim Summary

John Smith (POL-AUT-10001) was driving his Honda Accord northbound through the intersection of Main St and Oak Ave in Columbus, OH when Maria Rodriguez ran a red light in her Ford Explorer and struck his vehicle on the front-right corner. An independent witness (David Chen) confirmed the other party was at fault. A Columbus Police report (CPD-2026-018742) was filed. No injuries. Vehicle is drivable but has significant front-end damage on the passenger side. The other party is insured by State Farm (SF-98-7654321).

### Stage-by-Stage Walkthrough

---

#### Stage 1: Front Desk

**Presenter narration:**
> "The Front Desk is now categorizing this claim. It reads the incident description and identifies this as a standard collision -- two vehicles, intersection, clear fault determination. Priority is normal because there are no injuries, no total loss indicators, and no catastrophe event. The report is complete -- we have a police report number, witness contact, and other party insurance information. Nothing is missing."

**Expected pipeline output:**

```json
"front_desk": {
  "completed_at": "2026-02-21T10:30:45Z",
  "agent_session": "agent:front-desk:subagent:<uuid>",
  "category": "collision",
  "priority": "normal",
  "cat_event": null,
  "missing_info": []
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:30:45Z",
  "agent": "front-desk",
  "action": "fnol_intake_complete",
  "reasoning": "Categorized as standard collision based on two-vehicle intersection impact with clear fault determination. Priority normal: no injuries reported, vehicle drivable, no CAT event indicators. FNOL report is complete with police report number CPD-2026-018742, independent witness David Chen, and other party insurance (State Farm SF-98-7654321)."
}
```

---

#### Stage 2: Claims Officer

**Presenter narration:**
> "Now the Claims Officer is verifying coverage. It pulls up policy POL-AUT-10001 -- that is John Smith's standard auto policy. The policy is active, the incident date falls within the policy period, and collision coverage applies. The deductible is 500 dollars and the coverage limit is 50,000 dollars. The Claims Officer reviews all exclusions -- intentional acts, racing, commercial use, excluded drivers -- and none apply. This is a clean, covered claim."

**Expected pipeline output:**

```json
"claims_officer": {
  "completed_at": "2026-02-21T10:31:30Z",
  "agent_session": "agent:claims-officer:subagent:<uuid>",
  "covered": true,
  "policy_status": "active",
  "coverage_type": "collision",
  "deductible_amount": 500,
  "coverage_limit": 50000,
  "exclusions_checked": ["intentional_acts", "racing", "commercial_use", "excluded_drivers"],
  "denial_reason": null,
  "um_uim_route": "not_applicable"
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:31:30Z",
  "agent": "claims-officer",
  "action": "coverage_verified",
  "reasoning": "Policy POL-AUT-10001 is active. Incident date 2026-02-19 falls within policy period. Collision coverage applies to two-vehicle intersection collision. Deductible: $500. Coverage limit: $50,000. All exclusions reviewed: intentional acts (not applicable -- accidental collision), racing (not applicable), commercial use (not applicable -- personal trip), excluded drivers (no excluded drivers on this policy). UM/UIM routing not applicable -- other party has identified insurance (State Farm). Coverage confirmed."
}
```

---

#### Stage 3: Assessor

**Presenter narration:**
> "The Assessor is estimating damage now. Based on the description -- crumpled right fender, broken headlight assembly, damaged bumper cover, slightly buckled hood -- the estimate comes in at approximately 4,200 dollars. This is not a total loss. The Assessor recommends OEM for the headlight assembly because the vehicle is under three years old, but aftermarket is acceptable for the bumper cover. Notice the hidden damage flag -- the description mentions damage extending into the wheel well area, so the Assessor flags hidden damage as likely. That means a supplement payment may be needed after the shop opens it up."

**Expected pipeline output:**

```json
"assessor": {
  "completed_at": "2026-02-21T10:32:45Z",
  "agent_session": "agent:assessor:subagent:<uuid>",
  "repair_estimate_usd": 4200,
  "total_loss": false,
  "acv_usd": null,
  "salvage_value_usd": null,
  "parts_recommendation": "OEM for headlight assembly (vehicle under 3yr/36K mi, safety-critical component); aftermarket acceptable for bumper cover (cosmetic, no safety impact)",
  "labor_hours": 12,
  "rental_days": 5,
  "pre_existing_damage_flags": [],
  "hidden_damage_likely": true
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:32:45Z",
  "agent": "assessor",
  "action": "damage_assessed",
  "reasoning": "Repair estimate $4,200 based on: right fender replacement ($850), headlight assembly replacement ($650 OEM), bumper cover ($400), hood straightening/blend ($750), paint and materials ($550), wheel well inspection and minor repair ($500), alignment check ($150), miscellaneous hardware ($350). 12 labor hours estimated. Not a total loss -- repair cost well below ACV threshold. Hidden damage likely in wheel well area based on description of impact extending into that zone. Recommend supplement eligibility for post-teardown findings. 5 rental days based on parts ordering and repair complexity."
}
```

---

#### Stage 4: Fraud Analyst

**Presenter narration:**
> "The Fraud Analyst is running now. And this is a clean claim. The indicators all point to a legitimate collision: there is an independent witness who is not connected to the claimant, a police report that confirms the other party ran the red light, no injuries being claimed, the damage pattern is consistent with the described impact, and there is no prior suspicious claim history. Risk score: 15 out of 100 -- that is low. No fraud flags. Recommendation: proceed."

**Expected pipeline output:**

```json
"fraud_analyst": {
  "completed_at": "2026-02-21T10:33:30Z",
  "agent_session": "agent:fraud-analyst:subagent:<uuid>",
  "risk_score": 15,
  "risk_level": "low",
  "flags": [],
  "soft_fraud": false,
  "recommendation": "proceed"
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:33:30Z",
  "agent": "fraud-analyst",
  "action": "fraud_analysis_complete",
  "reasoning": "Assessed all 7 fraud patterns. Staged accident: no indicators -- independent witness (David Chen, no relation to claimant), police report confirming other party fault, consistent damage pattern. Phantom passengers: not applicable -- no passengers, no injury claims. Paper accident: not applicable -- police report, witness, other party confirmation. Inflated repair: estimate of $4,200 is proportionate to described damage (front-right corner impact at ~30 mph). Prior damage: no pre-existing damage flags from Assessor. Friendly tow: not applicable. VIN switching: not applicable. Risk score 15 reflects minimal residual uncertainty inherent in any claim. No fraud indicators detected. Recommendation: proceed to review."
}
```

---

#### Stage 5: Senior Reviewer

**Presenter narration:**
> "The Senior Reviewer is now weighing all the evidence. Coverage confirmed. Damage estimate reasonable. Fraud risk low. FCSP timelines are within compliance. And the decision is: APPROVED. The reasoning cites the independent witness, the police report confirming other-party fault, the consistent damage pattern, and the low fraud risk. This is exactly the kind of detailed, defensible decision record that regulators want to see."

**Expected pipeline output:**

```json
"senior_reviewer": {
  "completed_at": "2026-02-21T10:34:15Z",
  "agent_session": "agent:senior-reviewer:subagent:<uuid>",
  "decision": "APPROVED",
  "decision_reasoning": "Straightforward collision claim with strong supporting evidence. Coverage verified on active policy POL-AUT-10001 with collision coverage. Damage estimate of $4,200 is proportionate to described front-right corner impact at approximately 30 mph. Independent witness David Chen corroborates claimant's account. Police report CPD-2026-018742 confirms other party (Maria Rodriguez) ran red light. Fraud analysis returned low risk (15/100) with no flags. All evidence is internally consistent. No basis for denial or conditions. FCSP timeline compliance: claim submitted same day as acknowledgment -- well within 10-15 day acknowledgment window and 40-day decision deadline.",
  "conditions": [],
  "escalated_to_human": false,
  "escalation_reason": null,
  "fcsp_timeline_check": "Within all FCSP deadlines. Acknowledgment and decision rendered same day as submission."
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:34:15Z",
  "agent": "senior-reviewer",
  "action": "claim_approved",
  "reasoning": "APPROVED. All pipeline stages consistent. Coverage confirmed, estimate proportionate, fraud risk low (15/100, no flags), independent witness and police report corroborate account. FCSP compliant. Proceeding to payment."
}
```

---

#### Stage 6: Finance

**Presenter narration:**
> "And now Finance calculates the payment. Repair estimate: 4,200 dollars. Minus the 500 dollar deductible. No depreciation on collision repairs. That gives us a payment of 3,700 dollars. And here is the business value -- Finance identifies this as a subrogation candidate. Maria Rodriguez was at fault and insured by State Farm, policy SF-98-7654321. We are going to recover our 3,700 dollars plus the claimant's deductible from State Farm. The claim also gets flagged as supplement-eligible because of that hidden damage in the wheel well."

**Expected pipeline output:**

```json
"finance": {
  "completed_at": "2026-02-21T10:35:00Z",
  "agent_session": "agent:finance:subagent:<uuid>",
  "payment_amount_usd": 3700,
  "deductible_applied_usd": 500,
  "depreciation_applied_usd": 0,
  "subrogation_candidate": true,
  "subrogation_target": "State Farm / Maria Rodriguez / SF-98-7654321",
  "payment_method": "direct_deposit",
  "payment_reference": "PAY-2026-00001",
  "supplement_eligible": true
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T10:35:00Z",
  "agent": "finance",
  "action": "payment_issued",
  "reasoning": "Payment calculated: $4,200 repair estimate - $500 deductible = $3,700. No depreciation applied (collision coverage pays repair cost, vehicle not a total loss). Payment method: direct deposit. Subrogation flagged: other party Maria Rodriguez at fault, insured by State Farm (SF-98-7654321) -- recovery of insurer costs plus claimant deductible. Supplement eligible: hidden damage likely in wheel well area per Assessor; additional payment may be issued after repair shop teardown and supplemental estimate."
}
```

---

### Business Outcome

**Final status:** PAYMENT_ISSUED

**Claim APPROVED.** $3,700 payment issued to John Smith via direct deposit. Subrogation filed against State Farm (Maria Rodriguez, policy SF-98-7654321) to recover insurer costs. Supplement-eligible for additional hidden damage findings.

**What this demonstrates:** Efficient, compliant claims processing. Six agents processed this claim through the full pipeline with a complete audit trail documenting every decision, every reasoning step, and every regulatory compliance check. This is what regulators want to see. This is what protects the insurer from bad faith claims.

---
---

## Walkthrough 2: Fraud Rejection / SIU Referral (CLM-2026-00002)

**Test claim file:** `shared/test-claims/fraud-rejection-siu.json`

### Claim Summary

John Smith (POL-AUT-10001) again, filing a second claim. This time it is a low-speed parking lot rear-end at the Eastland Mall exit. A white Toyota Camry struck the rear of his Honda Accord at approximately 5 to 10 mph. The critical details: four passengers (Marcus Williams, Terrell Jackson, Devon Harris, Anthony Brown) all claiming soft tissue injuries and whiplash from this low-speed impact. All passengers and Smith have retained the same attorney, Lawrence Mitchell. The witnesses (Dwayne Cooper and Rashid Thompson) are friends of the claimant who were in the car behind. Smith had a similar parking lot incident 8 months ago. The rear bumper shows only scuffing and a small crack.

### Stage-by-Stage Walkthrough

---

#### Stage 1: Front Desk

**Presenter narration:**
> "The Front Desk categorizes this as a collision claim with normal priority. At this stage, the Front Desk does not have enough context to flag fraud -- that comes later. It notes that injuries are reported, which is factual. The claim data is complete."

**Expected pipeline output:**

```json
"front_desk": {
  "completed_at": "2026-02-21T11:00:35Z",
  "agent_session": "agent:front-desk:subagent:<uuid>",
  "category": "collision",
  "priority": "normal",
  "cat_event": null,
  "missing_info": []
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:00:35Z",
  "agent": "front-desk",
  "action": "fnol_intake_complete",
  "reasoning": "Categorized as collision based on rear-end impact in parking lot. Priority normal: injuries reported (soft tissue) but incident is low-speed parking lot collision. No CAT event indicators. FNOL report complete with police report number CPD-2026-017865, two witnesses, and other party insurance (Progressive PGR-44-2198765). Note: injuries reported by 4 passengers."
}
```

---

#### Stage 2: Claims Officer

**Presenter narration:**
> "The Claims Officer verifies coverage. Same policy as before, POL-AUT-10001, still active. Collision coverage applies. 500 dollar deductible. No exclusions triggered. The Claims Officer does not evaluate fraud -- that is the Fraud Analyst's job. Coverage is confirmed."

**Expected pipeline output:**

```json
"claims_officer": {
  "completed_at": "2026-02-21T11:01:20Z",
  "agent_session": "agent:claims-officer:subagent:<uuid>",
  "covered": true,
  "policy_status": "active",
  "coverage_type": "collision",
  "deductible_amount": 500,
  "coverage_limit": 50000,
  "exclusions_checked": ["intentional_acts", "racing", "commercial_use", "excluded_drivers"],
  "denial_reason": null,
  "um_uim_route": "not_applicable"
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:01:20Z",
  "agent": "claims-officer",
  "action": "coverage_verified",
  "reasoning": "Policy POL-AUT-10001 is active. Incident date 2026-02-18 falls within policy period. Collision coverage applies to rear-end parking lot collision. Deductible: $500. Coverage limit: $50,000. All exclusions reviewed -- none apply. Coverage confirmed."
}
```

---

#### Stage 3: Assessor

**Presenter narration:**
> "The Assessor examines the damage. And this is where the numbers start telling a story. A 5 to 10 mph parking lot bump produced only scuffing and a small crack in the bumper cover. The estimate is just 850 dollars -- minor cosmetic repair. Three hours of labor. No rental needed because the vehicle is drivable and it is a quick fix. No hidden damage expected from a low-speed impact. No pre-existing damage flags either. Remember this number -- 850 dollars of damage, but four people claiming injuries."

**Expected pipeline output:**

```json
"assessor": {
  "completed_at": "2026-02-21T11:02:30Z",
  "agent_session": "agent:assessor:subagent:<uuid>",
  "repair_estimate_usd": 850,
  "total_loss": false,
  "acv_usd": null,
  "salvage_value_usd": null,
  "parts_recommendation": "Aftermarket bumper cover (cosmetic repair, no safety impact)",
  "labor_hours": 3,
  "rental_days": 0,
  "pre_existing_damage_flags": [],
  "hidden_damage_likely": false
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:02:30Z",
  "agent": "assessor",
  "action": "damage_assessed",
  "reasoning": "Repair estimate $850 based on: rear bumper cover replacement ($350 aftermarket), paint and materials ($250), scuff repair and blending ($150), hardware and clips ($100). 3 labor hours. Not a total loss. Vehicle is drivable -- no rental days needed for minor repair. Low-speed impact (5-10 mph) with minimal energy transfer. Hidden damage unlikely given the low impact speed and superficial damage pattern. No pre-existing damage indicators observed."
}
```

---

#### Stage 4: Fraud Analyst

**Presenter narration:**
> "Now watch the Fraud Analyst. This is where our system really earns its keep. The Fraud Analyst reads the entire claim -- the incident description, the Assessor's estimate, and all the contextual details. And it detects FOUR converging fraud patterns."

> "Pattern one: Phantom passengers. Four passengers in a sedan, all claiming soft tissue injuries from a 5 to 10 mph impact. The physics do not support whiplash at that speed with that level of damage."

> "Pattern two: Staged accident. Low-speed impact with disproportionate injury claims. The witnesses are friends of the claimant, not independent bystanders."

> "Pattern three: Prior damage history. Smith had a similar parking lot incident just 8 months ago."

> "Pattern four: Attorney representation. The same attorney, Lawrence Mitchell, is representing multiple parties from a single incident. That is a common indicator of organized claim fraud."

> "Notice that no single flag would justify an SIU referral. But four patterns converging? That is indicator convergence. The risk score is 82 out of 100 -- high. The recommendation is SIU referral."

**Expected pipeline output:**

```json
"fraud_analyst": {
  "completed_at": "2026-02-21T11:03:45Z",
  "agent_session": "agent:fraud-analyst:subagent:<uuid>",
  "risk_score": 82,
  "risk_level": "high",
  "flags": [
    {
      "pattern": "phantom_passengers",
      "description": "4 passengers in sedan claiming soft tissue injuries from low-speed impact (~5-10 mph). Damage estimate of only $850 is inconsistent with injury-producing forces. Physics of low-speed rear-end impact do not typically produce whiplash in 5 occupants.",
      "severity": "high"
    },
    {
      "pattern": "staged_accident",
      "description": "Low-speed parking lot impact with disproportionate injury claims. Both witnesses (Dwayne Cooper, Rashid Thompson) are friends of claimant who were in the car behind -- not independent bystanders. Witness statements emphasize the low speed ('barely a tap') while claimant reports significant injuries.",
      "severity": "high"
    },
    {
      "pattern": "prior_damage_history",
      "description": "Claimant references a similar parking lot incident 8 months ago. Pattern of low-speed parking lot collisions raises concern about repeated claim behavior.",
      "severity": "medium"
    },
    {
      "pattern": "attorney_representation",
      "description": "Same attorney (Lawrence Mitchell at Mitchell & Associates) representing claimant and multiple passengers from a single incident. Pre-arranged legal representation across multiple parties is a known indicator of organized claim fraud.",
      "severity": "medium"
    }
  ],
  "soft_fraud": false,
  "recommendation": "SIU_REFERRAL"
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:03:45Z",
  "agent": "fraud-analyst",
  "action": "fraud_analysis_complete",
  "reasoning": "HIGH RISK -- SIU REFERRAL RECOMMENDED. Four converging fraud indicators detected. (1) Phantom passengers: 4 occupants claiming soft tissue injuries from ~5-10 mph impact; $850 damage estimate is inconsistent with injury-producing collision forces. (2) Staged accident indicators: low-speed impact, disproportionate injury claims, non-independent witnesses (friends of claimant in following vehicle). Witness statements describe 'barely a tap' while 5 people report injuries. (3) Prior history: similar parking lot incident 8 months prior. (4) Shared attorney: Lawrence Mitchell representing multiple parties from same incident. Individual indicators could have innocent explanations, but the convergence of all four patterns strongly suggests organized claim fraud (hard fraud, not soft fraud). Recommend SIU investigation before any payment authorization."
}
```

---

#### Stage 5: Senior Reviewer

**Presenter narration:**
> "The Senior Reviewer sees the fraud analysis and makes the call: ESCALATE to a human. This is not an outright denial -- the system is smart enough to know that flagging fraud does not mean the claim is fraudulent. But with four high-severity converging indicators, the AI cannot make a confident decision. It escalates to the Special Investigations Unit for a human investigation. Notice the FCSP timeline note -- the investigation exception pauses the regulatory clock."

**Expected pipeline output:**

```json
"senior_reviewer": {
  "completed_at": "2026-02-21T11:04:30Z",
  "agent_session": "agent:senior-reviewer:subagent:<uuid>",
  "decision": "ESCALATE_HUMAN",
  "decision_reasoning": "Multiple high-severity fraud indicators converging: phantom passenger pattern (4 injury claims from low-speed impact), staged accident indicators (non-independent witnesses, disproportionate claims), prior claim history (similar incident 8 months ago), and shared attorney representation across multiple parties. Fraud Analyst risk score 82/100 with SIU referral recommendation. The convergence of these indicators exceeds the threshold for confident AI adjudication. SIU investigation is warranted before any payment authorization. Property damage portion ($850) may be legitimate, but injury claims require human investigation. Escalation protects both the insurer (from paying potentially fraudulent claims) and the claimant (from wrongful denial if investigation clears them).",
  "conditions": [],
  "escalated_to_human": true,
  "escalation_reason": "Multiple high-severity fraud indicators converging. SIU investigation recommended before payment authorization.",
  "fcsp_timeline_check": "FCSP timeline paused pending investigation per fraud investigation exception. Investigation must be conducted in good faith and with reasonable diligence."
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:04:30Z",
  "agent": "senior-reviewer",
  "action": "claim_escalated",
  "reasoning": "ESCALATE_HUMAN. Four converging fraud indicators (phantom passengers, staged accident, prior history, shared attorney) exceed AI adjudication confidence. SIU referral for human investigation. FCSP timeline paused under fraud investigation exception."
}
```

---

#### Stage 6: Finance

**NOT REACHED.** Pipeline stops at Senior Reviewer escalation. No payment is authorized for escalated claims.

**Presenter narration:**
> "Notice that Finance never runs. The pipeline stops at the Senior Reviewer's escalation. No payment is issued until the human investigation is complete. This is the system working as designed -- the AI flags the concern, documents every indicator, and hands it to a human for the final call."

---

### Business Outcome

**Final status:** ESCALATED

**Claim ESCALATED to SIU (Special Investigations Unit).** No payment issued. The Fraud Analyst detected 4 converging indicators that a human adjuster might miss when reviewing each in isolation. The audit trail documents exactly why the claim was flagged -- protecting the insurer from paying fraudulent claims AND from bad faith claims if the investigation clears the claimant.

**What this demonstrates:** The Fraud Analyst does not deny claims. It flags patterns and recommends investigation. The Senior Reviewer makes the escalation decision based on the totality of evidence. The audit trail protects the insurer in both directions: if the claim is fraudulent, the documentation supports the investigation; if the claimant is cleared, the documentation shows the investigation was conducted in good faith based on objective indicators.

---
---

## Walkthrough 3: Coverage Denial / Excluded Driver (CLM-2026-00003)

**Test claim file:** `shared/test-claims/coverage-denial-exclusion.json`

### Claim Summary

Robert Wilson (POL-AUT-10003) files a claim for his 2024 Ford F-150. His nephew Michael Johnson was driving the truck westbound on I-275 near Cincinnati when traffic slowed suddenly in a construction zone. Michael rear-ended a Chevrolet Tahoe driven by Sandra Mitchell. Highway Patrol cited Michael for following too closely. Front-end damage to bumper, grille, hood, and possible radiator compromise. The critical fact: Michael Johnson is listed as an excluded driver on policy POL-AUT-10003.

### Stage-by-Stage Walkthrough

---

#### Stage 1: Front Desk

**Presenter narration:**
> "The Front Desk categorizes this as a standard collision. Normal priority -- no injuries, no catastrophe event. At this stage, the Front Desk does not know about the excluded driver situation. That is the Claims Officer's job."

**Expected pipeline output:**

```json
"front_desk": {
  "completed_at": "2026-02-21T11:30:30Z",
  "agent_session": "agent:front-desk:subagent:<uuid>",
  "category": "collision",
  "priority": "normal",
  "cat_event": null,
  "missing_info": []
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:30:30Z",
  "agent": "front-desk",
  "action": "fnol_intake_complete",
  "reasoning": "Categorized as collision based on rear-end impact on I-275. Priority normal: no injuries reported, police report filed (OSHP-2026-004521). Note: vehicle was driven by Robert Wilson's nephew Michael Johnson at time of incident. FNOL report complete."
}
```

---

#### Stage 2: Claims Officer

**Presenter narration:**
> "Now the Claims Officer pulls up policy POL-AUT-10003. The policy is active. But as it reviews the exclusions, it finds the critical issue: Michael Johnson is listed as an excluded driver on this policy. The policy explicitly excludes Michael Johnson from coverage. Since Michael was driving at the time of the incident, the excluded driver exclusion applies. Coverage is denied."

> "This is where the coverage denial shortcut kicks in. The pipeline SKIPS the Assessor, Fraud Analyst, and Finance. There is no point estimating damage on an uncovered claim. There is no point analyzing fraud on a denied claim. But the claim does go to the Senior Reviewer -- because every denial needs a bad faith risk assessment."

**Expected pipeline output:**

```json
"claims_officer": {
  "completed_at": "2026-02-21T11:31:15Z",
  "agent_session": "agent:claims-officer:subagent:<uuid>",
  "covered": false,
  "policy_status": "active",
  "coverage_type": "collision",
  "deductible_amount": null,
  "coverage_limit": null,
  "exclusions_checked": ["excluded_drivers"],
  "denial_reason": "Vehicle operated by Michael Johnson who is listed as an excluded driver on policy POL-AUT-10003. Excluded driver exclusion applies per policy terms. Policy specifically names Michael Johnson as excluded from all coverage under this policy.",
  "um_uim_route": null
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:31:15Z",
  "agent": "claims-officer",
  "action": "coverage_denied",
  "reasoning": "Policy POL-AUT-10003 is active. However, the vehicle was operated by Michael Johnson at the time of the incident. Michael Johnson is explicitly listed as an excluded driver on this policy. The excluded driver exclusion is clear and unambiguous -- the policy specifically names Michael Johnson. Coverage denied per excluded driver exclusion. No ambiguity to construe in claimant's favor (the exclusion names a specific individual, not a class of drivers). Note: this triggers the coverage denial shortcut -- pipeline skips Assessor, Fraud Analyst, and Finance, proceeding directly to Senior Reviewer for bad faith risk assessment."
}
```

---

#### Stage 3: Assessor -- SKIPPED

**Pipeline shortcut:** Coverage denied. Damage assessment is not performed on uncovered claims.

#### Stage 4: Fraud Analyst -- SKIPPED

**Pipeline shortcut:** Coverage denied. Fraud analysis is not performed on denied claims.

---

#### Stage 5: Senior Reviewer

**Presenter narration:**
> "The Senior Reviewer receives this as a coverage denial review, not a standard approval request. Its job here is to confirm the denial is defensible and assess bad faith risk. And the answer is clear: the excluded driver exclusion is unambiguous. The policy specifically names Michael Johnson. There is no ambiguity to construe in the claimant's favor. Bad faith risk is low -- this is a clear-cut policy exclusion. The denial stands."

**Expected pipeline output:**

```json
"senior_reviewer": {
  "completed_at": "2026-02-21T11:32:00Z",
  "agent_session": "agent:senior-reviewer:subagent:<uuid>",
  "decision": "DENIED",
  "decision_reasoning": "Coverage correctly denied per excluded driver exclusion on policy POL-AUT-10003. Policy explicitly excludes Michael Johnson by name. The exclusion language is clear and unambiguous -- it specifically identifies the excluded individual, leaving no room for interpretation. The ambiguity doctrine does not apply because there is no ambiguity in the exclusion language. Bad faith risk assessment: LOW. The denial is well-documented with specific policy language reference. The Claims Officer's reasoning correctly identifies the applicable exclusion and documents it thoroughly. FCSP compliance: denial notification must be issued within required timeframe with specific reference to the policy provision supporting the denial.",
  "conditions": [],
  "escalated_to_human": false,
  "escalation_reason": null,
  "fcsp_timeline_check": "Within all FCSP deadlines for denial notification. Denial letter must cite specific policy exclusion language per FCSP requirements."
}
```

**Expected audit log entry:**

```json
{
  "timestamp": "2026-02-21T11:32:00Z",
  "agent": "senior-reviewer",
  "action": "denial_confirmed",
  "reasoning": "DENIED. Excluded driver exclusion is unambiguous -- policy POL-AUT-10003 names Michael Johnson specifically. Bad faith risk: LOW. Denial is defensible. FCSP compliant."
}
```

---

#### Stage 6: Finance -- SKIPPED

**Pipeline shortcut:** Coverage denied. No payment is processed for denied claims.

**Presenter narration:**
> "Finance is never reached. No payment is issued. The pipeline processed this claim through only three agents instead of six -- Front Desk, Claims Officer, and Senior Reviewer. Three agents were skipped entirely. This is the coverage denial shortcut in action: efficient processing that does not waste time or tokens on uncovered claims, while still ensuring every denial gets supervisory review for bad faith protection."

---

### Business Outcome

**Final status:** DENIED

**Claim DENIED.** The excluded driver exclusion is clear and unambiguous. Michael Johnson is specifically named as an excluded driver on policy POL-AUT-10003. The Senior Reviewer confirms the denial is defensible and documents the bad faith risk assessment as LOW. The audit trail shows exactly why coverage was denied -- this is the documentation that protects the insurer if the claimant disputes the denial.

**What this demonstrates:** The coverage denial shortcut saves processing time by skipping three pipeline stages that are irrelevant for uncovered claims. But the Senior Reviewer still reviews every denial to protect against bad faith exposure. The audit trail documents every exclusion checked and the specific policy language supporting the denial -- this is what protects the insurer in a coverage dispute or regulatory inquiry.

---
---

## Presenter Narration Style Guide

### General Principles

- **Speak in present tense** as agents process: "The Front Desk is now categorizing this as a collision claim..."
- **Highlight surprising moments:** "Notice that the Fraud Analyst detected FOUR converging patterns..."
- **Connect to business value:** "This audit log entry is exactly what a regulator would want to see..."
- **Keep it conversational** -- read the narration naturally, not robotically
- **Fill processing gaps** with context about what the agent is doing and why

### Key Emphasis Points by Walkthrough

**Happy Path (CLM-2026-00001):**
- Emphasize speed and completeness: "Six agents, full audit trail, minutes instead of weeks"
- Highlight subrogation: "We are recovering our costs from the at-fault party's insurer"
- Point to the audit log: "Every decision documented for regulatory compliance"

**Fraud (CLM-2026-00002):**
- Build tension with each fraud flag: "Pattern one... pattern two... pattern three... pattern four..."
- Emphasize convergence: "No single flag would justify a referral. But four patterns converging..."
- Highlight the protection angle: "The audit trail protects the insurer AND the claimant"

**Denial (CLM-2026-00003):**
- Emphasize the shortcut: "Three agents skipped -- no wasted processing on uncovered claims"
- Point to bad faith protection: "Even denied claims get supervisory review"
- Highlight documentation: "The denial letter can cite the exact policy language and reasoning"

### Transitioning Between Walkthroughs (if running all three)

After the happy path: "That was a clean, straightforward claim. Now let me show you what happens when the system encounters something suspicious..."

After the fraud walkthrough: "Two very different outcomes from the same system. Let me show you one more -- what happens when coverage does not apply..."

After the denial walkthrough: "Three claims. Three different outcomes. One system. Complete audit trails for all three."

---

*Demo walkthroughs for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*3 scripted scenarios: Happy Path, Fraud/SIU Referral, Coverage Denial*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
