# Regulatory Compliance Reference

## Purpose

This document provides the regulatory compliance knowledge every team member must know cold before Feb 21. It covers Fair Claims Settlement Practices (FCSP) Act timelines, documentation retention requirements, bad faith exposure triggers, and how the system enforces compliance through reasoning frameworks rather than hardcoded rules.

---

## Quick Reference

| Regulation | Timeline | Source |
|-----------|----------|--------|
| Claim acknowledgment | 10-15 business days from FNOL receipt | NAIC model: 10 days; California: 15 calendar days |
| Coverage decision | 40 calendar days after proof of loss received | FCSP Act (California standard, representative) |
| Payment after acceptance | 30 calendar days | FCSP Act |
| Documentation retention | Minimum 5 years | Varies by state; Ohio follows NAIC model |

**Ohio note:** Ohio follows the NAIC model act. Frame all Q&A answers around NAIC standards rather than claiming Ohio-specific regulatory precision.

---

## 1. Fair Claims Settlement Practices (FCSP) Act Timelines

### The Numbers the Team Must Know

**Claim Acknowledgment: 10-15 Business Days from FNOL Receipt**

When a claimant files a First Notice of Loss, the insurer must formally acknowledge receipt within the regulatory window. The NAIC model act specifies 10 business days. California extends this to 15 calendar days. The system should default to the most conservative applicable standard for the relevant jurisdiction.

What this means for the system: The Front Desk agent must record the exact timestamp when the FNOL is received. The Router tracks elapsed time from this timestamp and flags when the claim is approaching the acknowledgment deadline. This is not a timer set to a specific number of days -- it is a compliance tracking mechanism that reasons about the applicable regulatory window.

**Coverage Decision: 40 Calendar Days After Proof of Loss Received**

Once the insurer has received the proof of loss (the documentation supporting the claim), a coverage decision must be reached within 40 calendar days. This clock starts when the proof of loss is complete and accepted, not when the FNOL is filed.

What this means for the system: The Claims Officer records when proof of loss is received. Every subsequent agent in the pipeline is aware that a regulatory clock is ticking. The Senior Reviewer must see the timeline status before making a final decision. If the claim is approaching the 40-day window without resolution, the system escalates with urgency.

**Payment After Acceptance: 30 Calendar Days**

Once a claim is accepted and approved, payment must be issued within 30 calendar days. Delays beyond this window expose the insurer to bad faith liability.

What this means for the system: The Finance agent tracks the time between Senior Reviewer approval and payment issuance. The payment must be issued promptly. Any delay must be documented with a specific reason.

### Why These Timelines Matter

- Exceeding any of these deadlines without documented justification creates bad faith exposure
- Regulators can audit claim files years after the fact and check whether timelines were met
- The system's audit log is the primary defense against bad faith allegations related to delays
- Judges will ask about these specific numbers -- being able to cite them from memory demonstrates genuine regulatory understanding

---

## 2. Documentation Retention Requirements

### What Must Be Retained

**Minimum 5-year retention for all claim files.** This varies by state, but 5 years is the conservative baseline that covers most jurisdictions.

**Every claim file must contain:**

- The original FNOL report with timestamp
- All coverage verification results (policy status, applicable coverages, exclusions checked)
- Damage assessment details (estimate methodology, total loss determination rationale)
- Fraud analysis results (risk score, patterns checked, recommendation)
- Senior Reviewer decision with written rationale
- Payment records (amount, calculation methodology, date issued)
- All status changes with timestamps
- The complete audit log of every agent decision with reasoning

### Why Retention Matters

Regulators can audit claim files years after the claim is closed. If the insurer cannot produce a complete record showing:
- What was decided at each stage
- Why it was decided
- When it was decided
- Who (or which agent) made the decision

...then the insurer faces regulatory sanctions and potential bad faith liability regardless of whether the original decision was correct.

### System Implementation

Every agent writes to the audit log with:
- Timestamp (ISO 8601 format)
- Agent identifier
- Action taken
- Reasoning for the action
- Any flags raised
- References to applicable regulations or policy provisions

The audit log is append-only. No agent can modify or delete previous entries. This creates an immutable record that satisfies regulatory retention requirements.

---

## 3. Bad Faith Exposure Triggers

Bad faith occurs when an insurer fails to act in good faith toward its policyholder. The following actions (or failures to act) create bad faith liability:

### Delay-Related Triggers

