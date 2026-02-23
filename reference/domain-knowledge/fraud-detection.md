# Fraud Detection Pattern Catalog

Reference document for the Fraud Analyst agent. Covers soft vs hard fraud distinction, named fraud patterns, reasoning-based scoring framework, SIU referral criteria, fraud statistics, and anti-pattern warnings.

---

## 1. Soft Fraud vs Hard Fraud Distinction

This is the foundational framework. Every fraud assessment begins with classifying which type of fraud may be present, because the response protocol differs entirely.

### Hard Fraud

**Definition:** Deliberately fabricated or staged claims where the underlying loss event is invented, manufactured, or fundamentally misrepresented.

**Characteristics:**
- The accident, theft, or damage was intentionally caused or never happened at all
- Multiple parties may be coordinating a scheme
- Documentation may be forged or fabricated
- Criminal intent is present

**Response Protocol:**
1. **Investigate**: Gather evidence, document indicators, cross-reference against known patterns
2. **Refer to SIU**: Special Investigations Unit conducts detailed investigation
3. **Likely deny**: Claim denial based on fraud evidence, with documented reasoning
4. **Potential criminal prosecution**: Insurer may refer to law enforcement for prosecution
5. **Reserve rights letter**: Insurer notifies claimant that investigation is ongoing and rights are reserved

**Legal significance:** Hard fraud is a criminal offense. Conviction can result in imprisonment, fines, and restitution. The insurer has a legal obligation to report suspected fraud in most states.

### Soft Fraud

**Definition:** Exaggeration or opportunistic inflation of a legitimate claim. The underlying loss event actually occurred, but the claimant inflates the severity, cost, or extent of damage or injury.

**Characteristics:**
- A real accident or loss event did occur
- The claimant adds costs, injuries, or damage that are not attributable to the incident
- Intent may range from opportunistic ("might as well claim this too") to deliberate inflation
- Often involves cooperation with a repair shop, medical provider, or attorney

**Response Protocol:**
1. **Investigate**: Identify which portions of the claim are legitimate and which are inflated
2. **Negotiate reduced settlement**: Pay the legitimate portion, document why inflated portions were excluded
3. **Flag for future claims**: Claimant's history is noted for pattern detection on subsequent claims
4. **No SIU referral in most cases**: Unless the inflation is extreme or part of a repeated pattern
5. **Do not deny the entire claim**: The legitimate portion is still owed --- partial payment is appropriate

**Legal significance:** Soft fraud is typically a civil matter, not criminal. However, egregious or repeated soft fraud can escalate to criminal investigation. The insurer must still pay the legitimate portion of the claim in good faith.

### Why the Distinction Matters for the Fraud Analyst

The Fraud Analyst must classify which type because:

- **Hard fraud --> deny + refer**: The entire claim is suspect
- **Soft fraud --> negotiate + pay partial**: The claim is partially valid
- **Misclassifying soft as hard**: Denying a partially legitimate claim is bad faith exposure
- **Misclassifying hard as soft**: Paying a fraudulent claim and missing the criminal element
- **The recommendation to Senior Reviewer must specify**: hard fraud (recommend denial + SIU) vs soft fraud (recommend reduced settlement)

---

## 2. Named Fraud Patterns

### Quick Reference Table

| Pattern | Category | Key Indicators | Severity |
|---------|----------|---------------|----------|
| Staged Accident / Swoop-and-Squat | Hard | Low-speed rear-end, multiple injury claimants, coordinated participants | High |
| Phantom Passengers / Jump-In Claims | Hard | Passenger count exceeds capacity, late-filed passenger claims | High |
| Paper Accident | Hard | No physical evidence, fabricated documentation, no independent witnesses | High |
| Inflated Repair Estimates | Soft | Estimate above comparable claims, excessive labor hours, above-market parts pricing | Medium |
| Prior Damage / VIN Switching | Soft or Hard | Rust on fresh damage, damage inconsistent with incident, VIN tampering | Medium-High |
| Owner Give-Up | Either | Vehicle found stripped, owner underwater on loan, recent mechanical diagnosis | Medium-High |
| Organized Fraud Ring | Hard | Shared addresses/phones, same repair shop, same attorney, clustered filing dates | High |

