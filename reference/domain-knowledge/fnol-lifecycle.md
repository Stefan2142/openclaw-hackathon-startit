# FNOL Lifecycle Reference

**Purpose:** Complete First Notice of Loss lifecycle documentation for the Ohio Mutual Auto multi-agent claims processing system. This document serves as the domain knowledge foundation embedded into Front Desk and pipeline agent AGENTS.md templates. Every stage, data field, and sequencing rationale must be internalized before the hackathon build.

---

## Quick Reference

**The 6 Claim Categories:** Collision, Comprehensive, Liability, Theft, Vandalism, Weather/CAT

**The 6 Pipeline Stages:** FNOL Receipt -> Coverage Verification -> Damage Assessment -> Fraud Analysis -> Senior Review -> Payment

**Why categorization at intake matters:** Category determines which coverage type applies, routes to the correct adjuster path, affects the deductible amount, and shapes fraud analysis patterns. Miscategorization at intake cascades errors through every downstream stage.

**Urgency triggers:** Injury reported, total loss likely, rental vehicle needed immediately, legal representation letter received

**CAT event indicators:** Multiple claims from same geographic area in same time window, date/location matches known weather event

---

## 1. FNOL Data Capture Checklist

Every data field captured at First Notice of Loss intake. The Front Desk agent must collect all available information before the claim can proceed to Coverage Verification.

### Policyholder & Contact Information
- **Policy number** -- the primary lookup key for coverage verification
- **Insured name** -- legal name on the policy
- **Contact information** -- phone, email, preferred contact method
- **Claimant relationship** -- is the claimant the named insured, a listed driver, or a third party?

### Incident Details
- **Date and time of loss** -- when the incident occurred (not when it was reported)
- **Location of loss** -- street address, intersection, highway mile marker, or general area description
- **Incident description (narrative)** -- free-form account from the claimant in their own words; this narrative becomes the primary input for fraud analysis pattern matching
- **Weather conditions at time of loss** -- relevant for comprehensive vs. collision determination and CAT event tagging
- **Road conditions** -- wet, icy, construction zone, unlit; contextualizes the incident narrative

### Other Party Information
- **Other party name** -- if another vehicle/person involved
- **Other party insurance carrier and policy number** -- critical for subrogation and UM/UIM routing
- **Other party contact information** -- phone, address
- **Other party vehicle information** -- year, make, model, license plate

### Documentation References
- **Police report number** -- if law enforcement responded; absence of a police report in certain claim types is itself a fraud indicator
- **Witness information** -- names and contact info for any witnesses
- **Photo metadata/references** -- file paths or descriptions of damage photos, scene photos, other party vehicle photos; the system processes photo descriptions and metadata, not raw image analysis

### Vehicle Information
- **Year, make, model** -- determines parts pricing and total loss ACV calculation
- **VIN (Vehicle Identification Number)** -- unique vehicle identifier; used for fraud cross-referencing (VIN switching, prior claims on same vehicle)
- **Current mileage** -- affects ACV and OEM vs. aftermarket parts recommendation
- **Pre-accident condition** -- general vehicle condition before the incident; relevant for pre-existing damage assessment

### Status & Severity Indicators
- **Injury status** -- any injuries reported to any party; if YES, this triggers the expedite flag
- **Vehicle drivability** -- can the vehicle be driven or does it need towing? Affects rental reimbursement urgency
- **Estimated severity** -- claimant's description of damage extent; initial severity framing for the Assessor

---

## 2. Claim Categorization

The 6 auto insurance claim categories, determined at FNOL intake. Each category maps to a specific coverage type on the policy and drives downstream processing decisions.

### Collision
**When it applies:** The insured vehicle strikes another vehicle or a stationary object (guardrail, pole, tree, building, fence). Includes single-vehicle accidents (running off the road, hitting a pothole that causes collision damage).

**Coverage implications:** Requires collision coverage on the policy. Collision deductible applies (typically higher than comprehensive). If another party is at fault, subrogation recovery is possible.

