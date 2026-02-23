# Edge Case Catalog

## Purpose

This is the team's Q&A defense document for every edge case scenario judges are likely to raise. For each edge case: what it is, why judges might ask about it, what the system does (or acknowledges), and a one-sentence answer the team can deliver.

---

## Quick Reference

| Edge Case | System Handles | Q&A Ready |
|-----------|---------------|-----------|
| 1. Total Loss | Yes -- Ohio 100% ACV rule, salvage, GAP awareness | Yes |
| 2. Pre-existing Damage | Yes -- detection flags, conditional approval | Yes |
| 3. Diminished Value (17c) | Awareness only -- knows formula, does not compute | Yes |
| 4. UM/UIM Routing | Awareness only -- knows concept, shows field in schema | Yes |
| 5. Claim Reopening / Supplements | Yes -- supplement payment path in Finance | Yes |
| 6. CAT Events | Yes -- Front Desk tags, Assessor and Fraud aware | Yes |
| 7. Claim Denial Bad Faith Risk | Yes -- denial documentation requirements enforced | Yes |
| 8. Legal Representation | Yes -- escalation trigger for Senior Reviewer | Yes |
| 9. Multi-Vehicle Incidents | Awareness -- linked claims concept, fraud risk | Yes |
| 10. Policy Endorsements / Riders | Yes -- Claims Officer checks endorsements | Yes |

---

## 1. Total Loss Handling

### What It Is

A vehicle is declared a total loss when the cost to repair equals or exceeds the vehicle's Actual Cash Value (ACV). The threshold varies by state. Ohio uses the **100% ACV rule** -- the vehicle is totaled when repair cost equals or exceeds ACV. This is one of the stricter thresholds; most states use 70-80% of ACV.

### Why Judges Might Ask

