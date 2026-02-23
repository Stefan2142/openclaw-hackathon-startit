# Damage Assessment Methodology

Reference document for the Assessor agent. Covers damage estimation, Ohio total loss rules, parts selection, rental reimbursement, pre-existing damage detection, and hidden damage awareness.

---

## 1. Damage Estimation Methodology

Damage estimation is a professional judgment exercise, not a formula. An experienced adjuster synthesizes multiple cost categories and applies knowledge of vehicle construction, repair procedures, and local market rates to produce an estimate that reflects the actual cost of returning the vehicle to its pre-loss condition.

### Cost Categories

**Labor Cost**
- Calculated as: labor hours x applicable labor rate
- Three distinct labor rate categories:
  - **Body labor**: Structural and panel repair/replacement (e.g., quarter panel straightening, bumper replacement)
  - **Mechanical labor**: Drivetrain, suspension, engine-related repairs (typically highest hourly rate)
  - **Paint labor**: Surface preparation, priming, color matching, clear coat application
- Labor hours are estimated based on the specific repair operations required, referencing industry databases (Mitchell, CCC, Audatex) as guidelines
- Rates vary by geographic market, shop certification level, and whether the shop is in-network or independent

**Parts Cost**
- Replacement parts priced at current market rates
- Part selection framework (see Section 3 below) determines OEM vs aftermarket vs salvage/recycled
- Parts pricing includes: list price, core charges (for remanufactured parts), and applicable markup

**Paint and Materials**
- Paint material costs cover: primer, basecoat, clearcoat, blending materials
- Color matching complexity affects cost (multi-stage pearls, tri-coats cost more)
- Material costs are typically estimated as a flat rate per refinish hour or per panel

**Supplemental Costs**
- Towing charges (from accident scene to repair facility)
- Storage fees (if vehicle held at tow yard before inspection)
- Teardown/disassembly charges for hidden damage inspection
- Disposal fees for hazardous materials (refrigerant, fluids)

### Estimation Approach

The Assessor evaluates damage based on structured damage descriptions and photo references provided as input. The estimation is not live ML inference on photos --- it is a reasoning exercise where the Assessor:

1. **Identifies affected components** from the damage description (panels, structural members, mechanical systems, glass, trim)
2. **Determines repair vs replace** for each component based on damage severity, component type, and economic feasibility
3. **Estimates labor hours** for each operation by reasoning about complexity, access difficulty, and adjacent component interference
4. **Selects parts** using the OEM vs aftermarket framework (Section 3)
5. **Calculates paint operations** based on panels requiring refinish and blending into adjacent panels
6. **Considers totality** --- does the combined estimate approach the vehicle's value? (See Section 2)

### What an Experienced Adjuster Considers

- **Impact direction and force**: A frontal hit at 35 mph causes different damage patterns than a side-swipe at 15 mph
- **Vehicle construction type**: Unibody vs body-on-frame affects repair approach and cost
- **Crumple zone engagement**: Whether energy-absorbing structures were activated (indicates structural repair)
- **Component interdependencies**: Replacing a fender may require removing headlight, bumper, and trim pieces (included labor)
- **Prior condition of the vehicle**: A vehicle with existing wear may have lower baseline value and different repair economics
- **Diminished value implications**: Structural repairs permanently affect vehicle value (flag for Senior Reviewer)

---

## 2. Ohio Total Loss Determination

This is the single most important state-specific rule the team must know.

### The Ohio 100% ACV Rule

**Ohio uses the 100% Actual Cash Value (ACV) threshold for total loss determination.**

- If the estimated cost of repair **equals or exceeds** the vehicle's ACV, the vehicle is declared a **total loss**
- The vehicle is NOT repaired; instead, the insurer settles based on the vehicle's pre-loss value

### Why This Matters

Most states use a 70-80% threshold (e.g., if repair cost reaches 75% of ACV, the vehicle is totaled). Ohio is one of the stricter states, requiring the repair cost to reach 100% of ACV before total loss is triggered. This means:

- More vehicles are repaired in Ohio than in lower-threshold states
- Vehicles with repair estimates at 85-95% of ACV are repaired in Ohio but would be totaled in most other states
- The Assessor must be precise about estimates near the ACV threshold because the outcome changes dramatically

### ACV Determination

**Actual Cash Value** = the fair market value of the vehicle immediately before the loss occurred, accounting for:

- **Year, make, model, trim level**
- **Mileage** (higher mileage reduces ACV)
- **Overall condition** (prior damage, wear, maintenance history)
- **Local market conditions** (regional pricing differences)
- **Equipment and options** (factory options, aftermarket additions with documentation)
- **Comparable sales data** (what similar vehicles are selling for in the local market)

ACV is NOT the original purchase price, trade-in value, or loan balance. It is the replacement cost for a substantially similar vehicle in the same condition.

### Total Loss Settlement Process

When total loss is declared:

1. **Insurer determines ACV** using market data, comparable sales, and condition assessment
2. **Payout = ACV minus applicable deductible**
3. **Insurer takes ownership of the salvage** (damaged vehicle)
4. **Salvage value is estimated** based on: damage severity, vehicle desirability for parts, scrap metal value, and salvage auction market
5. **Policyholder notification** includes: ACV determination with supporting data, deductible applied, salvage disposition

### Policyholder's Right to Retain Salvage

The policyholder may choose to keep the damaged vehicle. In this case:

- **Payout = ACV minus deductible minus salvage value**
- The vehicle receives a **salvage title** (branded title), which:
  - Significantly reduces future resale value
  - May affect future insurability
  - Requires inspection before re-registration in many states
- The policyholder assumes responsibility for repair or disposal

### Salvage Value Estimation Principles

Salvage value depends on:
- **Extent and location of damage** (engine/drivetrain intact = higher salvage value)
- **Vehicle age and desirability** (popular models have higher parts demand)
- **Salvage auction market conditions** (seasonal and regional variation)
- **Typically ranges from 10-30% of pre-loss ACV** for moderately damaged vehicles

---

## 3. OEM vs Aftermarket Parts Decision Framework

### Part Types

| Type | Description | Fit & Quality | Cost | Effect on Vehicle Value |
|------|-------------|---------------|------|------------------------|
| **OEM** (Original Equipment Manufacturer) | Made by or for the vehicle manufacturer; exact specification match | Guaranteed fit, factory finish | Highest | Preserves value |
| **Aftermarket** | Made by independent manufacturers to match OEM specifications | Generally good fit; may vary by manufacturer | 20-50% less than OEM | May reduce value; disclosure recommended |
| **Salvage/Recycled** | Genuine OEM parts removed from other vehicles | OEM quality; condition varies | 50-75% less than new OEM | Acceptable for older vehicles |
| **Remanufactured** | Used parts rebuilt to OEM specifications | Near-OEM quality | 30-50% less than new OEM | Acceptable for mechanical components |

### Decision Framework

**Principle: Vehicles under 3 years old OR under 36,000 miles --> recommend OEM parts**

This is a judgment principle, not a hardcoded rule. The reasoning:

- Newer vehicles have higher value to protect
- OEM parts maintain warranty coverage where applicable
- Fit and finish expectations are higher on newer vehicles
- Some state regulations require or strongly recommend OEM for newer vehicles
- Diminished value claims are more likely on newer vehicles, and aftermarket parts can compound the loss

**For older vehicles / higher mileage:**

- Aftermarket parts are generally acceptable
- Policyholder should be informed of the parts selection and given the option to upgrade to OEM at their expense
- Recycled OEM parts may be the best value option (OEM quality at reduced cost)
- Safety-critical components (airbags, structural members, restraint systems) should always be OEM regardless of vehicle age

### Impact on Diminished Value Claims

- A vehicle repaired with aftermarket parts may face a larger diminished value claim because the repair did not restore it to original specification
- Senior Reviewer should be aware that parts selection affects downstream liability
- Document parts selection reasoning in the estimate for audit purposes

---

## 4. Rental Reimbursement Calculation

Rental reimbursement is only available if the policyholder's policy includes rental coverage. The Claims Officer output should confirm rental coverage status.

### Standard Rental Allowance

- **Typical daily rate**: $30-50/day (varies by policy terms and vehicle class)
- **Policy cap**: Usually expressed as a daily maximum and total maximum (e.g., $40/day up to $1,200 total)
- Policyholder may rent a vehicle of comparable class, paying any difference above the daily allowance out of pocket

### Rental Days Tied to Repair Timeline

- **Repairable vehicles**: Rental days = estimated repair days + reasonable parts ordering delay
  - Light damage (cosmetic only): 3-5 days
  - Moderate damage (panel replacement, paint): 5-10 days
  - Heavy damage (structural repair): 10-20 days
  - Supplement delays may extend rental period (flag to Senior Reviewer)
- **Total loss vehicles**: Rental typically capped at a reasonable period to locate a replacement vehicle
  - Standard: up to 10 days from total loss declaration
  - May extend if comparable replacement is not readily available (market conditions, specialty vehicle)

### Assessor Responsibilities

- Estimate repair timeline in business days
- Calculate rental entitlement based on policy terms (from Claims Officer output)
- Flag if rental period is likely to exceed policy cap
- Note rental coverage status in the estimate output

---

## 5. Pre-existing Damage Detection

Pre-existing damage is damage present on the vehicle before the claimed incident. Only incident-related damage is covered --- pre-existing damage must be identified and excluded from the estimate.

### Indicators of Pre-existing Damage

**Physical Evidence:**
- **Rust or corrosion on impact areas**: Fresh collision damage exposes bare metal; rust takes weeks to months to develop. Rust on "fresh" damage areas is a strong pre-existing indicator
- **Paint oxidation on damaged panels**: Faded, chalky, or discolored paint on damaged surfaces indicates prolonged exposure, not recent impact
- **Damage in non-impact zones**: Dents, scratches, or damage on panels that could not have been affected by the described incident
- **Mismatched paint**: Different paint shades between adjacent panels suggest prior repair
- **Prior repair evidence**: Bondo/body filler, non-factory welds, adhesive residue, non-OEM parts already installed