---

### Hard Fraud Patterns

#### Pattern 1: Staged Accident / Swoop-and-Squat

**Description:** One or more fraudsters deliberately cause a traffic accident, typically by cutting in front of an unsuspecting driver and braking suddenly to force a rear-end collision. The innocent driver is at fault under rear-end liability presumptions in most jurisdictions.

**Variants:**
- **Swoop and squat**: One vehicle (swoop car) cuts in front of the target car, another (squat car) cuts in front of the swoop car and brakes hard. The swoop car swerves away, leaving the target to rear-end the squat car. The swoop car is never found.
- **Drive-down**: Fraudster waves a driver into traffic (at a merge or parking lot exit), then accelerates into them. Claims the other driver pulled out without looking.
- **Side-swipe setup**: At a dual-turn lane intersection, the fraudster drifts into the target vehicle during the turn and claims the target crossed lanes.

**Indicators:**
- Low-speed rear-end collision (designed to minimize real damage to fraudsters)
- Multiple occupants in the at-fault-claiming vehicle, all filing injury claims (whiplash, soft tissue)
- Occupants appear to know each other or share attorneys
- Witnesses who are friends or associates of the claimant
- Claimants quickly retain attorneys (often the same attorney across multiple staged claims)
- Vehicle has been involved in prior similar incidents
- Police report filed but details are vague or inconsistent
- Claimant not cooperative with independent medical exam

**Why it works:** Rear-end liability presumptions make the target driver automatically at fault in most states. Soft tissue injuries (whiplash) are difficult to disprove medically.

---

#### Pattern 2: Phantom Passengers / Jump-In Claims

**Description:** People who were NOT in the vehicle at the time of the accident claim they were passengers and file injury or bodily injury claims. The actual accident may be real, but the number of claimants is artificially inflated.

**Indicators:**
- Passenger count exceeds reasonable vehicle capacity (e.g., 5 injury claims from a 2-door coupe)
- No mention of passengers in the initial police report, but passengers file claims days or weeks later
- Passengers not mentioned by the policyholder during FNOL intake
- All "passengers" treated at the same medical facility or by the same attorney
- Passenger injury claims filed in a cluster pattern (same day, same forms)
- No independent evidence of passengers being present (no dash cam, no witness mentions)

**Why it works:** Verifying who was actually in a vehicle after the fact is difficult. The initial chaos of an accident means passenger lists are rarely documented at the scene.

---

#### Pattern 3: Paper Accident

**Description:** The accident never happened at all. All documentation --- police report, repair estimates, medical records, witness statements --- is fabricated. The claim is entirely fictional.

**Indicators:**
- No independent witnesses (all witnesses are associates of the claimant)
- No physical evidence at the claimed accident location (no debris, no paint transfer, no traffic camera footage)
- Police report filed as a "walk-in" report (not at the scene) or report number is not verifiable
- Repair shop associated with prior fraud cases or is an outlier in estimate patterns
- Vehicle shows no damage consistent with described accident, or damage was pre-existing
- Claimant has a history of similar claims across multiple insurers (NICB index check)
- Damage photos appear staged (wrong lighting, wrong location, metadata inconsistencies)
- Medical records show treatment by providers previously flagged for fraud

**Why it works:** Insurance systems are designed to process claims efficiently. A well-constructed paper trail can pass initial automated checks. Detection requires cross-referencing multiple data sources.

---

### Soft Fraud Patterns

#### Pattern 4: Inflated Repair Estimates

**Description:** A real accident occurred, but the repair estimate is inflated beyond what the actual damage warrants. May involve claimant-shop collusion or simply an opportunistic shop.

**Indicators:**
- Estimate significantly exceeds the range for comparable claims (same vehicle, same damage type, same region)
- Labor hours are excessive for the damage described (e.g., 40 hours for a bumper replacement that typically requires 8)
- Parts priced above market rates without justification
- OEM parts specified where aftermarket is standard for the vehicle age
- Estimate includes components not plausibly affected by the described impact
- Damage pattern does not match the described incident mechanics (e.g., front-end damage claimed from a rear-end hit)
- Repair shop has an unusually high average estimate compared to peers
- Shop and claimant have a prior relationship or shared connections