**Fraud analysis context:** Collision claims involving rear-end impacts with multiple passengers are a primary staged accident pattern. Speed-inconsistent damage and lack of police report are key indicators.

### Comprehensive
**When it applies:** Damage to the insured vehicle from non-collision events. This is a broad category covering theft, vandalism, weather damage, animal strikes, falling objects, glass/windshield damage, fire, and flood.

**Coverage implications:** Requires comprehensive coverage on the policy. Comprehensive deductible applies (typically lower than collision). Some policies have separate glass deductibles or glass-only coverage.

**Fraud analysis context:** Comprehensive claims for theft require verification of timeline (when vehicle was last seen, when discovered missing). Vandalism claims without witnesses or surveillance require additional scrutiny.

### Liability
**When it applies:** The insured is determined to be at fault, and the other party files a claim against the insured's policy. This is a third-party claim -- the insured's liability coverage pays for damage to the other party's property and bodily injury.

**Coverage implications:** Covered under the liability portion of the policy (bodily injury liability and property damage liability). No deductible applies to liability coverage -- the insurer pays the other party directly up to policy limits. If damages exceed policy limits, the insured faces personal exposure.

**Fraud analysis context:** Liability claims from the other party may involve inflated damages or phantom injuries. Cross-reference the insured's own incident description with the third-party claim.

### Theft
**When it applies:** The insured vehicle is stolen (full theft) or components are stolen from the vehicle (partial theft -- catalytic converter, wheels, electronics). Full theft that results in recovery of a damaged vehicle may combine theft and comprehensive damage.

**Coverage implications:** Falls under comprehensive coverage. Full theft triggers total loss evaluation if the vehicle is not recovered within a reasonable timeframe. Partial theft is assessed as a comprehensive claim for the value of stolen parts plus any damage caused during the theft.

**Fraud analysis context:** Theft claims have distinct fraud patterns -- owner-assisted theft for financial relief (vehicle worth less than loan balance), VIN switching on recovered vehicles, and claims filed shortly after policy inception or increase in coverage.

### Vandalism
**When it applies:** Intentional damage to the insured vehicle by a third party. Keying, broken windows, slashed tires, spray paint, dents from deliberate strikes.

**Coverage implications:** Falls under comprehensive coverage. Comprehensive deductible applies. If the vandal is identified, subrogation against the vandal is possible but rarely recoverable.

**Fraud analysis context:** Vandalism claims without police reports, witnesses, or surveillance footage require scrutiny. Repeated vandalism claims on the same vehicle within a short timeframe are a soft fraud indicator.

### Weather/CAT (Catastrophic Event)
**When it applies:** Damage from natural weather events -- hail, flood, tornado, hurricane, ice storm, lightning strike. When a weather event affects multiple policyholders in the same geographic area within the same time window, the event may be tagged as a CAT (catastrophic) event.

**Coverage implications:** Falls under comprehensive coverage. CAT event tagging affects processing priority -- CAT claims are often batched and may have expedited processing tracks. Weather damage is never collision, even if the weather caused a collision (e.g., hydroplaning) -- the proximate cause analysis determines the category.

**Fraud analysis context:** CAT events create opportunities for inflated claims because adjusters are processing high volumes under time pressure. Pre-existing damage attributed to the weather event is the primary fraud pattern during CAT surges.

### Why Categorization at Intake Matters

Categorization is not administrative bookkeeping -- it is the first substantive decision in the claims pipeline, and errors here cascade through every downstream stage:

1. **Determines which coverage type applies:** A collision claim against a comprehensive-only policy will be denied at Coverage Verification. Miscategorizing a comprehensive event as collision routes the claim to the wrong coverage check.

2. **Routes to the correct adjuster path:** Different claim categories require different assessment approaches. A theft claim needs stolen vehicle recovery investigation, not collision damage estimation.

3. **Affects deductible amount:** Collision and comprehensive deductibles are different amounts on most policies. Wrong category means wrong deductible subtracted from payout.