- **Unreasonable delay in acknowledging claim** -- Failing to acknowledge the FNOL within the regulatory acknowledgment window without documented justification
- **Failing to investigate promptly and thoroughly** -- Receiving a claim and not assigning it for investigation, or conducting only a superficial investigation
- **Failing to communicate claim status to policyholder** -- The policyholder has no idea what is happening with their claim; no status updates are provided

### Decision-Related Triggers

- **Denying claim without reasonable basis** -- Issuing a denial that cannot be supported by specific policy language or investigation findings
- **Low-balling: offering substantially less than claim is worth** -- Making an unreasonably low settlement offer to pressure the claimant into accepting less than the documented value
- **Misrepresenting policy provisions to deny coverage** -- Citing exclusions or limitations that do not actually apply, or interpreting policy language in a way that contradicts its plain meaning

### Documentation-Related Triggers

- **Failing to provide written explanation for denial** -- Every denial must cite the specific policy provision that supports it and provide the basis for the decision in writing
- **Incomplete investigation documentation** -- If the investigation file does not show thorough work, the denial looks arbitrary even if the decision was correct

### How the System Prevents Bad Faith

The system's architecture is designed to prevent bad faith through structural safeguards:

1. **Documented reasoning on every decision** -- Every agent records why it made each decision, not just what it decided. This creates a defensible record.

2. **Timeline tracking** -- The system tracks elapsed time from FNOL and flags when the claim is approaching regulatory deadlines. This prevents delay-based bad faith.

3. **Escalation triggers** -- When a claim approaches a deadline, the Senior Reviewer receives an urgency flag. Claims are not allowed to silently stall.

4. **Denial documentation** -- When a claim is denied, the system requires the specific policy provision to be cited, the investigation findings to be documented, and the denial rationale to be written in plain language.

5. **Audit trail** -- The complete decision chain is preserved. Any regulatory audit can trace exactly how and why a claim was handled the way it was.

---

## 4. Regulatory Compliance as Reasoning Framework

### The Principle

Compliance is not a set of hardcoded timers. It is a reasoning framework that agents apply to every decision.

**Wrong approach (hardcoded):**
"Set timer to 15 days. If timer expires, send alert."

**Right approach (reasoning framework):**
"Acknowledge within the regulatory window for the relevant jurisdiction. Default to the most conservative applicable standard. Record which regulation governs this decision. If the claim is approaching the applicable deadline, escalate with documented urgency."

### How Agents Apply This

**Front Desk:** Records the claim receipt timestamp and notes the start of the regulatory clock. Does not hardcode a deadline number -- records the jurisdiction and the applicable standard.

**Claims Officer:** References the regulatory timeline when making coverage decisions. Documents how long the investigation has taken and why. If the investigation requires more time (e.g., waiting for police report), documents the specific reason for the delay.

**Senior Reviewer:** Before making a final decision, checks:
- How much time has elapsed since FNOL
- Whether the claim is within, approaching, or exceeding the applicable regulatory window
- Whether any delays are documented with specific justification
- Whether the decision rationale is sufficient to withstand regulatory review

**Finance:** Tracks the time between approval and payment issuance. Ensures payment is processed within the applicable window. Documents any delay.

### Q&A Defense Points

When judges ask about regulatory compliance, the team should be able to say:

- "Our system tracks three FCSP timelines: 10-15 day acknowledgment from FNOL, 40-day coverage decision from proof of loss, and 30-day payment from acceptance."
- "Every agent decision includes a timestamp and reasoning in the audit log, creating a complete regulatory trail."
- "We default to the most conservative applicable standard for the jurisdiction -- NAIC model act for Ohio."
- "Bad faith prevention is structural: the system escalates when approaching deadlines rather than waiting for them to expire."
- "Documentation retention satisfies the 5-year minimum through our immutable audit log."

---

## Sources

- NAIC (National Association of Insurance Commissioners) -- Claims Settlement Provisions Chart, Spring 2024
- California Department of Insurance -- Fair Claims Settlement Practices Regulations (CCR Title 10, Sections 2695.1-2695.14)
- Justia -- Bad faith insurance law overview
- NAIC model act -- Ohio follows NAIC standards for claims handling

---
*Domain knowledge reference for: Ohio Mutual Auto Claims Processing System*
*Created: 2026-02-17*
*Hackathon context: OpenClaw Business Engineering Hackathon, Feb 21 2026, Belgrade*