**Resolution approach:** The Assessor's own estimate serves as the baseline for comparison. Significant deviation between the claimant's estimate and the Assessor's independent estimate is a red flag. The resolution is to pay based on the Assessor's estimate, not the inflated one, with documented reasoning.

---

#### Pattern 5: Prior Damage / VIN Switching

**Description:** Damage that existed before the claimed incident is presented as new, incident-related damage. In more serious cases, the VIN plate is swapped between vehicles to disguise a vehicle's true damage history.

**Indicators:**
- **Rust or corrosion on "fresh" damage**: Bare metal from a recent collision does not have rust; oxidized damage is old
- **Paint oxidation on damaged panels**: Faded, chalky paint on broken surfaces indicates the break is not recent
- **Damage inconsistent with incident mechanics**: The physics of the described accident could not have caused the claimed damage pattern
- **VIN plate tampering**: Visible signs of VIN plate removal, re-riveting, or adhesive residue
- **Vehicle history mismatch**: Prior insurance claims, CARFAX reports, or state inspection records showing the same damage
- **Multiple claims on same vehicle in short period**: Same damage area claimed repeatedly

**Severity classification:**
- Simple prior damage claiming (not disclosing old dent) = **Soft fraud**
- VIN switching or identity fraud = **Hard fraud** (criminal)
- Deliberately staging a new incident to cover existing damage = **Hard fraud**

---

### Either Category Patterns

#### Pattern 6: Owner Give-Up (Vehicle Abandonment)

**Description:** The vehicle owner wants to get rid of a vehicle they can no longer afford or that has expensive mechanical problems. They stage a theft, total loss accident, or fire to collect the insurance payout rather than selling the vehicle at a loss.

**Indicators:**
- Vehicle found stripped (owner or associates removed valuable parts before staging the loss)
- Owner recently received a major mechanical diagnosis (engine or transmission failure, $3,000+ repair)
- Loan balance significantly exceeds ACV (the owner is "underwater" and would still owe money after selling)
- Recent increase in insurance coverage (raised limits shortly before the loss)
- Personal items removed from the vehicle before the "sudden" theft or accident
- Vehicle had been listed for sale recently (check online marketplaces)
- Keys found in ignition or with the "stolen" vehicle
- No forced entry signs on "stolen" vehicle

**Why it spans both categories:**
- **Hard fraud** when the owner actively stages the loss (arson, fake theft report)
- **Soft fraud** when the owner merely fails to prevent a loss or exaggerates existing damage to push past total loss threshold

---

#### Pattern 7: Organized Fraud Ring

**Description:** Multiple individuals coordinate to file fraudulent or inflated claims against the same event, the same insurer, or across multiple insurers. Rings may include claimants, attorneys, medical providers, and repair shops working together.

**Indicators:**
- **Shared addresses** among claimants who are not family members
- **Shared phone numbers** across multiple unrelated claims
- **Same repair shop** used by multiple claimants in the same incident
- **Same attorney** representing multiple claimants with similar claim narratives
- **Claims filed in clusters**: Multiple claims submitted within a narrow time window with similar formats
- **Geographic concentration**: Multiple claims from the same intersection, neighborhood, or route
- **Medical provider patterns**: Same provider treating all claimants, billing similar treatment codes
- **Financial linkages**: Payments routed to connected accounts or entities

**Ring detection requires cross-claim analysis.** A single claim from a ring member may not trigger suspicion. The pattern emerges only when claims are analyzed together --- which is why the Fraud Analyst should note potential ring indicators even when individual claim-level fraud confidence is low.

---

## 3. Fraud Scoring as Reasoning Framework

### How the Fraud Analyst Evaluates Claims

The Fraud Analyst evaluates each claim against the known pattern catalog above. The assessment is a **reasoning exercise**, not a numerical calculation.

**The process:**

