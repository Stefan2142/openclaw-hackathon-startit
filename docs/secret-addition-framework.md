# Secret Addition Adaptation Framework

A playbook for incorporating the unknown "secret addition" revealed on hackathon morning. Every adaptation works by editing AGENTS.md files and configuration -- no code changes required. The team can adapt in 30 minutes or less regardless of what the secret addition is.

---

## 1. Adaptation Philosophy

The system is designed for AGENTS.md-first modification. Because all agent behavior is defined in reasoning frameworks (not hardcoded rules), adapting to new requirements means editing the operating instructions, not rewriting code. The Router's AGENTS.md controls pipeline flow, and each agent's AGENTS.md controls its decision-making.

Key architectural properties that enable rapid adaptation:

- **Sequential pipeline controlled by Router AGENTS.md** -- Add, remove, or reorder stages by editing the Router's state machine and spawn sequence. No code orchestration to modify.
- **Reasoning frameworks in each agent** -- Add new considerations, regulations, or business rules by appending to an agent's domain knowledge section. The agent reasons from these instructions naturally.
- **JSON claim schema** -- Add new fields by editing `shared/schemas/claim.schema.json` and updating the relevant agent's AGENTS.md output format section. No database migrations, no API changes.
- **openclaw.json agent registration** -- Add new agents by registering them in the `agents.list` array. The Router's `allowAgents` list controls who can be spawned. No code deployment required.

**Why this works:** Sub-agents (depth-1) receive only `AGENTS.md` + `TOOLS.md` injected into their context. Changing AGENTS.md changes agent behavior immediately on the next spawn. No restart, no rebuild, no redeploy.

---

## 2. Adaptation Decision Tree

When the secret addition is revealed, follow this process:

```
1. Read the requirement carefully
2. Classify it:
   |
   +-- (a) Does it require a NEW AGENT ROLE?
   |       (e.g., "add a medical reviewer", "add a customer notifier")
   |       --> Scenario A (30 min)
   |
   +-- (b) Does it add NEW KNOWLEDGE to existing agents?
   |       (e.g., "new regulation", "new business rule", "new coverage type")
   |       --> Scenario B (15 min)
   |
   +-- (c) Does it change CLAIM VOLUME or event handling?
   |       (e.g., "tornado hit Columbus", "process 10 claims", "batch submission")
   |       --> Scenario C (20 min)
   |
   +-- (d) Does it combine elements of A, B, and/or C?
           --> Scenario D: Hybrid (30 min)
           Decompose into atomic changes, apply matching scenarios

3. If none match exactly, combine elements from multiple scenarios
4. Time-box: 30 min max. If not done, implement simplest version first
```

**Quick classification test:** Ask "Does this change what agents exist, what agents know, or how many claims come in?" The answer maps directly to Scenario A, B, or C.

---

## 3. Scenario A: New Agent Role

**Example triggers:** "Add a Medical Reviewer agent for injury claims" or "Add a Customer Communication agent" or "Add a Compliance Auditor that checks every claim"

**Estimated time: 30 minutes**

### Steps

**Step 1: Create new workspace directory (2 min)**

```
workspaces/{new-agent-id}/
  AGENTS.md     <-- operating instructions (see step 2)
```

No SOUL.md -- sub-agents only receive AGENTS.md + TOOLS.md.

**Step 2: Write AGENTS.md for new agent (15 min)**

Follow the established 8-section pattern used by all pipeline agents:

1. **Role and Identity** -- Who this agent is, personality, expertise level
2. **Protocol** -- Step-by-step processing instructions (read claim, analyze, write output, append audit log, announce)
3. **Domain Knowledge** -- Embedded expertise relevant to this agent's function
4. **Decision Framework** -- How this agent makes its specific judgments
5. **Output Format** -- Exact fields to write to `pipeline.{new_agent_id}` section
6. **Escalation Criteria** -- When to announce ESCALATE instead of SUCCESS
7. **Audit Log Requirements** -- What to log and at what detail level
8. **Announce Protocol** -- Format for SUCCESS/ERROR/ESCALATE announce messages

**Step 3: Register agent in openclaw.json (3 min)**

Add entry to `agents.list`:

```json
{
  "id": "{new-agent-id}",
  "name": "{Display Name}",
  "workspace": "./workspaces/{new-agent-id}",
  "model": "anthropic/claude-opus-4-6",
  "tools": {
    "allow": ["read", "write"],
    "deny": ["exec", "browser", "gateway", "cron", "sessions_spawn"]
  }
}
```

Model assignment guidance:
- **Opus** if the agent requires complex reasoning, professional judgment, or pattern analysis
- **Sonnet** if the agent performs structured extraction, rule-based matching, or deterministic tasks

Add the new agent ID to the Router's `allowAgents` list:

```json
"allowAgents": ["front-desk", "claims-officer", "assessor", "fraud-analyst", "senior-reviewer", "finance", "{new-agent-id}"]
```

**Step 4: Update Router AGENTS.md (8 min)**

Edit `workspaces/router/AGENTS.md` to add the new stage:

1. **State machine section:** Add new status transition(s) if needed, or insert agent into existing flow
2. **Spawn sequence section:** Add the new stage at the correct position in the pipeline (after which existing stage? before which?)
3. **Task message template:** Write the task message the Router will use when spawning this agent (claim file path, context injection, regulatory context)
4. **Validation section:** Define what Router checks after new agent announces (required output fields, well-formed data)
5. **Error handling:** Add per-stage timeout (60-120s depending on complexity)

**Step 5: Update claim.schema.json (2 min)**

Add a `pipeline.{new_agent_id}` section to `shared/schemas/claim.schema.json` with the output fields defined in Step 2.

**Step 6: Test (remaining time)**

Submit a test claim and verify:
- Router spawns new agent at the correct pipeline position
- New agent reads claim, writes its pipeline section, appends audit log
- New agent announces SUCCESS/ERROR/ESCALATE
- Router validates output and proceeds to next stage

### Team Division

| Member | Responsibility |
|--------|---------------|
| Member A | Register in openclaw.json (Step 3), update Router AGENTS.md pipeline sequence (Step 4) |
| Member B or C (lighter load) | Create workspace + write the new agent's AGENTS.md (Steps 1-2) |
| All | Test integration at next checkpoint (Step 6) |

---

## 4. Scenario B: New Regulation or Business Rule

**Example triggers:** "Ohio just passed a law requiring 24-hour claim acknowledgment" or "Add diminished value calculation to every collision claim" or "Claims over $50K need dual approval"

**Estimated time: 15 minutes**

### Steps

**Step 1: Identify which agent(s) need the new knowledge (2 min)**

Use this mapping:

| Regulation/Rule Type | Primary Agent(s) to Modify |
|---------------------|---------------------------|
| Timeline/deadline changes | Router AGENTS.md (FCSP context injection) + Senior Reviewer AGENTS.md (timeline compliance check) |
| Coverage rule changes | Claims Officer AGENTS.md (coverage verification framework) |
| New coverage type | Claims Officer AGENTS.md + claim.schema.json (new coverage fields) |
| Damage/assessment rule changes | Assessor AGENTS.md (estimation methodology) |
| Fraud threshold changes | Fraud Analyst AGENTS.md (indicator patterns) |
| Payment rule changes | Finance AGENTS.md (payout calculation) |
| Escalation rule changes | Router AGENTS.md + Senior Reviewer AGENTS.md |
| Intake/triage changes | Front Desk AGENTS.md (categorization, priority framework) |
| Dual approval / authority changes | Senior Reviewer AGENTS.md (decision criteria) + Router AGENTS.md (validation logic) |
| Disclosure requirements | Senior Reviewer AGENTS.md (decision documentation) + Finance AGENTS.md (payment documentation) |

**Step 2: Add regulation/rule to the relevant AGENTS.md (5 min)**

Edit the **Domain Knowledge** section of the identified agent(s). Add the new rule as a reasoning principle:

```markdown
### [New Regulation Name]

**Requirement:** [What the regulation requires]
**When it applies:** [Conditions under which this rule activates]
**How to comply:** [Step-by-step compliance reasoning]
**Audit documentation:** [What to record for regulatory proof]
```

**Step 3: Update decision framework if needed (3 min)**