Total loss determination is a core claims processing concept. Getting the threshold wrong (or not knowing Ohio's specific rule) is a credibility failure. Judges will probe whether the team understands the financial mechanics: what happens to the vehicle, what the policyholder receives, and what happens if the loan balance exceeds the ACV.

### What the System Does

- **Assessor** compares repair estimate against the vehicle's ACV. If repair cost >= ACV, the Assessor declares total loss.
- **Payout calculation:** ACV minus deductible. If the policyholder retains the salvage, a salvage retention credit is also deducted.
- **Salvage title:** The totaled vehicle receives a salvage title. The policyholder has the option to retain the vehicle (reduced payout) or surrender it.
- **Rental on total loss:** Typically 10-day cap after total loss declaration (time to locate replacement vehicle).
- **GAP insurance awareness:** Finance notes that if the loan balance exceeds ACV, GAP insurance would cover the difference. Finance does not process the GAP claim itself.

### One-Sentence Answer

"Our Assessor compares repair cost against ACV using Ohio's 100% threshold, and if it's a total loss, Finance calculates the payout as ACV minus deductible, with GAP awareness flagged for cases where the loan exceeds the vehicle's value."

---

## 2. Pre-existing Damage

### What It Is

Damage to the vehicle that existed before the claimed incident. Only damage caused by the current incident is covered. Pre-existing damage must be identified, documented, and excluded from the claim payout.

### Why Judges Might Ask

Pre-existing damage is one of the most common sources of claim disputes between insurers and policyholders. It is also a soft fraud vector -- claimants may attempt to include old damage in a new claim. Judges want to see that the system considers this distinction rather than blindly accepting all reported damage.

### What the System Does

- **Assessor** looks for pre-existing damage indicators:
  - Rust on impact areas (fresh collision damage does not have rust)
  - Paint oxidation on damaged panels (indicates older damage)
  - Damage in non-impact zones (inconsistent with the described incident)
  - Evidence of prior repairs (mismatched paint, aftermarket parts already installed, visible body filler)
- **Conditional approval:** When pre-existing damage is detected, the Assessor flags the claim for conditional approval pending physical inspection
- **Dispute resolution:** If the policyholder disputes the pre-existing damage finding, the independent appraisal process is available
- **Audit log:** The Assessor documents which damage is consistent with the described incident and which appears pre-existing, with reasoning

### One-Sentence Answer

"Our Assessor flags pre-existing damage indicators like rust on fresh impact areas or damage in non-impact zones, issues a conditional approval pending inspection, and documents exactly which damage is incident-related versus pre-existing."

---

## 3. Diminished Value (17c Formula)

### What It Is

Diminished value (DV) is the loss in resale value a vehicle suffers after being in a collision, even when the repair is perfect. A car with a collision history is worth less than an identical car without one. Some states require insurers to address DV claims proactively.

### Why Judges Might Ask

Most hackathon teams will not know this concept exists. Being able to explain the 17c formula demonstrates deep domain knowledge that goes beyond basic claims processing. Judges may ask "What about the vehicle's resale value after repair?" to test this awareness.

### The 17c Formula

The 17c formula (State Farm's method, widely referenced in the industry):

1. **Base Diminished Value** = 10% of pre-accident retail value (from KBB or NADA)
2. **Damage Modifier** = 0.00 to 1.00 based on severity:
   - 1.00 = severe structural damage
   - 0.75 = major damage to structure and panels
   - 0.50 = moderate damage to structure or panels
   - 0.25 = minor damage to outer panels only
   - 0.00 = no structural damage (cosmetic only)
3. **Mileage Modifier** = 0.00 to 1.00 based on odometer:
   - 1.00 = 0 - 19,999 miles
   - 0.80 = 20,000 - 39,999 miles
   - 0.60 = 40,000 - 59,999 miles
   - 0.40 = 60,000 - 79,999 miles
   - 0.20 = 80,000 - 99,999 miles
   - 0.00 = 100,000+ miles

**Formula:** Base DV x Damage Modifier x Mileage Modifier = Diminished Value

**Example:** A vehicle with pre-accident retail value of $25,000, moderate structural damage (0.50), and 35,000 miles (0.80):
- Base DV = $25,000 x 10% = $2,500
- DV = $2,500 x 0.50 x 0.80 = **$1,000**

### What the System Does

- **Senior Reviewer** notes DV awareness when applicable (vehicles that are repairable, not total losses)
- The system does not compute DV automatically -- it is an awareness flag, not a calculator
- If a DV claim is expected (newer vehicle with significant structural damage), the Senior Reviewer notes this in the decision rationale

### One-Sentence Answer

"We're aware of diminished value -- the 17c formula calculates it as 10% of pre-accident value times damage severity and mileage modifiers -- and our Senior Reviewer flags DV awareness on applicable claims, though we don't build a full DV calculator for the demo."

---

## 4. Uninsured/Underinsured Motorist (UM/UIM)

### What It Is

When the at-fault party has no insurance (UM) or insufficient insurance (UIM), the claim routes to the policyholder's own UM/UIM coverage. This is a completely different coverage path from standard collision or liability claims.

- **UM (Uninsured Motorist):** The at-fault driver has NO insurance at all. The insured's own UM coverage pays for the insured's damages.
- **UIM (Underinsured Motorist):** The at-fault driver has insurance but the limits are too low to cover the insured's damages. The insured's UIM coverage pays the gap between the at-fault driver's coverage and the actual damages.

### Why Judges Might Ask

UM/UIM routing demonstrates that the team understands the difference between filing under your own coverage versus the other party's coverage. It is a common real-world scenario that many teams will miss. Judges may ask "What happens if the other driver doesn't have insurance?"

### What the System Does

- **Claims Officer** identifies UM/UIM scenarios early during coverage verification:
  - Other party has no insurance information -> UM path
  - Other party's coverage limits are insufficient -> UIM path
- **Different coverage path:** UM/UIM has its own limits and deductibles separate from collision coverage
- **Schema field:** The claim schema includes a `coverage_type` field that can be set to `UM` or `UIM`, showing the system is aware of these paths
- **Routing:** Claims Officer routes UM/UIM claims through a different coverage check (the insured's own UM/UIM limits) rather than the standard collision path

### One-Sentence Answer

"If the at-fault party is uninsured or underinsured, our Claims Officer identifies this early and routes the claim to the policyholder's own UM or UIM coverage, which has separate limits and deductibles from collision coverage."

---

## 5. Claim Reopening / Supplements

### What It Is

Hidden damage discovered during the repair process that was not visible in the initial damage assessment. This is common -- the initial estimate is based on what can be seen without disassembly. Once the repair shop starts work (removes bumper covers, inner fenders, etc.), additional damage is frequently found behind panels and structural components.

**Industry statistic:** 30-40% of collision claims have supplements.

### Why Judges Might Ask

Supplements are standard in the industry and judges know this. If the system only handles one-shot estimates with no supplement path, it looks incomplete. Judges may ask "What happens when the repair shop finds more damage?"

### What the System Does

- **Assessor** flags "hidden damage likely" when the initial assessment involves structural damage, deep panel deformation, or airbag deployment -- conditions where hidden damage is common
- **Senior Reviewer** can pre-authorize a supplement threshold: an amount up to which the repair shop can proceed without a new approval cycle
- **Finance** has a supplement payment path: additional payment on the same claim ID, not a new claim
- **Same claim ID:** Supplements are additional estimates and payments on the existing claim. No new claim is opened.
- **Audit trail:** The original estimate, supplement request, and additional authorization are all logged on the same claim

### One-Sentence Answer

"Our Assessor flags when hidden damage is likely, the Senior Reviewer can pre-authorize a supplement threshold, and Finance issues supplemental payments on the same claim -- about 30-40% of collision claims have supplements in practice."

---

## 6. Weather Surge / CAT (Catastrophic) Events

### What It Is

A natural disaster (hailstorm, flood, tornado, hurricane) that causes a large volume of claims in a concentrated area and timeframe. CAT events fundamentally change how claims are processed: surge capacity, prioritization, and potential for temporarily relaxed processing timelines.

### Why Judges Might Ask

CAT events test whether the team understands that claims processing is not static -- external events change priorities, capacity, and even coverage types. Judges may ask "What happens when a hailstorm hits and you get 500 claims in one day?"

### What the System Does

- **Front Desk** tags the claim with a CAT event identifier when:
  - The date and location match a known weather event
  - Multiple claims are arriving from the same area in the same time window
  - The damage type is weather-related (hail, flood, wind)
- **Coverage type matters:** Weather damage is **comprehensive** (not collision). This distinction affects which coverage the Claims Officer checks and which deductible applies.
- **Processing priority:** CAT-tagged claims may receive expedited processing or modified adjuster assignment
- **Fraud risk in CAT events:** CAT events create heightened fraud risk:
  - Prior damage claimed as storm damage
  - Inflated repair estimates when shops know demand exceeds supply
  - Claims from areas outside the actual event footprint
- **Fraud Analyst** is aware of CAT context and applies additional scrutiny for these patterns

### One-Sentence Answer

"Front Desk tags CAT events based on date, location, and damage type, which affects coverage routing (weather is comprehensive, not collision), processing priority, and Fraud Analyst scrutiny for CAT-specific fraud patterns like pre-existing damage claimed as storm damage."

---

## 7. Claim Denial Bad Faith Risk

### What It Is

Every claim denial carries potential bad faith liability if not handled properly. A denial must be based on a documented, reasonable investigation with specific policy provisions cited. "We deny because we think it's fraud" without thorough investigation is itself a violation of good faith claims handling.

### Why Judges Might Ask

Denial is one of the three claim outcomes the demo must handle (approved, fraud rejection, coverage denial). Judges will probe whether the team understands the legal exposure that comes with denying a claim. A system that can deny claims but cannot document why is a regulatory liability.

### What the System Does

The proper denial path enforced by the system:

1. **Investigate thoroughly** -- The denial cannot come before a complete investigation. Claims Officer, Assessor, and Fraud Analyst must all complete their work before a denial is issued.
2. **Document findings** -- Every investigation step is logged with reasoning in the audit trail.
3. **Cite specific policy provision** -- The denial must reference the exact exclusion, limitation, or policy provision that supports the denial. "Commercial use on personal policy exclusion, Section 4.3.b" -- not just "excluded."
4. **Written denial** -- The policyholder receives a written explanation that includes the specific basis for denial.
5. **Appeal rights** -- The denial notice must inform the policyholder of their right to appeal or seek independent appraisal.
6. **Senior Reviewer oversight** -- No denial is issued without Senior Reviewer authorization. The Fraud Analyst can flag and recommend, but cannot deny.

### One-Sentence Answer

"Every denial requires a thorough investigation, a specific policy provision citation, a written explanation to the policyholder, appeal rights notification, and Senior Reviewer authorization -- skipping any of these steps creates bad faith exposure."

---

## 8. Legal Representation

### What It Is

When the insured hires an attorney to represent them in the claim process. This changes the dynamics of the claim: all communication must go through the attorney, claim value expectations typically increase, and the claim requires Senior Reviewer attention.

### Why Judges Might Ask

Attorney involvement is a real-world escalation trigger that tests whether the system can adapt its behavior. Judges may ask "What happens when the claimant gets a lawyer?"

### What the System Does

- **Escalation trigger:** When a letter of representation is received or the insured indicates they have legal counsel, the claim is escalated to the Senior Reviewer for human-in-the-loop oversight
- **Communication routing:** All further communication goes through the attorney. The system does not communicate directly with the insured after attorney involvement is noted.
- **Claim value awareness:** Attorney involvement typically increases the expected claim value. The Senior Reviewer factors this into the decision.
- **Not adversarial:** The system does not treat attorney involvement as inherently suspicious or adversarial. The insured has the right to representation.
- **Audit trail:** The date and context of attorney involvement are logged. All subsequent decisions note that legal representation is active.

### One-Sentence Answer

"Attorney involvement triggers Senior Reviewer escalation, routes all communication through counsel, and is logged in the audit trail -- it's an escalation trigger, not a fraud indicator, because the insured has a right to representation."

---

## 9. Multi-Vehicle Incidents

### What It Is

Incidents involving more than two vehicles. These create complexity in liability determination, multiple simultaneous claims, and potential fraud exposure (staged multi-vehicle incidents).

### Why Judges Might Ask

Multi-vehicle incidents test whether the system can handle complexity beyond the simple two-car collision. Judges may ask "What about a three-car pile-up?"

### What the System Does

- **Separate claims, linked for investigation:** Each vehicle involved is a separate claim with its own claim ID, but all claims from the same incident are linked by incident reference
- **Liability complexity:** Fault may be shared among multiple parties. Each claim's liability determination considers the full incident context.
- **Fraud risk:** Staged multi-vehicle incidents are a known fraud pattern:
  - **Swoop-and-squat:** One vehicle cuts off another, causing a rear-end chain reaction
  - **Multiple claimants with the same attorney** -- potential organized ring
  - **Phantom passengers across multiple vehicles**
- **Subrogation complexity:** When multiple at-fault parties exist, subrogation recovery may involve multiple third-party insurers
- **Fraud Analyst** is aware of multi-vehicle fraud patterns and applies additional scrutiny when multiple claims reference the same incident

### One-Sentence Answer

"Multi-vehicle incidents create separate but linked claims, with the Fraud Analyst specifically watching for staged accident patterns like swoop-and-squat, and subrogation potentially involving recovery from multiple at-fault parties."

---

## 10. Policy Endorsements / Riders

### What It Is

Non-standard additions to the base auto insurance policy that modify or extend coverage. Endorsements can add coverage (rental car, roadside assistance, OEM parts), increase limits, or change terms.

### Why Judges Might Ask

Endorsements demonstrate that the team understands policies are not one-size-fits-all. Judges may ask "What if the policy has a special endorsement?"

### What the System Does

- **Claims Officer** checks endorsements during coverage verification:
  - **Rental car endorsement:** Enables rental reimbursement coverage
  - **Roadside assistance endorsement:** Covers towing and roadside services
  - **OEM parts endorsement:** Requires OEM (Original Equipment Manufacturer) parts for repairs instead of aftermarket
  - **GAP coverage endorsement:** Covers the difference between ACV and loan balance on total loss
  - **Custom equipment endorsement:** Covers aftermarket modifications (wheels, sound system, lift kits)
- **Endorsement overrides:** An endorsement can override standard policy terms. For example, an OEM parts endorsement overrides the Assessor's default ability to recommend aftermarket parts.
- **Must check before routing:** Endorsements must be checked before the claim moves downstream. The Assessor needs to know about OEM endorsements before estimating parts. Finance needs to know about GAP endorsements before calculating total loss payouts.

### One-Sentence Answer

"Claims Officer checks all policy endorsements during coverage verification because endorsements like OEM parts requirements or rental coverage override standard policy terms and directly affect how downstream agents process the claim."

---

## Cross-Cutting Edge Case Patterns

### Edge Cases That Combine

Several edge cases frequently occur together:

- **Total loss + GAP + rental:** When a financed vehicle is totaled, GAP applies and rental is capped at 10 days
- **CAT event + pre-existing damage + fraud:** Storm claims frequently include pre-existing damage claimed as new damage
- **Multi-vehicle + UM/UIM:** In a multi-vehicle incident, some at-fault parties may be uninsured
- **Supplements + rental extension:** When hidden damage is found, the repair takes longer and rental needs to be extended
- **Legal representation + denial:** When an attorney is involved and the claim is denied, the documentation requirements are even more critical

### The Team's Edge Case Readiness Test

A team member should be able to:

1. State Ohio's total loss threshold (100% ACV) and explain the payout calculation
2. Describe the 17c diminished value formula with modifiers
3. Explain the difference between UM and UIM coverage
4. Walk through the supplement/claim reopening process
5. Describe CAT event tagging and its impact on processing
6. Explain why every denial needs a specific policy provision citation
7. List three fraud patterns specific to multi-vehicle incidents
8. Name three common endorsements and how they affect claims processing

---

## Sources

- Ohio Department of Insurance -- total loss threshold (100% ACV rule)
- State Farm 17c formula -- diminished value calculation methodology
- NAIC model act -- UM/UIM coverage requirements
- NICB -- staged auto accident fraud patterns (swoop-and-squat, phantom passengers)
- Industry standard practices -- supplements, CAT events, endorsements, legal representation handling
- California FCSP regulations -- denial documentation requirements, bad faith prevention

---
*Domain knowledge reference for: Ohio Mutual Auto Claims Processing System*
*Created: 2026-02-17*
*Hackathon context: OpenClaw Business Engineering Hackathon, Feb 21 2026, Belgrade*
