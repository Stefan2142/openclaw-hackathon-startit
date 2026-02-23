> **WORK IN PROGRESS — DRAFT** — This document is under active development and should not be taken as final. Content may be incomplete or subject to change.

# Scenario Matrix Guide — Ohio Auto Insurance Claims

Companion guide for `SCENARIOS.csv`. Open the CSV in Excel/Google Sheets for filtering and sorting.

## Dimensions

The matrix covers **5 key dimensions** that determine how a claim is processed:

| # | Dimension | Values | Impact |
|---|-----------|--------|--------|
| 1 | **Driver** | Owner / Friend (permissive user) | Ohio permissive use: friend's OWN insurer pays first (Acuity v. Progressive, 2023); owner's policy is secondary |
| 2 | **Fault** | At-fault / Not-at-fault / Shared / Disputed | Determines coverage type, premium impact, and subrogation |
| 3 | **Police Report** | Yes / No | Affects fraud scoring, UM/UIM eligibility, and claim credibility |
| 4 | **Damage Severity** | Minor (<$1K) / Moderate ($1-5K) / Major ($5-15K) / Total Loss (>ACV) | Determines financial sense of filing |
| 5 | **Other Party** | Known+Insured / Known+Uninsured / Unknown(fled) / None | Determines which coverage to use |

## Coverage Type Quick Reference

| Situation | Coverage Used | Deductible | Premium Impact |
|-----------|--------------|------------|----------------|
| Other party at fault + insured | **Their Liability** | No | None |
| Other party at fault + uninsured | **Our UM/UIM** | Varies | None-Minimal |
| We are at fault (our car) | **Our Collision** | Yes ($500 typical) | +30-60% for 3-5yr |
| We are at fault (their car) | **Our Liability** | No | +30-60% for 3-5yr |
| Hit-and-run | **UM/UIM** (with police) or **Collision** | Yes | None (not-at-fault) |
| Weather/hail/flood | **Comprehensive** | Yes ($250 typical) | None-Minimal |
| Theft/vandalism | **Comprehensive** | Yes ($250 typical) | None-Minimal |
| Animal (deer) | **Comprehensive** | Yes ($250 typical) | None-Minimal |

## Ohio-Specific Rules

### Fault Rules
- **At-fault state** (tort system, not no-fault)
- **Modified comparative negligence** — 51% bar: you recover only if you're <51% at fault, reduced by your fault %. Statute of limitations: 2yr injury, 4yr property damage
- **Left-turn presumption** — left-turning driver presumed at fault; must yield to all oncoming. Exception: other was speeding, ran light, or reckless
- **Rear-end presumption** — rear driver almost always at fault
- **4-way stop** — first to arrive has right of way; simultaneous: left driver yields to right; left turn always yields to straight/right
- **Uncontrolled intersection** — first to arrive has right of way; simultaneous: left yields to right (ORC §4511.41)
- **T-intersection** — driver on terminating road yields to all cross traffic
- **Parking lot** — private property; Ohio traffic law doesn't fully apply but duty of care does; both moving often 50/50; one parked = other at fault

### Police Report (ORC §5502.11)
- **Required**: injury, death, or property damage >$1,000
- **Not required**: property damage <=$1,000, no injuries
- Filing a claim without a required police report is a **fraud indicator** (but not proof)
- Parking lots (private property): police may not respond to scene regardless

### Premium Impact
- Ohio average premium: ~$1,500/year
- At-fault surcharge: +30-60% for 3-5 years (= $1,350 to $4,500 total extra cost)
- Not-at-fault: generally no surcharge
- Comprehensive claims: minimal or no surcharge
- **Break-even rule**: If (damage - deductible) < expected premium increase → don't file

### Permissive Use (Friend Driving Your Car)
- **2023 Ohio Supreme Court (Acuity v. Progressive)**: Friend's own liability policy pays FIRST
- Owner's policy is SECONDARY (steps in only if friend has no insurance or insufficient limits)
- **Exceptions that void coverage**: business use, unlicensed driver, excluded driver, regular use without being listed on policy
- **ORC §4549.03**: Must stop and exchange info even in parking lots; if unattended car hit, notify police within 24 hrs

### UM/UIM
- Ohio: insurers must **offer** UM/UIM but it's **optional** — policyholder can decline
- HB 596 (pending Feb 2026) would make UM mandatory and raise minimums from 25/50 to 50/100 — not yet enacted
- ~12-17% of Ohio drivers are uninsured
- For hit-and-run: UM covers **bodily injury**; **Collision** covers vehicle damage (UMPD if no collision coverage)
- Police report essential for hit-and-run UM claims
- Ohio minimums: **25/50/25** ($25K per person / $50K per accident / $25K property)

### Premium Impact — Legal Protections
- **ORC §3937.22**: Insurers legally **prohibited** from raising premiums after a **single** not-at-fault accident per policy period
- **ORC §3937.23**: Same protection extends to UM/UIM claims where you were not at fault
- **Second** not-at-fault accident in the same period: CAN trigger an increase
- At-fault surcharges vary wildly: American Family +7%, State Farm +28%, GEICO +46-51%, Progressive +66-67%, Farmers +81%
- Most accident forgiveness programs: first at-fault accident only

