# Coverage Verification Knowledge Base

**Purpose:** Comprehensive coverage verification reference for the Ohio Mutual Auto multi-agent claims processing system. This document provides the Claims Officer agent with the domain knowledge needed to determine whether a policy covers a specific claim. All logic is expressed as reasoning frameworks suitable for AGENTS.md embedding.

---

## Quick Reference

**The 4 Coverage Outcomes:** COVERED, DENIED, CONDITIONAL, UM/UIM_ROUTE

**Policy Verification Sequence:** Lookup -> Active Status -> Coverage Type Match -> Exclusion Check -> Deductible Lookup -> Limits Check

**Common Exclusions to Always Check:** Intentional acts, racing/competition, commercial use on personal policy, excluded drivers, non-owned vehicle, mechanical breakdown, wear and tear

**Deductible Principle:** Collision deductible and comprehensive deductible are separate amounts. Deductible applies to damage payout, not to liability coverage. Higher deductible means lower premium -- this is the policyholder's chosen risk trade-off.

---

## 1. Policy Lookup Protocol

The Claims Officer's first action is to locate and verify the insured's policy. This is a sequential verification -- each step must pass before proceeding to the next.

### Step 1: Look Up Policy by Policy Number

The policy number provided at FNOL intake is the primary lookup key. Retrieve the complete policy record including:
- Named insured and listed drivers
- Policy effective dates (inception and expiration)
- Coverage types present and their limits
- Deductible amounts per coverage type
- Any endorsements (rental, roadside, gap, etc.)
- Any exclusions or riders
- Payment status (current, lapsed, cancelled)

### Step 2: Verify Policy Is Active

Check the policy status at the **date of loss** (not the date of claim filing):

- **Active and current:** Policy effective dates encompass the date of loss, and premiums are current. Proceed to coverage type matching.

- **Lapsed (premium non-payment):** If the policy lapsed before the date of loss, check the grace period. Most states allow a grace period of 10 to 30 days after a missed payment during which coverage may still apply. If the date of loss falls within the grace period, coverage may still be valid -- document the grace period analysis and flag for Senior Reviewer awareness. If the date of loss falls after the grace period, coverage is not in force.

- **Cancelled:** If the insurer or insured cancelled the policy before the date of loss, there is no coverage. Document the cancellation date and reason.

- **Not-yet-effective:** If the date of loss is before the policy inception date, there is no coverage.

### Step 3: Match Claim Category to Coverage Types on Policy

The claim category assigned at FNOL intake must map to a coverage type that exists on the policy:

| Claim Category | Required Coverage Type |
|---|---|
| Collision | Collision coverage |
| Comprehensive | Comprehensive coverage |
| Liability | Liability coverage (bodily injury and/or property damage) |
| Theft | Comprehensive coverage |
| Vandalism | Comprehensive coverage |
| Weather/CAT | Comprehensive coverage |

If the required coverage type is not present on the policy, the claim cannot be covered under that category. For example, a collision claim on a policy that carries only liability and comprehensive coverage (no collision) must be denied on coverage grounds.

### Step 4: Identify Applicable Coverage Limits

Every coverage type has a per-occurrence or per-person limit. The Claims Officer must identify:
- Per-occurrence limit for the applicable coverage type
- Any aggregate limits that may be relevant
- Whether the claim is likely to approach or exceed the limit (if so, flag for Senior Reviewer awareness)

### Step 5: Determine Deductible Amount

Look up the deductible for the applicable coverage type. Record the deductible amount -- this will be subtracted from the damage payout by the Finance agent.

---

## 2. Coverage Types on Auto Policies

A comprehensive explanation of each coverage type found on standard auto insurance policies.

### Liability Coverage (Bodily Injury + Property Damage)

**What it covers:** Damage and injuries the insured causes to other people and their property when the insured is at fault. This is third-party coverage -- it pays the other party, not the insured.

**Two components:**
- **Bodily Injury Liability (BI):** Medical expenses, lost wages, pain and suffering of injured parties. Expressed as per-person/per-occurrence limits (e.g., 100/300 means $100K per person, $300K per occurrence).
- **Property Damage Liability (PD):** Repair or replacement of other party's property. Separate limit (e.g., $100K per occurrence).

