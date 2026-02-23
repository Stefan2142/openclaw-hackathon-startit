# Ohio Mutual Auto -- 5-Minute Presentation Script

Complete presentation script with second-level timing marks. Read the **spoken text** aloud. Follow **[ACTION]** markers for screen transitions and commands. This script is designed to be read verbatim -- every sentence is written to be spoken naturally.

---

## Section 1: Problem Setup (0:00 - 0:30)

**[ACTION] Slide 1: Title slide -- "Ohio Mutual Auto: Multi-Agent Claims Processing"**

> "Auto insurance claims processing is broken. A single claim touches six or more specialists -- intake, coverage, damage assessment, fraud analysis, review, and payment. Each handoff takes hours or days. Each handoff is a point where compliance failures, fraud, and bad faith exposure creep in."

*[0:12]*

> "Ohio's Fair Claims Settlement Practices Act requires acknowledgment within 10 to 15 days and a decision within 40 days. Miss those deadlines and the insurer faces regulatory action and bad faith lawsuits."

*[0:20]*

> "So here is the question: What if you could process a claim through every specialist -- intake, coverage, damage assessment, fraud analysis, review, and payment -- in minutes instead of weeks, with a complete audit trail that proves regulatory compliance at every step?"

*[0:30]*

---

## Section 2: Architecture Overview (0:30 - 1:30)

**[ACTION] Slide 2: System architecture diagram (docs/ARCHITECTURE.md Section 1 ASCII art)**

> "This is Ohio Mutual Auto. Built on OpenClaw, it uses seven AI agents arranged in a sequential pipeline."

*[0:37]*

> "At the top is the OpenClaw gateway. It receives claim submissions and routes them to the Router -- our orchestrator agent. The Router is the only depth-zero agent. It reads the claim, generates a unique claim ID, writes the initial JSON record, and then spawns each pipeline agent one at a time using OpenClaw's sessions_spawn primitive."

*[0:52]*

**[ACTION] Point to each pipeline stage as you name it**

> "Six pipeline agents process the claim sequentially. Stage 1: Front Desk handles FNOL intake and categorization. Stage 2: Claims Officer verifies coverage and checks exclusions. Stage 3: Assessor estimates damage and checks for total loss. Stage 4: Fraud Analyst runs pattern detection across seven named fraud schemes. Stage 5: Senior Reviewer makes the final decision -- approve, deny, conditional, or escalate to a human. Stage 6: Finance calculates payment and identifies subrogation opportunities."

*[1:12]*

> "Every agent has scoped tools -- least privilege. Pipeline agents get read and write only. They cannot spawn sub-agents. They cannot execute scripts. The one exception is Finance, which gets exec access to run a mock payment simulation."

*[1:22]*

> "The shared claim JSON file is the single source of truth. Every agent reads it, writes to its section, and appends to the audit log. No database. No message queue. JSON files for transparency."

*[1:30]*

---

## Section 3: Business Logic Deep Dive (1:30 - 3:00)

**[ACTION] Slide 3: Agent detail grid (or stay on architecture slide and point)**

> "This is where it gets interesting. Let me walk you through what each agent actually knows -- because none of these decisions are hardcoded if-then rules. Each agent uses reasoning frameworks, principles and judgment guidelines that work like a real adjuster's training, not a decision tree."

*[1:42]*

> "The Front Desk categorizes claims into collision, comprehensive, liability, theft, vandalism, or weather events. It detects catastrophe events, assigns priority, and flags missing information."

*[1:50]*

> "The Claims Officer is the gatekeeper. It does a full policy lookup -- checks that the policy was active on the date of loss, not the date of filing. It reviews every exclusion: intentional acts, racing, commercial use, excluded drivers. And here is the key -- it applies the ambiguity doctrine: if coverage language is ambiguous, it is construed in the claimant's favor. That is Ohio insurance law."

*[2:07]*

> "The Assessor breaks down repair cost into labor, parts, and paint. It applies Ohio's 100 percent ACV total loss rule. For vehicles under three years or 36,000 miles, it recommends OEM parts. It flags pre-existing damage and estimates hidden damage likelihood."

*[2:20]*

> "The Fraud Analyst is where our system really shines. It checks seven named fraud patterns: staged accidents, phantom passengers, paper accidents, inflated repairs, prior damage fraud, friendly tow schemes, and VIN switching. It uses indicator convergence -- a single flag is a note, multiple converging indicators are an investigation trigger. It distinguishes soft fraud from hard fraud. And critically, it is a flag-and-escalate function, not detect-and-deny. The Fraud Analyst never denies a claim."

*[2:42]*

> "The Senior Reviewer is the only decision authority. It weighs all prior evidence, checks FCSP timeline compliance, and assesses bad faith risk. It has four outcomes: approve, deny, conditional approval, or escalate to a human when the AI cannot make a confident decision."

*[2:53]*

> "Finance calculates the final payment -- estimate minus deductible minus depreciation -- and identifies subrogation candidates. If the other party was at fault and insured, we flag recovery."

*[3:00]*

---

## Section 4: Live Demo (3:00 - 4:30)

**[ACTION] Switch to terminal**

> "Let me show you this in action. I am going to submit a real collision claim and we will watch the entire pipeline process it live."

*[3:06]*