## Financial Decision Framework

```
                         Damage Amount
                              |
                    ┌─────────┴──────────┐
                    ▼                    ▼
              < Deductible          > Deductible
                    |                    |
                 DON'T FILE        Check fault:
                                        |
                          ┌─────────────┴──────────────┐
                          ▼                            ▼
                    Not-at-fault                  At-fault
                          |                            |
                     FILE (no                  Calculate:
                     premium                   Payout vs
                     impact)                   Premium Cost
                                                    |
                                          ┌─────────┴──────────┐
                                          ▼                    ▼
                                    Payout > Cost         Payout < Cost
                                          |                    |
                                       FILE              DON'T FILE
                                                      (pay out of pocket)
```

**Quick math for at-fault claims:**
- Typical premium increase: ~$675/year for 3 years = **~$2,000 total**
- So: if (damage - $500 deductible) > $2,000 → worth filing
- That means: **damage should be >$2,500** to justify an at-fault claim
- For major at-fault: surcharge higher, but payout also higher — always worth filing above ~$5K

## Paper Accident Indicator (Fraud Pattern #3)

### What Is It?

Paper Accident = **the accident never happened**. Everything is fabricated — the collision, the damage, the police report, the repair estimate. The entire claim is fiction on paper.

### How Our Fraud Analyst Detects It

The Fraud Analyst checks for **convergence** of these indicators:

| Indicator | Weight | Why It Matters |
|-----------|--------|----------------|
| No police report for >$1K damage | Medium | Ohio law requires it — absence is suspicious |
| No independent witnesses | Medium | Only claimant's associates confirm the event |
| Walk-in police report (not at scene) | High | Report filed at station, not at accident location |
| No physical evidence at claimed location | High | No debris, paint transfer, or camera footage |
| Photos look staged | High | Wrong lighting, metadata doesn't match location/time |
| Repair shop flagged in prior fraud | High | Shop participating in the scheme |
| Damage doesn't match described accident | High | Physics of impact inconsistent |
| Claimant has multiple similar claims | Medium | Same pattern across insurers |
| Medical provider previously flagged | Medium | Known fraud-associated providers |

### Paper Accident Risk Scoring in the Matrix

| Risk Level | Combination |
|------------|-------------|
| **Low** | Police report present + witnesses + consistent evidence |
| **Low** | No police + <$1K + parking lot (all normal in Ohio) |
| **Medium** | No police + >$1K (should have reported per Ohio law) |
| **Medium** | Hit-and-run + no witnesses (but has photos/camera) |
| **Medium-High** | No police + >$1K + single vehicle + no witnesses |
| **High** | Hit-and-run + no police + no witnesses + >$1K |
| **High** | No police + friend driving + unknown other party + >$1K |

### Key Insight for Our Pipeline

A claim being a "paper accident" doesn't mean it IS fraud — it means it **matches the pattern** of how paper accidents look. Many legitimate claims share some indicators:
- Minor parking lot incidents legitimately have no police report
- Hit-and-runs legitimately have no witnesses
- Single vehicle accidents legitimately have no other party

**The Fraud Analyst's job is convergence**: one indicator = note it. Multiple converging indicators from this pattern = flag it. Flag + other patterns = escalate.

## Scenario Categories

| Category | Count | Key Variations |
|----------|-------|----------------|
| Rear-End (RE) | 9 | Owner/friend × fault × police × severity |
| Intersection-Signal (IS) | 5 | Green/red/disputed × police |
| Intersection-Sign (IN) | 6 | Stop/yield/uncontrolled/left-turn |
| Parking Lot (PL) | 8 | Parked/moving × known/unknown other × police |
| Single Vehicle (SV) | 6 | Pothole/deer/ice/pole/ditch |
| Hit-and-Run (HR) | 4 | Police/no-police × severity |
| Lane Change (LC) | 3 | At-fault/not-at-fault |
| Multi-Vehicle (MV) | 2 | Front/rear car in chain |
| Weather (WN) | 4 | Hail/flood/tree/tornado |
| Theft/Vandalism (TV) | 4 | Stolen/keyed/catalytic/break-in |
| Special (SP) | 8 | Road rage/DUI/uninsured/medical/teen/rideshare/cargo |

**Total: 59 scenarios**

## Pipeline Outcomes

| Outcome | Count | What It Means |
|---------|-------|---------------|
| **PAID** | ~35 | Full pipeline → payment issued |
| **PAID (with scrutiny)** | ~5 | Pipeline completes but Fraud Analyst flags indicators |
| **PAID (marginal)** | ~3 | Technically worth filing but borderline |
| **PAID (reduced)** | ~2 | Comparative negligence reduces payout |
| **NOT_FILED** | ~10 | Damage below deductible or premium cost > payout |
| **DENIED** | ~1 | Policy exclusion (e.g., DUI) |
| **ESCALATED** | ~3 | Senior Reviewer sends to human (fraud/complexity) |