If the new rule changes HOW the agent makes decisions (not just what it knows):
- Add to the **Decision Framework** section of the relevant agent's AGENTS.md
- Frame as a reasoning principle, not a hardcoded threshold
- Example: "When the claim filing date is more than [deadline] from the current date, note timeline urgency in your analysis" -- not "if days > 24, flag=true"

**Step 4: Add new output fields if needed (3 min)**

If the regulation requires tracking new information:
1. Add field to `shared/schemas/claim.schema.json` in the relevant pipeline section
2. Update the agent's AGENTS.md **Output Format** section to include the new field
3. Update Router's validation for that stage to check the new field

**Step 5: Update escalation triggers if needed (2 min)**

If the new rule creates new conditions for human escalation:
- Add escalation criterion to the relevant agent's AGENTS.md **Escalation Criteria** section
- Add matching trigger handling in Router AGENTS.md escalation section

**Step 6: Test**

Run a claim that exercises the new rule. Verify the agent applies the new knowledge in its audit log reasoning.

### Team Division

| Member | Responsibility |
|--------|---------------|
| Member A | Update Router AGENTS.md if pipeline flow changes |
| Member B or C | Update the target agent's AGENTS.md domain knowledge and decision framework |
| All | Review audit log output to verify new rule is applied |

---

## 5. Scenario C: Claim Volume Surge (CAT Event)

**Example triggers:** "A tornado just hit Columbus -- process 10 claims instead of 3" or "Handle a multi-vehicle pileup as a single event" or "Simulate a catastrophe response"

**Estimated time: 20 minutes**

### Steps

**Step 1: Update Router AGENTS.md for CAT event awareness (5 min)**

Add to Router's domain knowledge:
- When a claim has `cat_event` field set, tag all related claims with the same event ID for cross-reference
- If multiple related claims: process sequentially but note related claim IDs in each claim's audit log
- Optional: prioritize CAT event claims over non-CAT claims in processing order

**Step 2: Update Front Desk AGENTS.md for CAT event tagging (3 min)**

The claim schema already has a `cat_event` field. Update Front Desk AGENTS.md:
- Add CAT event identification to the **Categorization** section (weather keywords, multi-vehicle indicators, geographic clustering)
- Update **Priority Assignment** framework: CAT event claims default to "high" or "urgent" priority
- Set `cat_event` field with event identifier (e.g., "CAT-2026-TORNADO-COLUMBUS")

**Step 3: Create additional test claim JSON files (10 min)**

Copy existing test claims from `shared/test-claims/` and modify:
1. Copy `happy-path-collision.json` as template
2. Change claimant details, incident details, and dates to match CAT event scenario
3. Add `cat_event` field with matching event ID across all related claims
4. Create 3-5 additional claims varying in severity (minor, moderate, severe, total loss)
5. Ensure different policy IDs are used (POL-AUT-10001 through POL-AUT-10005)

**Step 4: If priority triage needed (2 min)**

Update Front Desk AGENTS.md priority assignment to factor in CAT event urgency:
- Injuries during CAT event = "urgent" (always)
- Total loss indicators during CAT event = "high"
- Standard damage during CAT event = "normal" (standard processing, but tagged for cross-reference)

**Step 5: Update demo script for batch submission**

Modify `scripts/run-demo.sh` or create a new `scripts/run-cat-demo.sh` that submits multiple claims sequentially and shows the pipeline processing each one.

**Step 6: Test**

Submit 2-3 CAT event claims. Verify:
- Front Desk tags each with matching `cat_event` identifier
- Router processes them sequentially (by design -- one claim at a time)
- Audit logs cross-reference related claim IDs

### Key Insight

**No structural changes needed.** The pipeline handles one claim at a time by design. Multiple claims = multiple sequential pipeline runs. CAT event handling is a metadata tag and priority adjustment, not a pipeline architecture change. This is a strength of the sequential design.

### Team Division

| Member | Responsibility |
|--------|---------------|
| Member A | Update Router + Front Desk AGENTS.md (Steps 1-2, 4) |
| Member B or C | Create additional test claim JSON files (Step 3) |
| All | Run batch demo and verify cross-referencing (Steps 5-6) |

---

## 6. Scenario D: Hybrid / Unexpected

If the secret addition does not fit neatly into A, B, or C:

### Decomposition Process

1. **Break it down into atomic changes:**
   - "This requires a new field AND a new decision criterion AND maybe a new agent"
   - List each atomic change separately