**[ACTION] Run: `./scripts/run-demo.sh happy-path`**

> "This is John Smith, policy holder on POL-AUT-10001. He was driving northbound through an intersection with a green light when Maria Rodriguez ran a red light in her Ford Explorer and struck his Honda Accord on the front-right corner. A witness confirmed the other party was at fault. A police report was filed."

*[3:20]*

> "Watch the terminal. The Front Desk is categorizing this as a collision claim, normal priority. No catastrophe event. No missing information."

*[3:28]*

> "Now the Claims Officer is verifying coverage. Policy is active. Coverage type: collision. Deductible: 500 dollars. No exclusions apply."

*[3:36]*

> "The Assessor is estimating damage. Front-right fender, headlight assembly, bumper cover, hood buckling. The estimate comes in around 4,200 dollars. Not a total loss. OEM recommended for the headlight assembly since the vehicle is under three years old. Aftermarket acceptable for the bumper cover. And notice -- it flags hidden damage as likely in the wheel well area."

*[3:52]*

> "Fraud Analyst is running. This is a straightforward claim -- independent witness, police report confirming other-party fault, consistent damage pattern. Risk score: low. No fraud flags. Recommendation: proceed."

*[4:04]*

> "Senior Reviewer: approved. Straightforward collision, low fraud risk, within coverage limits, within all FCSP deadlines."

*[4:12]*

> "And Finance calculates the payment: 4,200 dollar estimate minus the 500 dollar deductible equals 3,700 dollars. And here is the business value -- it flags subrogation against State Farm, Maria Rodriguez's insurer. We are going to recover our costs."

*[4:24]*

**[ACTION] Run: `./scripts/check-status.sh CLM-2026-00001` (or use the claim ID from the demo output)**

> "Look at this audit log. Every decision. Every agent. Every reasoning step documented. This is what regulators want to see. This is what protects the insurer from bad faith claims."

*[4:30]*

### [IF DEMO FAILS] Fallback Instructions

If the live demo encounters an error at any point, switch immediately to the walkthrough narrative:

1. **[ACTION]** Say: "Let me show you the expected output instead."
2. **[ACTION]** Open `docs/demo-walkthroughs.md` and read from **Walkthrough 1: Happy Path Collision**.
3. Narrate each agent's expected output as documented in the walkthrough.
4. If backup captures exist (from 04-04 plan), **[ACTION]** display the pre-captured terminal output file.
5. Continue the presentation from Section 5 as normal -- the audience sees the same data points either way.

**Key recovery lines:**
- "The system processed this claim through all six agents. Here is what each one found..."
- "The audit trail documents every decision and reasoning step..."
- Resume with the audit log emphasis and transition to Section 5.

---

## Section 5: Secret Addition & Close (4:30 - 5:00)

**[ACTION] Slide 4: Adaptability slide (or return to architecture slide)**

> "When the secret addition was announced, we adapted by editing agent instructions -- not code. This is the power of reasoning-framework-based agents. New business requirements become new knowledge, not new engineering."

*[4:42]*

> "We updated the relevant AGENTS.md files with the new context. The next claim processed used the updated instructions immediately. No redeployment. No code changes. Just updated reasoning frameworks."

*[4:52]*

> "Six agents. One pipeline. Complete audit trail. Regulatory compliance by design. That is Ohio Mutual Auto."

*[5:00]*

**[ACTION] Return to title slide. Open for questions.**

---

## Presenter Notes

### Timing Calibration

| Section | Start | End | Duration |
|---------|-------|-----|----------|
| 1. Problem Setup | 0:00 | 0:30 | 30 seconds |
| 2. Architecture Overview | 0:30 | 1:30 | 60 seconds |
| 3. Business Logic Deep Dive | 1:30 | 3:00 | 90 seconds |
| 4. Live Demo | 3:00 | 4:30 | 90 seconds |
| 5. Secret Addition & Close | 4:30 | 5:00 | 30 seconds |

### Pacing Tips

- Section 1 is the hook. Speak with urgency about the problem.
- Section 2 should be brisk and visual. Point at the diagram. Name-drop OpenClaw primitives: sessions_spawn, tool scoping, agent isolation, AGENTS.md.
- Section 3 is the differentiator. This is where judges see domain expertise. Slow down slightly for the fraud patterns and ambiguity doctrine.
- Section 4 is the proof. Let the terminal output speak. Fill silence with narration from the walkthrough script.
- Section 5 is the close. Speak with confidence. The last sentence should be delivered slowly and clearly.

### If You Are Running Behind

- **At 1:30 and not in Section 3 yet:** Trim the architecture overview. Skip tool scoping detail.
- **At 3:00 and not in Section 4 yet:** Trim the business logic section. Hit only Front Desk, Fraud Analyst, and Senior Reviewer. Skip Assessor and Finance detail.
- **At 4:30 and not in Section 5 yet:** Cut the audit log display. Go directly to the closing line.

### Key Phrases for Q&A Setup

- "Reasoning frameworks, not hardcoded rules"
- "Complete audit trail for regulatory compliance"
- "Least-privilege tool scoping"
- "Coverage denial shortcut -- no wasted processing"
- "Indicator convergence, not probability of fraud"

---

*Presentation script for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
*Total runtime: 5 minutes*