**Inconsistency Analysis:**
- **Damage inconsistent with incident mechanics**: Rear-end collision should not cause front-end damage; side-swipe should not damage roof; low-speed impact should not cause frame distortion
- **Damage severity inconsistent with described speed**: Minor parking lot tap should not produce $8,000 in damage
- **Multiple unrelated damage patterns**: Different types of damage (scratches going one direction, dent from another direction) suggest multiple incidents

### Response Protocol

When pre-existing damage is detected:

1. **Document specifically** which damage components are pre-existing and which are incident-related
2. **Reduce the estimate** to cover only incident-related damage
3. **Flag for conditional approval** pending physical inspection by an independent appraiser
4. **Note in audit log** the specific indicators that led to the pre-existing determination
5. **Do not deny the entire claim** --- legitimate incident damage is still covered even if some damage is pre-existing

### Relationship to Fraud Detection

Pre-existing damage claiming crosses from damage assessment into fraud territory when:
- The claimant explicitly describes pre-existing damage as part of the current incident
- The damage pattern suggests the incident was staged to cover existing damage
- Vehicle history (prior claims, prior repair records) shows a pattern

In these cases, the Assessor flags for the Fraud Analyst (see fraud-detection.md) while still completing the damage assessment for the legitimate portion.

---

## 6. Hidden Damage Likelihood

Hidden damage is damage that exists but is not visible during initial assessment because it is concealed behind exterior panels, under components, or within structural cavities. Hidden damage is normal and expected --- it does not indicate fraud.

### Common Hidden Damage Locations

**Behind Exterior Panels:**
- Structural reinforcements behind bumper covers
- Inner fender liners and splash shields
- Radiator support and cooling system components
- Wiring harnesses routed behind panels

**Frame and Structural:**
- Unibody rail damage (hidden behind quarter panels)
- Subframe distortion (hidden under the vehicle)
- Pillar damage (hidden behind interior trim and airbag assemblies)
- Floor pan buckling (hidden under carpet and insulation)

**Suspension and Alignment:**
- Bent control arms or knuckles (not always visible)
- Damaged wheel bearings (symptom: noise, not visual)
- Strut tower damage (hidden under engine bay components)
- Alignment issues from impact (requires measurement, not visual inspection)

### Indicators That Hidden Damage Is Likely

- **Gap irregularities**: Uneven panel gaps between doors, hood, trunk suggest structural shift
- **Door alignment issues**: Doors that don't close properly or have changed gap dimensions
- **Fluid leaks**: Coolant, power steering fluid, or transmission fluid appearing after impact
- **Airbag deployment**: Any airbag deployment indicates severe impact force and near-certain structural involvement
- **Crumple zone engagement**: Visible deformation of energy-absorbing structures means force propagated inward

### Assessor Response

1. **Flag as "supplement likely"** in the initial estimate
2. **Estimate the supplement range** based on damage type and severity (e.g., "structural involvement likely --- supplement estimate $1,500-$3,000")
3. **Recommend teardown inspection** at a qualified repair facility
4. **Senior Reviewer may pre-authorize** a supplement threshold to avoid delays (e.g., "authorize up to $2,500 in supplements without re-review")
5. **Track supplement history** in the claim audit log for transparency

---

## Quick Reference: Ohio-Specific Numbers and Rules

| Item | Value | Source |
|------|-------|--------|
| **Total loss threshold** | 100% of ACV | Ohio Revised Code |
| **ACV definition** | Fair market value immediately before loss | Industry standard |
| **Salvage title** | Required when vehicle is declared total loss | Ohio BMV |
| **OEM parts recommendation** | Vehicles under 3 years / 36,000 miles | Industry best practice |
| **Typical collision deductible** | $500 (policy-dependent) | Common default |
| **Typical comprehensive deductible** | $250 (policy-dependent) | Common default |
| **Rental reimbursement (repairable)** | Tied to repair days | Policy terms |
| **Rental reimbursement (total loss)** | Up to ~10 days | Industry standard |
| **Supplement pre-authorization** | Senior Reviewer decision | Internal policy |

### Key Comparisons for Q&A

- **Ohio vs most states**: Ohio requires 100% of ACV for total loss; most states use 70-80%. This means Ohio insurers repair more vehicles and total fewer.
- **OEM vs aftermarket**: Not a regulatory mandate in Ohio, but a judgment principle. Newer vehicles get OEM; older vehicles get aftermarket with disclosure.
- **Pre-existing vs incident damage**: Only incident damage is covered. The Assessor must distinguish and document. This is an assessment judgment, not an automatic denial.

---

*Reference document for: Assessor Agent (AGENT-03)*
*Domain: Auto insurance damage assessment*
*Key dependency: Feeds into fraud-detection.md (inflated repair is a fraud pattern that requires understanding normal estimation)*