**Key characteristic:** No deductible applies to liability coverage. The insurer pays the third party directly. If damages exceed policy limits, the insured faces personal financial exposure.

**Mandatory in most states:** Liability is required by law in nearly all states. Minimum limits vary by state.

### Collision Coverage

**What it covers:** Damage to the insured's own vehicle resulting from a collision with another vehicle or object. Includes single-vehicle accidents (hitting a guardrail, running off the road, hitting a pothole).

**Key characteristics:**
- Optional coverage (not legally required)
- Deductible applies (commonly $500, but varies by policy)
- Pays regardless of fault -- if the insured is at fault, collision still pays for the insured's vehicle damage
- If a third party is at fault, the insurer may pursue subrogation after paying the insured

### Comprehensive Coverage

**What it covers:** Damage to the insured's own vehicle from non-collision events. This is the broadest single coverage type for the insured's vehicle:
- Theft (full or partial)
- Vandalism
- Weather events (hail, flood, tornado, hurricane, lightning)
- Animal strikes (deer, other wildlife)
- Falling objects (tree limbs, construction debris)
- Fire
- Glass/windshield damage
- Civil disturbance or riot

**Key characteristics:**
- Optional coverage (not legally required)
- Deductible applies (commonly $250, typically lower than collision deductible)
- Some policies have separate glass deductibles or full glass coverage without deductible
- Does not cover collision damage -- even if weather caused a collision (e.g., hydroplaning into another car), proximate cause analysis may route to collision, not comprehensive

### Uninsured Motorist Coverage (UM)

**What it covers:** Injuries and property damage to the insured when the at-fault party has NO insurance at all. The insured's own UM coverage steps in to pay what the at-fault party's liability coverage would have paid.

**Key characteristics:**
- Required in some states, optional in others
- Covers bodily injury (UM/BI) and in some states property damage (UMPD)
- Different deductible than collision or comprehensive
- Triggered when the at-fault party is identified but confirmed uninsured, or in hit-and-run scenarios where the at-fault party cannot be identified

### Underinsured Motorist Coverage (UIM)

**What it covers:** The gap between the at-fault party's insufficient insurance limits and the insured's actual damages. If the at-fault party has insurance but the limits are too low to cover the insured's damages, UIM pays the difference up to the insured's own UIM limits.

**Key characteristics:**
- Often bundled with UM but can be separate
- Different limits and deductibles than standard collision
- Requires establishing that the at-fault party's coverage is insufficient (usually after settlement offer from the at-fault party's insurer)

### Medical Payments / Personal Injury Protection (PIP)

**What it covers:** Medical expenses for the insured and passengers regardless of fault. PIP may also cover lost wages, funeral expenses, and essential services.

**Key characteristics:**
- No-fault coverage -- pays regardless of who caused the accident
- PIP is required in no-fault states; Medical Payments (MedPay) is the equivalent in at-fault states
- Typically has its own separate limit (e.g., $5K-$10K per person)
- No deductible in most cases

### Rental Reimbursement

**What it covers:** Cost of a rental vehicle while the insured's vehicle is being repaired due to a covered claim.

**Key characteristics:**
- Optional endorsement
- Daily dollar limit (commonly $30-$50/day)
- Maximum duration cap (commonly 30 days)
- For total loss, rental typically covers up to 10 days (time to arrange a replacement vehicle)

### Roadside Assistance / Towing

**What it covers:** Towing, flat tire change, lockout service, fuel delivery, and basic roadside mechanical assistance.

**Key characteristics:**
- Optional endorsement
- Per-occurrence dollar limit for towing (commonly $75-$150)
- Not a claims event in most cases -- usage does not affect claims history

---

## 3. Exclusion Types

Common auto policy exclusions that the Claims Officer must check against every claim. For each exclusion: what triggers the check, what evidence to look for, and what the denial path looks like.

### Intentional Acts

**The exclusion:** Damage deliberately caused by the policyholder or an insured party is not covered. Insurance covers fortuitous (accidental) losses, not planned ones.