4. **Impacts fraud analysis patterns:** Each category has distinct fraud indicators. Applying collision fraud patterns to a comprehensive claim produces false positives and misses category-specific red flags.

5. **Determines subrogation potential:** Collision claims with an at-fault third party have subrogation recovery potential. Comprehensive claims rarely do (except identified vandals or at-fault parties in weather-related multi-vehicle incidents).

---

## 3. FNOL-to-Payment Lifecycle Stages

The complete sequential flow from initial claim report through payment issuance. Each stage must complete before the next can begin -- this sequencing is a correctness requirement, not a design choice.

### Stage 1: FNOL Receipt (Front Desk Agent)

**Purpose:** Capture all available information about the loss event, categorize the claim, generate a unique claim identifier, and timestamp the acknowledgment for FCSP compliance tracking.

**Data entering this stage:**
- Raw claimant report (phone call, online form, walk-in)
- Policy number provided by claimant

**Processing:**
- Collect all data fields from the FNOL Data Capture Checklist
- Determine claim category (collision, comprehensive, liability, theft, vandalism, weather/CAT)
- Generate unique claim ID
- Record FNOL receipt timestamp (starts the FCSP compliance clock)
- Evaluate urgency indicators and set expedite flags
- Check for CAT event tagging conditions
- Write structured FNOL data to claim state

**Data exiting this stage:**
- Complete FNOL record with all captured fields
- Claim category assignment with reasoning
- Claim ID
- FNOL receipt timestamp
- Urgency/expedite flags (if applicable)
- CAT event tag (if applicable)
- Initial audit log entry with intake reasoning

**Why this must come first:** Nothing can be verified, assessed, or analyzed without the initial loss report. The FNOL receipt timestamp is also the regulatory compliance anchor -- all FCSP timelines run from this moment.

### Stage 2: Coverage Verification (Claims Officer Agent)

**Purpose:** Determine whether the insured's policy provides coverage for this specific claim. This is the gateway decision -- if coverage does not exist, the claim cannot proceed to assessment.

**Data entering this stage:**
- Complete FNOL record from Stage 1
- Policy number for lookup
- Claim category

**Processing:**
- Look up policy by policy number in the policy database
- Verify policy is active (check effective dates, check for lapse, evaluate grace period if lapsed)
- Match the claim category to coverage types present on the policy
- Check for applicable exclusions (intentional acts, racing, commercial use, excluded drivers, etc.)
- Determine the applicable deductible amount
- Identify coverage limits
- If at-fault party is uninsured or underinsured, route to UM/UIM coverage path

**Data exiting this stage:**
- Coverage determination: COVERED, DENIED, CONDITIONAL, or UM/UIM_ROUTE
- If COVERED: applicable coverage type, deductible amount, coverage limits
- If DENIED: specific exclusion or coverage gap with reasoning
- If CONDITIONAL: what additional information is needed
- Audit log entry with coverage verification reasoning

**Why this must come before assessment:** Assessing damage on an uncovered claim wastes pipeline resources and creates false expectations. Coverage verification is the first gatekeeping decision -- if the policy does not cover this loss, the claim routes to Senior Reviewer for denial documentation, not to the Assessor.

### Stage 3: Damage Assessment (Assessor Agent)

**Purpose:** Generate a repair cost estimate or total loss determination, recommend OEM vs. aftermarket parts, estimate repair timeline, and calculate rental entitlement.

**Data entering this stage:**
- Complete FNOL record (incident description, vehicle info, photos/descriptions)
- Coverage verification result (COVERED, with applicable limits and deductible)
- Claim category (affects estimation approach)

**Processing:**
- Evaluate damage based on incident description, photo descriptions, and vehicle information
- Generate repair estimate (labor hours, parts costs, paint/materials)
- Apply total loss check: if repair cost approaches or exceeds the vehicle's Actual Cash Value (ACV), the vehicle is a total loss; Ohio uses the 100% ACV rule -- if repair cost equals or exceeds ACV, it is a total loss
- If total loss: determine ACV (considering year, make, model, mileage, condition), estimate salvage value
- Recommend OEM vs. aftermarket parts based on vehicle age and mileage (newer vehicles and those with lower mileage warrant OEM parts for safety and fit; older vehicles may appropriately use aftermarket parts with policyholder disclosure)
- Estimate repair timeline in days
- Calculate rental entitlement based on repair days and policy rental coverage
- Flag any indicators of pre-existing damage (damage inconsistent with the described incident)
- Flag likelihood of hidden/supplemental damage for structural impacts