1. **Review all claim data**: FNOL details, coverage determination, damage assessment, claimant history, incident description, documentation
2. **Compare against each known pattern**: Does this claim exhibit indicators consistent with any named pattern?
3. **Assess indicator strength**: A single indicator is a note. Multiple converging indicators from the same pattern are a flag. Multiple patterns with strong indicators are an escalation.
4. **Consider alternative explanations**: Legitimate claims can coincidentally match some fraud indicators. The Fraud Analyst must reason about whether the indicators have innocent explanations.
5. **Classify fraud type**: If fraud is suspected, is it hard fraud (fabricated) or soft fraud (exaggerated)?
6. **Produce a recommendation**: CLEAR / INVESTIGATE / REFER_SIU with documented reasoning

### Scoring Principles

The fraud assessment reflects the Fraud Analyst's reasoned confidence that fraud patterns are present. It is not a binary yes/no determination.

**Framework for reasoning:**

- **Consider the totality of indicators.** A single red flag warrants noting in the assessment but does not alone indicate fraud.
- **Multiple converging indicators warrant investigation.** When several indicators from the same pattern are present, the claim deserves closer scrutiny.
- **Pattern match to known fraud types warrants SIU referral.** When the claim closely matches a named fraud pattern with multiple strong indicators, SIU should be involved.
- **The assessment informs the Senior Reviewer's decision --- it does not determine the outcome.** The Fraud Analyst flags and recommends; the Senior Reviewer decides.
- **Document the reasoning, not just the conclusion.** The audit log must show which indicators were considered, which patterns were evaluated, and why the recommendation was made.

### What the Score Communicates

- **Low concern**: Claim data is consistent with the described incident. No significant fraud indicators. Recommendation: CLEAR.
- **Moderate concern**: Some indicators present but with plausible legitimate explanations. Recommend additional documentation or verification before proceeding. Recommendation: INVESTIGATE (gather more information).
- **High concern**: Multiple indicators from a named fraud pattern are present. Limited legitimate explanations. Recommendation: REFER_SIU (hard fraud) or NEGOTIATE_REDUCED (soft fraud).

---

## 4. SIU Referral Criteria

### When to Recommend Special Investigations Unit Referral

SIU referral is appropriate when:

1. **Hard fraud pattern match with supporting evidence**: The claim closely matches a named hard fraud pattern (staged accident, phantom passengers, paper accident) AND multiple indicators are present, not just one
2. **Organized ring indicators**: Evidence of coordination between multiple claimants, providers, or claims suggests organized fraud activity
3. **Significant claim value with multiple red flags**: Higher-value claims with fraud indicators warrant closer investigation because the financial exposure is greater
4. **Claimant has prior fraud history**: NICB index checks, prior SIU referrals, or prior claim denials for fraud on the same claimant
5. **Documentation anomalies suggesting fabrication**: Forged documents, altered photos, inconsistent police reports, or medical records from flagged providers

### What SIU Referral Is and Is Not

- **SIU referral IS a recommendation**, not a claim denial. The claim may still be partially valid (especially in soft fraud cases where the legitimate portion is owed).
- **SIU referral IS the Fraud Analyst's output** when hard fraud is suspected. The Fraud Analyst does not deny claims --- that is the Senior Reviewer's authority.
- **SIU does NOT exist in the hackathon pipeline** as a separate agent. The referral is an output document that would go to a human SIU team in production. For the hackathon, the Senior Reviewer receives the referral recommendation and makes the final decision.

### SIU Referral Output Format

The Fraud Analyst's SIU referral recommendation should include:

- Claim ID and summary
- Named fraud pattern(s) identified
- Specific indicators and evidence
- Hard fraud vs soft fraud classification
- Recommended action (deny, investigate further, pay partial)
- Confidence level in the assessment with reasoning

---

## 5. Fraud Statistics for Q&A

Numbers the team should be prepared to cite during the hackathon Q&A:

| Statistic | Value | Source |
|-----------|-------|--------|
| Annual fraud cost to U.S. economy | $308.6 billion | Coalition Against Insurance Fraud |
| Staged accidents trend (Q4 2024) | Up 47% year-over-year | Aviva Canada Fraud Prevention Report |
| Property-casualty claims with fraud element | Approximately 10% | Industry estimate (FBI, NICB) |
| Typical SIU referral rate | 5-8% of all claims | Industry average |
| Average fraud cost per household | ~$400-700/year in increased premiums | Coalition Against Insurance Fraud |
| Most common auto fraud type | Inflated repair estimates (soft fraud) | NICB data |
| Fastest growing fraud type | Staged accidents | Aviva 2024 report |

### Why These Numbers Matter for the Demo

- They demonstrate the team understands the scale of the fraud problem
- They justify why a dedicated Fraud Analyst agent exists in the pipeline
- They provide context for SIU referral rates (most claims are legitimate)
- They show awareness of current trends (staged accident increase)

---

## 6. Anti-Pattern Warnings

These are explicit design constraints for the Fraud Analyst agent and the system as a whole. Violating these creates regulatory liability and undermines business thinking credibility with judges.

### Do NOT Auto-Deny Based on Fraud Score Alone

The Fraud Analyst's output is a recommendation, not a decision. The decision authority belongs to the Senior Reviewer. A claim flagged for fraud may still have legitimate components that are owed to the policyholder.

**Why:** Auto-denial based on scoring is:
- A bad faith violation (denying without proper investigation)
- A hardcoded rule (violates the hackathon's "no hardcoded thinking" principle)
- Legally indefensible (a score is not evidence; it is an indicator)

### Do NOT Use Hardcoded Numerical Thresholds

Avoid patterns like "if fraud_score > 70 then deny" or "if claim_value > $25,000 then refer to SIU." These are hardcoded rules that the hackathon explicitly discourages.

**Instead:** The Fraud Analyst reasons about the weight and convergence of indicators. "Multiple indicators from a named fraud pattern with limited innocent explanations" is a reasoning framework. "Score > 70 = deny" is a rule table.

### Fraud Analyst Flags and Recommends; Senior Reviewer Decides

The separation between assessment and decision is both:
- **Correct insurance practice**: In real insurance organizations, SIU analysts investigate and recommend; claims managers decide
- **Regulatory compliance**: Separation prevents systematic denial patterns that create bad faith liability
- **Architectural strength**: Shows judges the team understands organizational design, not just technical implementation

### Finance Never Pays Without Senior Reviewer Approval

This is a hard constraint in the pipeline architecture. The Finance agent should verify that Senior Reviewer approval exists before processing any payment. This prevents:
- Fraud-flagged claims being paid before review
- Bypassing the decision gate through pipeline ordering bugs
- Audit trail gaps in the payment authorization chain

### Document Everything

Every fraud assessment must include:
- Which patterns were evaluated
- Which indicators were found (and which were absent)
- The classification (hard/soft/none)
- The recommendation and reasoning
- Any alternative explanations that were considered and dismissed

The audit log is the system's defense against bad faith allegations. If a claim is denied for fraud and the claimant sues, the documented reasoning in the audit log is what the insurer's legal team uses.

---

## Pattern Interaction Map

Fraud patterns do not exist in isolation. Understanding how patterns interact helps the Fraud Analyst identify more complex schemes:

```
[Staged Accident]
    + [Phantom Passengers] = Enhanced staged accident scheme
        (staged the collision AND added fake passengers for injury claims)

[Inflated Repair Estimates]
    + [Prior Damage] = Opportunistic inflation using pre-existing damage
        (real accident + existing damage bundled into one inflated claim)

[Owner Give-Up]
    + [Paper Accident] = Vehicle disposal disguised as accident
        (no real accident; fake documentation to cover intentional destruction)

[Organized Ring]
    + [Any Pattern Above] = Coordinated scheme across multiple claims
        (ring members execute the same pattern repeatedly across different insurers)
```

When multiple patterns converge on a single claim, the Fraud Analyst's confidence in fraud increases substantially. Document each pattern separately and note the interaction.

---

*Reference document for: Fraud Analyst Agent (AGENT-04)*
*Domain: Auto insurance fraud detection*
*Key dependency: Requires damage-assessment.md understanding (inflated repair is a fraud pattern that requires knowing what normal estimation looks like)*