2. **Map each atomic change to a scenario:**
   - New field? -> Scenario B Step 4 (schema + output format)
   - New decision logic? -> Scenario B Step 3 (decision framework)
   - New agent? -> Scenario A (full new agent flow)
   - More claims? -> Scenario C (test data + CAT tagging)

3. **Prioritize by minimum viable demonstration:**
   - What is the MINIMUM change that demonstrates compliance with the secret addition?
   - Implement that first
   - Add depth only if time permits

4. **Time-box strictly:**
   - Spend maximum 30 minutes on adaptation
   - If not complete at 30 min: implement the simplest working version
   - Mention the full vision in the presentation ("Given more time, we would also...")

### Common Hybrid Patterns

| Secret Addition Pattern | Decomposition |
|------------------------|---------------|
| "Add X and also change Y" | Scenario B (Y) first, then A or B (X) |
| "New agent that uses new data" | Scenario A (agent) + B (data fields) |
| "Handle a scenario with different rules" | Scenario B (rules) + C if volume-related |
| "Integrate with external system" | Scenario B (mock the integration as domain knowledge, add fields for mock data) |
| "Add audit/compliance requirement" | Scenario B (add to Senior Reviewer + Router) |

---

## 7. What NOT to Change

These are architectural invariants. Changing them risks breaking the pipeline and wastes time debugging.

| Do NOT | Reason |
|--------|--------|
| Restructure the pipeline (sequential is proven) | Parallel execution introduces race conditions on the shared claim JSON. Sequential is a correctness choice, not a performance limitation. |
| Change the claim JSON format fundamentally | Add fields -- do not rename or remove existing ones. Every agent reads/writes specific field names. |
| Add new tools to agents unless absolutely necessary | Least-privilege principle. If a new agent needs only read+write, give it only read+write. |
| Attempt real external API calls | Mock everything. The demo shows reasoning quality, not integration engineering. |
| Change model assignments without reason | Opus/Sonnet split is deliberate (complex reasoning vs. structured tasks). |
| Modify `maxSpawnDepth` | Currently 1 (Router=depth-0, pipeline=depth-1). Changing this breaks the flat pipeline model. |
| Remove `agentToAgent: false` | All communication flows through claim JSON + Router mediation. Direct agent-to-agent would bypass audit trail. |
| Panic | The architecture was designed for this. AGENTS.md-first means every adaptation is a text edit, not a code change. |

---

## 8. Presentation Framing

Regardless of what the secret addition is, frame the adaptation in the presentation using this narrative:

### The Key Message

> "When the secret addition was revealed, we adapted our system by modifying agent operating instructions -- not code. This demonstrates the key advantage of reasoning-framework-based agents: new business requirements become new knowledge, not new engineering."

### Talking Points

1. **Architecture designed for change:** "Our agents operate on reasoning frameworks defined in AGENTS.md files. When the secret addition required [specific change], we edited the relevant agent's instructions. The agent immediately applied the new knowledge on the next claim."

2. **No code changes needed:** "We did not write new code, deploy new services, or change our pipeline. We edited text files containing agent operating instructions. This is the power of instruction-driven AI agents."

3. **Time to adapt:** "From hearing the secret addition to having it working: [actual time]. This speed comes from the architecture, not from heroic engineering."

4. **Audit trail proves compliance:** "Look at the audit log -- you can see the agent reasoning about the new requirement in its own words. Every decision is documented, every regulation referenced."

### If Asked "What If the Secret Addition Were X Instead?"

This question tests adaptability. The correct answer references the framework:

> "We have a classification system for changes. If it requires a new agent role, we create a workspace and register it. If it adds new knowledge, we update the relevant agent's instructions. If it changes volume, we adjust metadata and test data. The architecture handles all three categories through the same AGENTS.md-first mechanism."

### Slide/Demo Integration

If presenting the adaptation process:
1. Show the `git diff` of what changed (should be AGENTS.md files and/or openclaw.json)
2. Show the audit log output proving the agent applies the new knowledge
3. Contrast with traditional approach: "In a hardcoded system, this would require code changes, testing, deployment. Here, it is a text edit."

---

*Secret Addition Adaptation Framework*
*Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