**Data exiting this stage:**
- Repair estimate OR total loss determination with ACV and salvage value
- OEM vs. aftermarket parts recommendation with reasoning
- Estimated repair days
- Rental entitlement (if policy includes rental coverage)
- Pre-existing damage flags (if any)
- Hidden damage likelihood flag
- Audit log entry with assessment methodology and reasoning

**Why this must come before fraud analysis:** The Fraud Analyst needs the damage estimate to evaluate whether the claimed damage is proportional to the described incident. Inflated repair estimates, damage patterns inconsistent with the described collision, and total loss claims on recently insured vehicles are all fraud indicators that require the Assessor's output.

### Stage 4: Fraud Analysis (Fraud Analyst Agent)

**Purpose:** Evaluate the complete claim data for fraud indicators, assign a risk score, classify the fraud type (soft vs. hard), and recommend the appropriate response path.

**Data entering this stage:**
- Complete FNOL record (narrative, parties, police report presence)
- Coverage verification result
- Damage assessment (estimate amount, total loss determination, pre-existing damage flags)
- Claimant history (prior claims on same vehicle, claim frequency)

**Processing:**
- Pattern match against known fraud indicators:
  - **Staged accidents:** Swoop-and-squat, drive-down, side-swipe setups; indicators include damage inconsistent with described speeds, multiple passengers with injury claims, lack of independent witnesses
  - **Phantom passengers:** More injury claimants than the vehicle can seat, passengers with no independent verification
  - **Inflated repair estimates:** Damage estimate significantly exceeds what the described incident would produce; comparison of damage description to estimate amount
  - **Paper accidents:** Claims for incidents that never occurred; no physical evidence, no police report, no witnesses, vague or shifting narrative details
  - **Prior damage claims:** Same vehicle or same claimant with recent prior claims; pattern of claims on newly insured vehicles
- Classify as soft fraud (exaggeration of legitimate claim) or hard fraud (fabricated or staged claim)
- Assign fraud risk score based on the weight and combination of indicators found
- Determine recommendation: CLEAR (proceed normally), INVESTIGATE (additional review needed), or REFER_SIU (refer to Special Investigations Unit for formal investigation)

**Data exiting this stage:**
- Fraud risk score with scoring methodology explanation
- Named fraud patterns flagged (if any)
- Soft vs. hard fraud classification (if fraud indicators present)
- Recommendation: CLEAR, INVESTIGATE, or REFER_SIU
- Audit log entry with every indicator evaluated and reasoning for the score

**Why this must come before Senior Review:** The Senior Reviewer needs the fraud assessment to make a defensible approval or denial decision. Approving a high-fraud-risk claim without documented fraud analysis is both an operational failure and a potential bad faith exposure -- the insurer must demonstrate due diligence in evaluating claims.

### Stage 5: Senior Review (Senior Reviewer Agent)

**Purpose:** Make the final authorization decision on the claim -- approve, deny, conditionally approve, or escalate to human review. This is the decision gate that prevents unauthorized payments and ensures regulatory compliance.

**Data entering this stage:**
- All prior stage outputs (FNOL, coverage, assessment, fraud analysis)
- Fraud risk score and recommendation
- FCSP timeline status (elapsed time since FNOL receipt)

