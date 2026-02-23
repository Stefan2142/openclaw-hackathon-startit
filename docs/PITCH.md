# Hackathon Pitch: Ohio Mutual Claims Processing
## 4-5 Minute Presentation

---

## Opening: Rachel's Problem (30 seconds)

Meet Rachel. She's the Chief Compliance Officer at Ohio Mutual Insurance.

Last quarter, Ohio's Department of Insurance fined her company $340,000. The reason? Their claims adjusters were consistently anchoring damage estimates to policy limits instead of actual damage. When an adjuster knows the policy pays up to $50,000, their estimates drift upward. When they see a $500 deductible, they round up to cover it.

This isn't fraud. It's human cognitive bias — anchoring. And it costs the industry billions annually while creating regulatory exposure.

Rachel needs a system where the person estimating damage literally cannot see the financial numbers.

---

## The Problem: Anchoring Bias (45 seconds)

In traditional claims processing, the adjuster sees everything:
- The policy limits
- The deductible amount
- The damage

Research shows this creates **anchoring bias** — estimates unconsciously drift toward known financial reference points. This is:

- **A compliance violation** — regulators specifically look for estimate-to-limit correlation
- **Financially wasteful** — inflated estimates cost insurers millions
- **Hard to fix with humans** — you can't un-see a number. Training helps but doesn't eliminate the bias.

The insurance industry has tried training, audits, blind reviews. None of it works because the problem is architectural — the same person has access to both financial data and damage assessment.

---

## The Solution: Enforced Data Boundaries (60 seconds)

We built a **6-agent pipeline** on OpenClaw where data segregation is enforced at the architecture level, not the policy level.

```
Router → Claims Officer → Assessor → Fraud Analyst → Senior Reviewer → Finance
```

The key innovation: **The Assessor agent physically cannot see the deductible or coverage limit.**

This isn't a rule we told the AI to follow. It's enforced at the database level:

```sql
SELECT claim_data
  #- '{pipeline,claims_officer,deductible_amount}'
  #- '{pipeline,claims_officer,coverage_limit}'
FROM claims WHERE claim_id = $1;
```

The Assessor calls `get-claim-assessor` instead of `get-claim`. The financial fields are stripped before the data ever reaches the agent. There is no prompt that says "ignore the deductible" — the deductible simply doesn't exist in the Assessor's world.

**Only Finance** sees both the damage estimate AND the financial limits to calculate the final payment.

---

## Live Demo (90 seconds)

*[Open Telegram, submit a claim]*

Watch the pipeline process a collision claim:
1. **Router** receives the message, creates the claim, starts the pipeline
2. **Claims Officer** verifies the policy, confirms coverage, sets deductible to $500
3. **Assessor** estimates $4,200 in damage — note: it has NO idea the deductible is $500 or what the coverage limit is
4. **Fraud Analyst** scores risk at 12/100 (low), recommends CLEAR
5. **Senior Reviewer** reviews all evidence, approves the claim
6. **Finance** calculates payment: $4,200 - $500 deductible = $3,700

*[Show the database — Assessor's view vs full claim data]*

The Assessor's estimate of $4,200 was made purely on damage assessment. No anchoring. No bias. Defensible under audit.

---

## Why This Matters (30 seconds)

This pattern — **enforced data boundaries between AI agents** — solves a class of problems that exist across regulated industries:

- **Insurance:** Estimate-to-limit anchoring (what we built)
- **Healthcare:** Diagnosis without billing influence
- **Legal:** Evidence evaluation without settlement pressure
- **Finance:** Risk assessment without portfolio exposure

Multi-agent systems aren't just about splitting work. They're about **creating information boundaries that humans can't maintain** but architecture can enforce.

---

## Technical Highlights (30 seconds)

- **6 specialized agents** on OpenClaw, each with their own AGENTS.md specification
- **PostgreSQL** with JSONB for flexible claim documents
- **SQL-level data stripping** — not prompt-level, not application-level
- **Full audit trail** — every agent logs structured traces (START/STEP/END)
- **Pin-test framework** — test each agent in isolation with seeded data
- **7 fraud patterns** with convergence-based scoring (not just flag counting)
- **Ohio regulatory compliance** — FCSP timelines, 100% ACV rule, bad faith checks

---

## Close (15 seconds)

Rachel's problem isn't unique. Every regulated industry needs AI systems where information boundaries are architectural guarantees, not just policies.

We built the proof that multi-agent systems can enforce compliance that humans can't.

Thank you.

---

## Q&A Defense Points

- **"Why not just tell the AI to ignore the number?"** — Prompt-level instructions can be overridden, forgotten, or worked around. SQL-level stripping is a guarantee. You can't be biased by data you never received.
- **"Is anchoring bias real?"** — Yes, extensively documented. Tversky & Kahneman (1974), and specifically in insurance by the NAIC and state regulators. Ohio DOI specifically audits for estimate-to-limit correlation.
- **"Why 6 agents instead of 1?"** — Separation of concerns. Each agent has exactly the data it needs and nothing more. This is the same principle as least-privilege access in security.
- **"What about latency?"** — Sequential pipeline takes ~2-3 minutes total. Acceptable for claims processing where regulatory timelines are measured in days.
- **"What happens when fraud is detected?"** — The Fraud Analyst flags and recommends; only the Senior Reviewer can deny. This prevents false positive denials and ensures every denial is reviewed.
