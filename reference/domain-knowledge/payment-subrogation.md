# Payment Calculation & Subrogation Knowledge Base

## Purpose

This document covers the financial side of claims processing: how payouts are calculated, when and how the insurer recovers from at-fault third parties through subrogation, how rental reimbursement works, and the principles behind depreciation and ACV calculation. Every team member should be able to walk through these concepts from memory during Q&A.

---

## Quick Reference

| Concept | Formula / Rule |
|---------|---------------|
| Standard payout | Damage estimate - deductible |
| ACV policy payout | Damage estimate - deductible - depreciation |
| Total loss payout | ACV - deductible - salvage retention credit (if applicable) |
| Subrogation trigger | At-fault party is a third party with identifiable insurance |
| Rental allowance | $30-50/day, typically 30-day cap (if on policy) |
| Rental on total loss | Typically 10 days max after total loss declaration |

---

## 1. Payment Calculation Methodology

### Standard Payout (Collision or Comprehensive)

The basic formula is straightforward:

**Payout = Damage Estimate - Deductible**

The damage estimate comes from the Assessor agent. The deductible comes from the Claims Officer's coverage verification (read from the policy). Finance calculates the final payout.

**Example:** Damage estimate $4,200, collision deductible $500 = payout of $3,700.

### ACV (Actual Cash Value) Policy Payout

Most auto insurance policies are ACV policies. ACV accounts for depreciation -- the vehicle's loss of value over time due to age, mileage, and wear.

**Payout = Damage Estimate - Deductible - Depreciation**

Depreciation is applied to the parts component of the repair estimate (labor does not depreciate). The exact depreciation amount depends on the vehicle's age, mileage, and condition.

**When ACV matters most:** Total loss situations. When a vehicle is totaled, the payout is the vehicle's ACV minus the deductible, not the repair cost. The ACV is what the vehicle was worth immediately before the loss.

### RCV (Replacement Cost Value) Policy Payout

RCV policies pay the full replacement cost without depreciation deduction. These are less common in auto insurance (more typical in homeowners/property insurance).

**Payout = Full Replacement Cost - Deductible**

For the hackathon: Know RCV exists, explain the distinction from ACV in Q&A, but the system defaults to ACV since that is the standard auto insurance model.

### Total Loss Payout

When repair cost equals or exceeds the vehicle's ACV (Ohio uses the 100% rule), the vehicle is declared a total loss.

**Total Loss Payout = ACV - Deductible - Salvage Retention Credit (if applicable)**

- **ACV determination:** Based on market comparables (KBB, NADA, local dealer pricing) -- what the vehicle was worth immediately before the accident
- **Salvage retention:** If the policyholder chooses to keep the totaled vehicle, a salvage retention credit is deducted from the payout. The vehicle receives a salvage title.
- **GAP insurance awareness:** When the loan balance exceeds the ACV, GAP insurance covers the difference. Finance should note this awareness in total loss cases but does not process the GAP claim itself (separate coverage, separate insurer or endorsement).

---

## 2. Subrogation Logic

### What Subrogation Is

Subrogation is the process by which the insurer, after paying its insured, "steps into the insured's shoes" to recover the payment from the at-fault third party (or their insurer).

**In plain language:** The insurer pays the policyholder first so they are made whole. Then the insurer goes after the person who caused the damage to get the money back.

### When Subrogation Applies