**Processing:**
- Review coverage determination for correctness
- Review damage assessment for reasonableness
- Evaluate fraud score and named patterns -- if fraud risk is elevated, assess whether the recommendation is proportionate
- Check FCSP compliance timeline: has the claim been processed within regulatory timeframes? If approaching the decision deadline without resolution, escalate with urgency
- Evaluate escalation triggers: elevated fraud indicators, high claim value, total loss, legal representation letter received, prior claim within recent history on same vehicle, UM/UIM claim
- Assess whether diminished value claim is likely and should be noted
- Make decision: APPROVE (proceed to Finance), DENY (document denial reasoning for regulatory compliance), CONDITIONAL_APPROVE (approve pending specific conditions such as physical inspection), or ESCALATE_HUMAN (claim requires human adjuster review)

**Data exiting this stage:**
- Decision: APPROVED, DENIED, CONDITIONAL, or ESCALATE_HUMAN
- Written rationale explaining the decision
- Any conditions attached (for conditional approval)
- FCSP timeline compliance status
- Escalation details (if escalated)
- Audit log entry with complete decision reasoning

**Why this must come before payment:** No payment should issue without an explicit approval decision from the Senior Reviewer. This is both an internal control (prevents unauthorized disbursements) and a regulatory requirement (every claim decision must be documented and defensible). Finance must verify that `senior_reviewer.decision === "APPROVED"` before calculating payment.

### Stage 6: Payment (Finance Agent)

**Purpose:** Calculate the final payment amount, record the payment, flag subrogation opportunities, and close the claim (or leave it open for subrogation recovery).

**Data entering this stage:**
- Senior Reviewer approval with any conditions
- Damage assessment (repair estimate or total loss ACV/salvage)
- Deductible amount from coverage verification
- Policy type (ACV or replacement cost)

**Processing:**
- Verify Senior Reviewer approval exists and is unconditional (or conditions are satisfied)
- Calculate payout:
  - For repairs: repair estimate minus deductible
  - For total loss: ACV minus deductible minus salvage value (if insurer retains salvage) or ACV minus deductible (if insured retains salvage)
  - Apply depreciation if policy is ACV-based (standard for auto)
  - Add rental reimbursement as a separate line item if applicable
- Evaluate subrogation potential: if a third party is at fault and has identified insurance, flag the claim for subrogation recovery; the payment issues to the insured, but the claim remains open for the insurer to pursue recovery from the at-fault party's carrier
- Generate payment record with: amount, recipient, payment method, date, claim reference
- If no subrogation: close the claim
- If subrogation flagged: mark claim as PAID_PENDING_SUBROGATION

**Data exiting this stage:**
- Payment record (amount, recipient, method, date)
- Subrogation flag and third-party insurer details (if applicable)
- Claim status: PAYMENT_ISSUED or PAID_PENDING_SUBROGATION
- Final audit log entry with payment calculation breakdown

**Why this is the final stage:** Payment is the fulfillment of the insurance contract. Every prior stage exists to ensure that this payment is correct (coverage verified), fair (damage properly assessed), legitimate (fraud analyzed), and authorized (Senior Reviewer approved). No shortcut through this sequence produces a defensible claims outcome.

---

## 4. CAT Event Tagging

Catastrophic (CAT) event tagging identifies claims that are part of a larger weather or disaster event affecting multiple policyholders. CAT tagging is determined at FNOL intake by the Front Desk agent.

### When to Tag a Claim as CAT

A claim should be evaluated for CAT event tagging when any of the following conditions are present:

- **Geographic clustering:** Multiple claims are being received from the same geographic area within a narrow time window. When the Front Desk agent observes a surge in claims from a specific region, each individual claim in that surge should be evaluated for CAT tagging.

- **Date/location correlation with known weather:** The date and location of the loss match a known severe weather event -- hailstorm, tornado, flood, hurricane, ice storm. Weather event data can be cross-referenced with the incident date and location.

- **Claimant description indicates weather:** The claimant's incident narrative describes weather-related damage (hail dents, flooding, fallen tree, wind damage) rather than a collision or human-caused event.

### Why CAT Tagging Matters

- **Coverage type determination:** Weather damage is comprehensive coverage, never collision, even if the weather caused a vehicle collision (proximate cause analysis). CAT tagging reinforces the correct coverage path.