**When to check:** When the incident description, police report, or witness statements suggest the damage was intentional. Road rage incidents where the insured deliberately rammed another vehicle, intentional destruction of own vehicle for financial gain.

**Evidence to look for:** Police report indicating intentional act, witness statements describing deliberate behavior, claimant's own admission, surveillance footage showing intentional damage, damage pattern inconsistent with accidental cause.

**Denial path:** If intentional act is substantiated, the claim is denied under the intentional acts exclusion. Document the evidence in the audit log. Route to Senior Reviewer for denial documentation. If the intentional act involved insurance fraud, also flag for the Fraud Analyst with a hard fraud classification.

### Racing / Competition Use

**The exclusion:** Damage sustained while the vehicle was being used in any form of racing, speed contest, or organized competition is not covered.

**When to check:** When the incident description mentions racing, a track event, drag racing, street racing, or any organized speed competition. Also when the location of loss is a race track or similar facility.

**Evidence to look for:** Location is a race track or closed course, police report mentions racing or speed contest, witness statements describe racing behavior, damage pattern consistent with high-speed competition.

**Denial path:** Claim denied under racing/competition exclusion. Document the evidence. Route to Senior Reviewer for denial documentation.

### Commercial Use on Personal Policy

**The exclusion:** A personal auto policy does not cover the vehicle while it is being used for commercial purposes. This commonly arises with rideshare (Uber, Lyft), delivery services (DoorDash, Amazon Flex), or other for-hire transportation.

**When to check:** When the incident description mentions the insured was working for a rideshare or delivery company at the time of loss. When the vehicle had passengers who were ride-hailing customers. When the insured was making deliveries at the time of the incident.

**Evidence to look for:** Rideshare app was active at the time of loss (driver was logged in and available or on a trip), insured admits to commercial activity, passengers were paying customers, delivery items in the vehicle, vehicle has commercial markings or equipment.

**Denial path:** Claim denied under commercial use exclusion. The insured needs a commercial auto policy or a rideshare endorsement. Document the commercial activity evidence. Route to Senior Reviewer for denial documentation. This is not fraud -- it is a coverage gap. The insured may not have known their personal policy excluded commercial use.

### Excluded Drivers

**The exclusion:** Some policies specifically name drivers who are excluded from coverage. If the excluded driver was operating the vehicle at the time of loss, the claim is denied regardless of the type of loss.

**When to check:** When the driver at the time of loss is someone other than the named insured. Cross-reference the driver's identity against the policy's excluded driver list.

**Evidence to look for:** Police report identifies the driver, claimant identifies who was driving, the driver is specifically named on the policy's excluded driver list.

**Denial path:** Claim denied because the vehicle was being operated by an excluded driver. Document which excluded driver was operating the vehicle and how this was determined. Route to Senior Reviewer for denial documentation.

### Non-Owned Vehicle Without Endorsement

**The exclusion:** Standard personal auto policies cover the named vehicle(s) on the policy. If the insured is driving a vehicle not listed on the policy and does not have a non-owned vehicle endorsement, coverage may not extend to that vehicle.

**When to check:** When the VIN of the involved vehicle does not match any vehicle listed on the policy. When the insured was driving a borrowed, rented, or otherwise non-owned vehicle.

**Evidence to look for:** VIN mismatch between the claim vehicle and the policy vehicle list, insured states they were driving someone else's vehicle, rental agreement for the vehicle.

**Denial path:** Evaluate whether the policy has any non-owned vehicle coverage or endorsement. If not, the claim may be denied. Note that some policies provide limited coverage for temporary substitute vehicles or newly acquired vehicles within a grace period. Route ambiguous cases to Senior Reviewer as CONDITIONAL.

### Mechanical Breakdown

**The exclusion:** Auto insurance covers damage from external events (collisions, weather, theft), not internal mechanical failures. Engine failure, transmission problems, electrical system malfunctions, and other mechanical breakdowns are maintenance issues, not insured perils.

**When to check:** When the claimed damage is purely mechanical with no external cause. When the incident description describes the vehicle "just stopped working" or "the engine failed" without any collision, weather, or other covered event.