**Trigger conditions:**
- The at-fault party is a third party (not the insured)
- The at-fault party has identifiable insurance (or identifiable assets)
- Liability can be established (police report, witness statements, admission, evidence)
- The insured has filed under their own collision coverage (not the at-fault party's liability coverage)

**When subrogation does NOT apply:**
- The insured was at fault (no third party to recover from)
- The at-fault party is uninsured and has no identifiable assets (recovery unlikely; UM coverage applies instead)
- The insured filed directly against the at-fault party's liability coverage (the at-fault insurer is already paying; no recovery needed)

### Subrogation Workflow

1. **Insurer pays the insured** -- The policyholder receives their payout (damage estimate minus deductible) promptly, regardless of fault determination
2. **Subrogation lien is placed** -- The insurer's right to recovery is formally recorded on the claim
3. **Identify at-fault insurer** -- Using police report, other party's insurance information captured at FNOL
4. **File demand** -- Insurer sends a demand letter to the at-fault party's insurer for the amount paid
5. **Negotiate/recover** -- The at-fault insurer evaluates the demand. Recovery may be full, partial, or denied based on liability determination
6. **Deductible recovery** -- If subrogation is fully successful, the insured gets their deductible back. This is a significant benefit to the policyholder.

### Impact on Claim Status

A claim with a subrogation flag remains open for recovery even after the policyholder has been paid. The claim is not "closed" in the traditional sense -- it transitions to a subrogation recovery status.

**For the system:**
- Finance flags subrogation opportunity when fault determination indicates a third party is at fault
- The claim status includes a subrogation status (PENDING_RECOVERY, RECOVERED, PARTIAL_RECOVERY, RECOVERY_DENIED)
- The audit log documents the subrogation decision and recovery progress

### Q&A Defense Points

- "Subrogation is how the insurer recovers from the at-fault party after paying our insured first."
- "We flag subrogation when there is an identifiable at-fault third party with insurance."
- "The insured gets paid promptly regardless -- subrogation is between insurers."
- "If subrogation is successful, the policyholder gets their deductible back."
- "The claim remains open for subrogation recovery even after the policyholder is paid."

---

## 3. Rental Reimbursement Rules

### Coverage Prerequisite

Rental reimbursement is not included in all auto insurance policies. It is a separate coverage or endorsement that must be on the policy. The Claims Officer verifies whether rental coverage exists during coverage verification.

**If rental coverage is not on the policy:** No rental reimbursement, regardless of the claim outcome.

### Standard Allowance

- **Daily rate:** $30-50/day is the typical allowance range
- **Duration cap:** Typically 30-day maximum for repair scenarios
- **Vehicle class:** Comparable vehicle, not an upgrade. A Honda Civic policyholder gets a mid-size sedan rental, not an SUV.

### Repair Scenario Rental

When the vehicle is repairable:
- **Rental days = Estimated repair days** from the Assessor's repair timeline
- The Assessor estimates repair time based on the scope of work (parts ordering, labor hours, paint/body)
- If repair takes longer than estimated (supplements, parts delays), additional rental days may be authorized

### Total Loss Scenario Rental

When the vehicle is declared a total loss:
- **Rental typically limited to 10 days maximum** after the total loss declaration
- Rationale: This is the reasonable time to locate and purchase a replacement vehicle
- The rental clock starts at total loss declaration, not at FNOL

### System Implementation

- **Claims Officer:** Checks whether rental coverage exists on the policy; records the daily allowance and cap
- **Assessor:** Estimates repair timeline (days); this drives rental entitlement duration
- **Finance:** Calculates rental reimbursement as a separate line item (daily rate x authorized days)

---

## 4. Depreciation and ACV Calculation Principles

### The Core Concept

**ACV = Replacement Cost - Depreciation**

ACV represents what the vehicle was actually worth at the moment of the loss, accounting for its age, mileage, condition, and local market conditions. It is not the original purchase price, not the loan balance, and not what the owner thinks the vehicle is worth.

### Depreciation Factors

Depreciation is not a single formula. It is a professional judgment based on multiple factors:

- **Age:** Older vehicles have more depreciation. A 2-year-old car retains more value than a 10-year-old car.
- **Mileage:** Higher mileage increases depreciation. A vehicle with 30,000 miles retains more value than one with 150,000 miles.
- **Condition:** Pre-accident condition affects ACV. Well-maintained vehicles with documented service history have higher ACV.
- **Local market comparables:** What similar vehicles are actually selling for in the local market. This is the strongest indicator of ACV.

### Common Data Sources

- **Kelley Blue Book (KBB):** Widely used consumer-facing valuation tool
- **NADA (National Automobile Dealers Association):** Used by insurers and dealers; sometimes considered more accurate for insurance purposes
- **Local dealer pricing:** Actual asking prices for comparable vehicles in the local market
- **Auction data:** Wholesale values for total loss salvage valuation

### Why This is a Reasoning Framework, Not a Formula

The plan explicitly requires that the system reason about depreciation rather than apply a fixed formula. The Assessor should:

- Reference the vehicle's age, mileage, and condition
- Note which data sources inform the valuation
- Explain the reasoning behind the ACV determination
- Document any adjustments (e.g., rare vehicle with limited market comparables)

**Wrong approach:** "Apply 15% depreciation per year."
**Right approach:** "Based on the vehicle's age (4 years), mileage (52,000), good condition, and local market comparables showing similar vehicles listed at $18,000-$20,000, the ACV is estimated at $19,000."

### Q&A Defense Points

- "ACV is what the vehicle was worth at the moment of loss, based on market comparables."
- "We reference KBB, NADA, and local market data -- not a fixed depreciation formula."
- "For total loss, the payout is ACV minus deductible, not the repair cost."
- "Our Assessor documents the reasoning behind every ACV determination, not just the number."

---

## Sources

- NAIC -- Replacement Cost vs. ACV explainer
- Total Loss Appraisals -- OEM vs. aftermarket analysis, state-by-state total loss thresholds
- Insurance industry standard practices for subrogation, rental reimbursement, and ACV calculation
- Kelley Blue Book and NADA valuation methodologies (referenced as data sources)

---
*Domain knowledge reference for: Ohio Mutual Auto Claims Processing System*
*Created: 2026-02-17*
*Hackathon context: OpenClaw Business Engineering Hackathon, Feb 21 2026, Belgrade*