- **Processing priority adjustment:** CAT events may trigger expedited processing tracks because regulators and policyholders expect faster response during disasters. The Senior Reviewer should be aware of CAT status when evaluating FCSP timeline compliance.

- **Fraud analysis calibration:** CAT events create conditions where inflated claims are more common because adjusters are processing high volumes under time pressure. The Fraud Analyst should apply additional scrutiny to CAT-tagged claims where pre-existing damage may be attributed to the weather event.

- **Reporting and analytics:** CAT event tags allow the insurer to aggregate losses by event for reinsurance reporting, reserve management, and regulatory filings.

---

## 5. Urgency Indicators

Certain conditions at FNOL intake signal that a claim requires expedited processing. The Front Desk agent should evaluate these indicators and set appropriate flags in the claim record.

### Injury Reported

When any party reports bodily injury -- whether the insured, passengers, other drivers, or pedestrians -- the claim receives an expedite flag. Injury claims have regulatory implications (bodily injury liability, PIP/MedPay coverage activation) and human welfare urgency that justify priority processing.

**What the Front Desk agent does:** Set the injury flag to true, note which parties reported injuries, and ensure the claim is routed with priority through the pipeline.

### Total Loss Likely

When the claimant describes damage that suggests the vehicle is likely a total loss (severe structural damage, airbag deployment, fire, flood submersion, significant intrusion into passenger compartment), the claim should be flagged for expedited Assessor review. Total loss claims require ACV determination and potentially rental reimbursement or transportation assistance.

**What the Front Desk agent does:** Set the total-loss-likely flag based on the severity description. The Assessor will make the definitive total loss determination, but early flagging ensures the claim is not delayed in queue.

### Rental Vehicle Needed Immediately

When the insured's vehicle is not drivable and the insured needs transportation immediately (especially if the policy includes rental reimbursement coverage), the claim should be flagged for rental urgency. The Claims Officer can fast-track rental coverage verification so the insured can get a rental vehicle before the full pipeline completes.

**What the Front Desk agent does:** Note vehicle drivability status and rental urgency. If the policy includes rental coverage, this enables parallel processing of the rental authorization while the main claim proceeds through assessment.

### Legal Representation Letter Received

When the claimant or another party has retained legal counsel and a letter of representation has been received, the claim requires careful handling. Legal representation often indicates a disputed claim, potential litigation, or a demand that will require Senior Reviewer attention.

**What the Front Desk agent does:** Flag legal representation status and note the attorney's contact information. All subsequent communications may need to go through the attorney rather than directly to the claimant. This flag also serves as an escalation trigger for the Senior Reviewer.

---

## Pipeline Data Flow Summary

```
Stage 1 (Front Desk)
  IN:  Raw claimant report
  OUT: Structured FNOL record, claim category, claim ID, timestamps, urgency flags
    |
    v
Stage 2 (Claims Officer)
  IN:  FNOL record, policy number
  OUT: Coverage determination (COVERED/DENIED/CONDITIONAL/UM_UIM_ROUTE), deductible, limits
    |
    v  [If DENIED -> Stage 5 for denial documentation]
Stage 3 (Assessor)
  IN:  FNOL record, coverage result, claim category
  OUT: Repair estimate OR total loss (ACV + salvage), OEM/aftermarket, rental days
    |
    v
Stage 4 (Fraud Analyst)
  IN:  All prior outputs (FNOL, coverage, assessment)
  OUT: Fraud score, named patterns, soft/hard classification, recommendation
    |
    v
Stage 5 (Senior Reviewer)
  IN:  All prior outputs, FCSP timeline status
  OUT: Decision (APPROVE/DENY/CONDITIONAL/ESCALATE), rationale
    |
    v  [If DENIED or ESCALATE -> claim stops here]
Stage 6 (Finance)
  IN:  Approval, damage estimate, deductible
  OUT: Payment record, subrogation flag, claim status
```

---

*Reference document for Ohio Mutual Auto multi-agent claims processing system*
*Covers: FNOL data capture, claim categorization, FNOL-to-payment lifecycle, CAT event tagging, urgency indicators*