**Evidence to look for:** No external damage to the vehicle, damage is limited to mechanical components (engine, transmission, drivetrain), no collision or external event caused the failure, repair shop diagnosis of mechanical failure or wear.

**Denial path:** Claim denied under mechanical breakdown exclusion. This is a maintenance/warranty issue, not an insurance claim. Document the mechanical nature of the damage. Route to Senior Reviewer for denial documentation.

### Wear and Tear / Maintenance Failures

**The exclusion:** Gradual deterioration, rust, corrosion, tire wear, brake pad wear, and other normal aging of the vehicle are not covered events. Insurance covers sudden and accidental losses, not predictable degradation.

**When to check:** When the claimed damage appears to be the result of long-term deterioration rather than a specific incident. When the damage described (rust, paint peeling, tire blowout from worn tread) is consistent with age and use rather than a covered peril.

**Evidence to look for:** Damage appears old or progressive, rust or corrosion pre-dates the reported loss date, tire failure from worn tread rather than road hazard, maintenance records showing deferred repairs.

**Denial path:** Claim denied under wear and tear exclusion. Document the evidence of gradual deterioration. Route to Senior Reviewer for denial documentation.

### Nuclear / War / Government Action (Standard Exclusions)

**The exclusion:** Damage from nuclear events, acts of war, military action, or government seizure/destruction of property is excluded under standard policy language. These are catastrophic risks that are uninsurable under standard auto policies.

**When to check:** Rarely relevant in standard auto claims. Check when the loss involves military operations, government action (eminent domain, law enforcement vehicle seizure), or is related to civil unrest escalating to insurrection.

**Denial path:** Standard exclusion language -- denial based on policy terms. Route to Senior Reviewer for documentation.

---

## 4. Deductible Determination

How deductibles work in auto insurance claims and how the Claims Officer determines the applicable deductible amount.

### Per-Coverage Deductibles

Each coverage type on the policy has its own deductible amount. The most common structure:

- **Collision deductible:** Typically $500, though policies may have $250, $500, $1,000, or even $2,500 depending on the policyholder's choice when the policy was purchased.
- **Comprehensive deductible:** Typically $250, often lower than the collision deductible. Some policies have $100, $250, $500, or $1,000 comprehensive deductibles.
- **Liability:** No deductible. The insurer pays the third party directly.
- **UM/UIM:** May have its own deductible, often different from collision and comprehensive.

### The Deductible Trade-Off

Higher deductible means lower premium. The policyholder chose their deductible level based on their risk tolerance and budget. A $1,000 collision deductible means the policyholder pays the first $1,000 of any collision repair out of pocket, and the insurer pays the rest up to the coverage limit.

The Claims Officer should not second-guess the deductible amount -- it is a contractual term of the policy. Record it accurately and pass it to Finance for subtraction from the payout.

### Named-Driver Deductibles

Some policies assign different deductible amounts to different listed drivers. A young driver added to a family policy might have a higher deductible than the primary policyholder. The Claims Officer must check whether the driver at the time of loss has a named-driver deductible that differs from the policy default.

### Deductible Waiver Scenarios

In certain circumstances, the deductible may be waived:

- **Not-at-fault collision (some states):** If the insured was not at fault in a collision and the at-fault party's insurer is paying, no deductible applies because the claim is against the other party's liability coverage. If the insured files under their own collision coverage (to avoid waiting for the other insurer), the deductible applies initially but may be recovered through subrogation.

- **Windshield-only claims (some states/policies):** Some states require insurers to offer zero-deductible glass coverage. If the policy has this endorsement and the claim is windshield-only, no deductible applies.

- **Uninsured motorist property damage (some states):** Some states waive or reduce the UMPD deductible when the at-fault party is confirmed uninsured.

### Deductible and Payout Relationship

The deductible is subtracted from the damage payout, not added to it:

- **Repair claim:** Payout = Repair Estimate - Deductible
- **Total loss claim:** Payout = ACV - Deductible (minus salvage value if insurer retains salvage)
- **Liability claim:** No deductible -- insurer pays the third party's damages directly

If the repair estimate is less than the deductible, there is no payout. The insured pays the full cost out of pocket. The Claims Officer should note this scenario so the claimant is informed promptly.

---

## 5. UM/UIM Identification

When and how to route a claim to the uninsured/underinsured motorist coverage path. This is a critical routing decision that changes which coverage type applies and may change the deductible and limits.

### Uninsured Motorist (UM) Scenarios

UM coverage activates when the at-fault party has **no insurance at all**:

- **Identified uninsured driver:** The other driver is identified (police report, witness, admission) but has no active insurance. The insured's own UM coverage pays for the insured's damages.

- **Hit-and-run:** The at-fault driver fled the scene and cannot be identified. In most states, this qualifies as an uninsured motorist scenario. The insured's UM coverage may apply, though some states require physical contact between the vehicles.

- **Phantom vehicle:** The insured swerved to avoid another vehicle that left no contact and cannot be identified. This is the most difficult UM scenario -- some states require proof of the phantom vehicle's existence.

### Underinsured Motorist (UIM) Scenarios

UIM coverage activates when the at-fault party **has insurance but insufficient limits**:

- The at-fault party's liability limit is $25,000 but the insured's damages total $80,000. The at-fault party's insurer pays their $25,000 limit. The insured's UIM coverage pays the $55,000 difference (up to the insured's UIM limit).

- UIM is typically triggered after the at-fault party's insurer has made their maximum offer or settled at policy limits.

### Routing Decision Framework

The Claims Officer must identify the UM/UIM scenario early in the coverage verification process:

1. **Was another party at fault?** If no, UM/UIM does not apply -- the insured's collision coverage handles the claim.

2. **Does the at-fault party have insurance?** If yes, check whether the limits are sufficient. If no, route to UM.

3. **Are the at-fault party's limits sufficient?** If the damages are likely to exceed the at-fault party's limits (based on damage severity and the Assessor's estimate), flag for potential UIM routing.

4. **Does the insured's policy include UM/UIM coverage?** If not, the insured has no UM/UIM protection -- their options are to file under their own collision coverage (with deductible) or pursue the at-fault party directly.

### Key Differences from Standard Collision Path

| Aspect | Collision Path | UM/UIM Path |
|---|---|---|
| Deductible | Collision deductible | UM/UIM deductible (may be different) |
| Coverage limits | Collision per-occurrence limit | UM/UIM per-person/per-occurrence limits |
| Subrogation | Insurer pursues at-fault party's insurer | Insurer may pursue at-fault party directly (if uninsured) |
| Bodily injury | Not covered under collision | UM/BI covers insured's injuries |

---

## 6. Coverage Determination Outcomes

Every coverage verification ends with one of four outcomes. The Claims Officer must clearly state the outcome and provide reasoning.

### COVERED

**Definition:** The policy is active, the coverage type matches the claim category, no exclusions apply, and the deductible and limits are identified.

**Next step:** Proceed to Stage 3 (Damage Assessment). Pass the coverage details (coverage type, deductible amount, coverage limits) to the Assessor.

**Audit log entry should include:** Policy number, policy status (active), coverage type matched, exclusions checked and cleared, deductible amount, applicable limits.

### DENIED

**Definition:** The claim cannot be covered because of one or more clear disqualifying conditions:
- Policy is lapsed beyond the grace period
- The required coverage type is not present on the policy
- An exclusion directly applies (excluded driver, commercial use, intentional act, etc.)
- The policy was not in force at the date of loss

**Next step:** Route to Stage 5 (Senior Reviewer) for denial documentation. The Senior Reviewer must review the denial reasoning, ensure it is defensible and properly documented, and issue the formal denial.

**Audit log entry should include:** Specific reason for denial, the policy condition or exclusion that applies, any evidence supporting the denial determination. This documentation is critical for FCSP compliance -- every denial must be supportable if challenged.

### CONDITIONAL

**Definition:** Coverage is uncertain and requires additional information or investigation before a determination can be made:
- The date of loss falls in or near the grace period and payment history needs verification
- The coverage type match is ambiguous (e.g., was the weather event the proximate cause, or was it a collision during weather?)
- An exclusion may apply but the evidence is incomplete
- The policy has unusual endorsements or riders that affect coverage

**Next step:** The claim is held pending additional information. Document what information is needed and why. If the information can be obtained within the pipeline (e.g., the Assessor can clarify the damage cause), proceed conditionally with a note for Senior Reviewer attention.

**Audit log entry should include:** The conditional determination, exactly what information is needed, why the determination cannot yet be made, and the expected path to resolution.

### UM/UIM_ROUTE

**Definition:** The claim involves an at-fault third party who is uninsured or underinsured, and the insured's UM/UIM coverage should be evaluated instead of (or in addition to) standard collision coverage.

**Next step:** Re-evaluate coverage under the UM/UIM provisions of the policy. Check UM/UIM limits, deductible, and coverage conditions. If UM/UIM coverage exists and applies, mark the claim as COVERED under UM/UIM and proceed to assessment. If the policy does not include UM/UIM coverage, document this and evaluate whether the collision coverage path is an alternative.

**Audit log entry should include:** Why the UM/UIM route was identified, the at-fault party's insurance status, the insured's UM/UIM coverage details.

---

## 7. Mock Policy Database

Five representative policy records illustrating different verification scenarios the Claims Officer will encounter. These demonstrate the range of coverage situations and how each maps to a coverage determination outcome.

### Policy 1: Standard Active Policy (DEMO-POLICY-001)

```
Policy Number: DEMO-POLICY-001
Named Insured: Sarah Mitchell
Status: ACTIVE
Effective: 2025-08-15 to 2026-08-15
Vehicle: 2022 Honda Civic EX (VIN: 2HGFC2F59NH012345)
Mileage: 28,400

Coverages:
  Liability (BI/PD): 100/300/100
  Collision: $500 deductible
  Comprehensive: $250 deductible
  UM/UIM: 100/300
  Medical Payments: $5,000 per person
  Rental Reimbursement: $40/day, 30-day max

Listed Drivers:
  - Sarah Mitchell (primary)
  - James Mitchell (spouse)

Exclusions: None specific
Endorsements: Rental reimbursement, roadside assistance
```

**Verification scenarios:** Standard covered claim for any category. Collision claim with $500 deductible. Comprehensive claim with $250 deductible. UM/UIM available if at-fault party is uninsured. Rental coverage available during repairs.

### Policy 2: Lapsed Policy (DEMO-POLICY-002)

```
Policy Number: DEMO-POLICY-002
Named Insured: Robert Chen
Status: LAPSED (premium non-payment)
Effective: 2025-03-01 to 2026-03-01
Last Payment: 2025-12-15
Lapse Date: 2026-01-15
Vehicle: 2019 Toyota Camry SE (VIN: 4T1B11HK5KU789012)
Mileage: 52,100

Coverages (when active):
  Liability (BI/PD): 50/100/50
  Collision: $1,000 deductible
  Comprehensive: $500 deductible
  UM/UIM: None

Listed Drivers:
  - Robert Chen (primary)

Exclusions: None specific
Endorsements: None
```

**Verification scenarios:** If the date of loss is before January 15, 2026, the policy was active -- COVERED. If the date of loss is between January 15 and approximately February 15 (30-day grace period), coverage is CONDITIONAL pending payment verification. If the date of loss is after the grace period, the claim is DENIED due to lapsed coverage. Also note: no UM/UIM coverage, so if another party is uninsured, the insured has no UM protection.

### Policy 3: Excluded Driver (DEMO-POLICY-003)

```
Policy Number: DEMO-POLICY-003
Named Insured: Maria Rodriguez
Status: ACTIVE
Effective: 2025-11-01 to 2026-11-01
Vehicle: 2021 Ford F-150 XLT (VIN: 1FTEW1EP5MFA34567)
Mileage: 41,200

Coverages:
  Liability (BI/PD): 100/300/100
  Collision: $500 deductible
  Comprehensive: $250 deductible
  UM/UIM: 50/100
  Medical Payments: $10,000 per person

Listed Drivers:
  - Maria Rodriguez (primary)
  - Carlos Rodriguez (spouse)

Excluded Drivers:
  - Diego Rodriguez (son, age 19) -- excluded due to driving record

Endorsements: None
```

**Verification scenarios:** If Maria or Carlos is driving, standard COVERED determination. If Diego (the excluded driver) was operating the vehicle at the time of loss, the claim is DENIED regardless of the type of loss. The exclusion is driver-specific, not coverage-specific -- it applies to any claim type if the excluded driver was behind the wheel.

### Policy 4: High Deductible Policy (DEMO-POLICY-004)

```
Policy Number: DEMO-POLICY-004
Named Insured: Thomas Wright
Status: ACTIVE
Effective: 2025-06-01 to 2026-06-01
Vehicle: 2020 BMW 330i (VIN: 3MW5R1J04L8B56789)
Mileage: 35,800

Coverages:
  Liability (BI/PD): 250/500/250
  Collision: $2,500 deductible
  Comprehensive: $1,000 deductible
  UM/UIM: 250/500
  Medical Payments: $25,000 per person
  Rental Reimbursement: $50/day, 30-day max

Listed Drivers:
  - Thomas Wright (primary)

Exclusions: None specific
Endorsements: Rental reimbursement, OEM parts endorsement
```

**Verification scenarios:** Fully covered for all claim types, but the high deductibles ($2,500 collision, $1,000 comprehensive) mean that minor damage claims may result in no payout if the repair estimate is below the deductible. The OEM parts endorsement means the Assessor should always recommend OEM parts regardless of vehicle age. The high coverage limits suggest a high-value policy -- the insured chose high limits with high deductibles to manage premium cost.

### Policy 5: Comprehensive-Only Policy (DEMO-POLICY-005)

```
Policy Number: DEMO-POLICY-005
Named Insured: Jennifer Park
Status: ACTIVE
Effective: 2025-09-01 to 2026-09-01
Vehicle: 2015 Hyundai Sonata SE (VIN: 5NPE24AF8FH012345)
Mileage: 89,200

Coverages:
  Liability (BI/PD): 25/50/25 (state minimum)
  Comprehensive: $500 deductible
  UM/UIM: None

Listed Drivers:
  - Jennifer Park (primary)

Exclusions: None specific
Endorsements: None
```

**Verification scenarios:** This policy has NO collision coverage. If Jennifer is in a collision and is at fault, there is no coverage for her vehicle damage -- the claim is DENIED for collision. Her liability coverage pays the other party only. If the claim is comprehensive (theft, vandalism, weather), it is COVERED with a $500 deductible. No UM/UIM, so if hit by an uninsured driver, her only option is to pursue the at-fault party directly -- no UM coverage on this policy. No rental reimbursement. This policy represents a policyholder who chose minimal coverage to keep premiums low on an older, lower-value vehicle.

---

## Reasoning Framework for Coverage Verification

The Claims Officer should follow this reasoning process for every claim:

1. **Can I find the policy?** If the policy number is invalid or not found, request verification from the claimant before proceeding.

2. **Was the policy in force on the date of loss?** Check effective dates and payment status. Apply grace period analysis if lapsed. Document the finding.

3. **Does the policy cover this type of claim?** Match the claim category to the required coverage type. If the coverage type is missing, the claim cannot proceed under that category -- consider whether reclassification is appropriate (e.g., if the claim was categorized as collision but the proximate cause is actually weather, comprehensive may apply).

4. **Does any exclusion disqualify this claim?** Walk through every applicable exclusion. Document which exclusions were checked and cleared. If an exclusion applies, document the specific evidence.

5. **Is this a UM/UIM scenario?** If another party is at fault and their insurance status is in question, evaluate the UM/UIM path before defaulting to the standard coverage determination.

6. **What is the deductible and what are the limits?** Record both for downstream agents. If the claim is likely to exceed the coverage limit, flag this for Senior Reviewer awareness.

7. **State the outcome clearly:** COVERED, DENIED, CONDITIONAL, or UM/UIM_ROUTE. Provide the reasoning for each determination in the audit log. Every determination must be defensible if challenged by the claimant, a regulator, or in litigation.

---

*Reference document for Ohio Mutual Auto multi-agent claims processing system*
*Covers: Policy lookup protocol, coverage types, exclusion types, deductible determination, UM/UIM routing, coverage outcomes, mock policy database*
