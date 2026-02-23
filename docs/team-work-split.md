# Team Work Split -- Parallel Workstream Design

Three parallel workstreams for 3 team members. Each workstream has zero blocking dependencies on the others during build hours (10:30-15:00). Integration happens at checkpoints (Hour 3 and Hour 5) and during the integration window (15:30-17:00).

**See also:** [day-of-timeline.md](day-of-timeline.md) for hour-by-hour schedule, [integration-checkpoints.md](integration-checkpoints.md) for checkpoint protocol.

---

## Workstream A: Router + Infrastructure (Member A)

**Role:** Orchestration layer owner. Member A owns the Router agent and all infrastructure that makes the pipeline work. They are the integration lead -- testing that Router can spawn each agent as others complete them.

### Agents Owned
- **Router** (workspaces/router/AGENTS.md)

### Deliverables (in order)

**1. Router AGENTS.md (10:30-11:30)**
- File: `workspaces/router/AGENTS.md`
- Content: Role identity, state machine definition (9 states, complete transition table), sequential spawn protocol (announce-wait-read-spawn cycle), task message construction templates for all 6 stages, error handling and retry policy (max 2 retries, per-stage timeouts), escalation handling protocol, audit logging requirements, regulatory context injection templates
- Test: Verify gateway accepts the AGENTS.md (no syntax errors, agent loads)
- Size estimate: ~250 lines (largest AGENTS.md -- it contains the orchestration logic)

**2. Infrastructure Deployment (9:00-10:00, parallel with setup)**
- VPS provisioning via `setup.sh`
- `openclaw.json` deployment and verification
- Shared directory structure creation (`shared/state/claims/`, `shared/policies/`, `shared/schemas/`, `shared/uploads/`, `shared/test-claims/`)
- Policy JSON files deployment (5 files to `shared/policies/`)
- Claim schema deployment (`claim.schema.json` to `shared/schemas/`)
- Test claim files deployment (3 files to `shared/test-claims/`)
- Script permissions (`chmod +x scripts/*.sh`)

**3. Integration Testing (11:30 onward, continuous)**
- Test Router spawns Front Desk (first integration point)
- Test Router spawns Claims Officer (second integration point)
- Test Router spawns Assessor, Fraud Analyst, Senior Reviewer, Finance (as Member C completes them)
- Debug spawn failures: check `openclaw.json` agentDir paths, verify agent IDs match, check tool permissions
- Run full pipeline tests when all agents are ready

### How to Signal "Ready for Integration"
- Member A does not need to signal -- they ARE the integration point
- Member A pulls agents into integration as they are completed by B and C

### Integration Role During Checkpoints
- Member A leads both Integration Checkpoint 1 (Hour 3) and Checkpoint 2 (Hour 5)
- Runs `submit-claim.sh`, `check-status.sh`, `run-demo.sh`
- Diagnoses which agent failed and coordinates fix with the owning member

---

## Workstream B: Front Desk + Claims Officer + Policies (Member B)

**Role:** Intake and coverage pipeline owner. Member B owns the first two pipeline stages plus policy data. These agents are grouped because Claims Officer depends on Front Desk output and both need policy data.

### Agents Owned
- **Front Desk** (workspaces/front-desk/AGENTS.md)
- **Claims Officer** (workspaces/claims-officer/AGENTS.md)

### Deliverables (in order)

**1. Front Desk AGENTS.md (10:30-11:00)**
- File: `workspaces/front-desk/AGENTS.md`
- Content: Role identity (professional intake coordinator), FNOL processing checklist, claim categorization criteria (standard/complex/CAT/multi-vehicle), priority assignment framework (severity, injuries, time sensitivity), completeness assessment (required vs optional fields), domain knowledge from Phase 1 (FNOL lifecycle embedded), output format (pipeline.front_desk fields), announce protocol (SUCCESS/ERROR format)
- Test: Read the AGENTS.md aloud -- zero numerical if/then thresholds
- Size estimate: ~120 lines

**2. Claims Officer AGENTS.md (11:00-11:30)**
- File: `workspaces/claims-officer/AGENTS.md`
- Content: Role identity (meticulous coverage analyst), policy lookup protocol (how to read policy JSON), coverage verification framework (matching incident to coverage type), exclusion analysis checklist (excluded drivers, lapsed policies, coverage gaps), denial documentation requirements (FCSP compliance), UM/UIM routing logic, domain knowledge from Phase 1 (coverage verification embedded), output format (pipeline.claims_officer fields), announce protocol
- Test: Verify against policy files -- does the AGENTS.md reference the correct policy JSON structure?
- Size estimate: ~140 lines

**3. Policy Data Verification (9:15-9:30 during setup, and 11:30-12:00)**
- Verify all 5 policy files are valid JSON and match the schema expectations
- Verify Claims Officer AGENTS.md references correct policy field names
- Test Claims Officer with at least 2 policies: active (POL-AUT-10001) and excluded driver (POL-AUT-10003)

**4. Signal Ready for Integration (11:30)**
- Tell Member A: "Front Desk AGENTS.md deployed and ready to test"
- Provide quick summary of expected output format so Member A knows what to validate

### Order of Operations
1. Front Desk first (it is Stage 1 -- earliest integration point)
2. Claims Officer second (depends on Front Desk output format being settled)
3. Policy verification third (can happen while Claims Officer is being typed)

### What to Test After Each Agent Is Ready
- **Front Desk:** Submit a test claim. Check pipeline.front_desk section has: category, priority, missing_info, completed_at. Check audit_log has an entry from front-desk.
- **Claims Officer:** After Front Desk runs, check pipeline.claims_officer section has: covered, deductible_amount, coverage_limit, exclusions_checked, denial_reason (if applicable), completed_at. Verify policy file was read correctly.

### Secret Addition Responsibility
- If secret addition affects intake (new claim fields, new categories): update Front Desk AGENTS.md
- If secret addition affects coverage (new exclusions, new coverage types): update Claims Officer AGENTS.md
- Implement during secret addition integration window (15:30-16:30)

---

## Workstream C: Assessor + Fraud Analyst + Senior Reviewer + Finance (Member C)

**Role:** Analysis and decision pipeline owner. Member C owns the remaining 4 pipeline stages. Senior Reviewer and Finance are simpler agents (shorter AGENTS.md, more structured logic) and are scheduled after the complex Assessor and Fraud Analyst.

### Agents Owned
- **Assessor** (workspaces/assessor/AGENTS.md)
- **Fraud Analyst** (workspaces/fraud-analyst/AGENTS.md)
- **Senior Reviewer** (workspaces/senior-reviewer/AGENTS.md)
- **Finance** (workspaces/finance/AGENTS.md)

### Deliverables (in order)

**1. Assessor AGENTS.md (10:30-11:30)**
- File: `workspaces/assessor/AGENTS.md`
- Content: Role identity (experienced damage appraiser), damage assessment methodology (systematic estimation), total loss determination framework (ACV comparison, Ohio 70-75% threshold as guideline), parts recommendation criteria (OEM vs aftermarket based on vehicle age/mileage/safety), pre-existing damage detection (indicators, cross-reference to fraud), photo analysis protocol (description-based reasoning, not ML), domain knowledge from Phase 1, output format (pipeline.assessor fields), announce protocol
- Test: Verify output format matches what Fraud Analyst expects to read (pre_existing_damage_flags)
- Size estimate: ~150 lines

**2. Fraud Analyst AGENTS.md (11:30-12:30)**
- File: `workspaces/fraud-analyst/AGENTS.md`
- Content: Role identity (skeptical investigator), fraud pattern catalog (staged accidents, phantom passengers, inflated repairs, prior damage, VIN switching, policy stacking, claim timing), indicator convergence framework (single flag = note, converging = investigate, pattern match = refer SIU), risk scoring methodology (0-100 convergence-based), soft vs hard fraud distinction, SIU referral criteria, cross-reference analysis (reads assessor.pre_existing_damage_flags), pattern interaction map, domain knowledge from Phase 1, output format, announce protocol
- Test: Verify all 7 fraud patterns are documented with full indicator lists
- Size estimate: ~180 lines (largest pipeline agent AGENTS.md)

**3. Senior Reviewer AGENTS.md (12:00-13:00)**
- File: `workspaces/senior-reviewer/AGENTS.md`
- Content: Role identity (authoritative decision-maker), evidence weighing framework (coverage + assessment + fraud signals), decision criteria (4 outcomes: APPROVED/DENIED/CONDITIONAL/ESCALATE_HUMAN), FCSP timeline compliance check (calculate deadlines from submitted_at), bad faith risk assessment (when denial triggers liability), escalation judgment (when AI should defer to human), domain knowledge from Phase 1, output format, announce protocol
- Test: Verify decision criteria cover all possible pipeline states
- Size estimate: ~130 lines

**4. Finance AGENTS.md (13:30-14:00)**
- File: `workspaces/finance/AGENTS.md`
- Content: Role identity (precise financial processor), payment calculation (estimate - deductible - depreciation, capped at coverage limit), deductible application rules, depreciation methodology, subrogation assessment (when to flag for recovery), payment method selection, HARD CONSTRAINT: never pay without Senior Reviewer approval, domain knowledge from Phase 1, output format, announce protocol
- Test: Verify payment formula logic, verify the hard constraint is explicit
- Size estimate: ~100 lines (simplest pipeline agent)

### Order of Operations
1. Assessor first (Stage 3 -- needed early for integration testing)
2. Fraud Analyst second (Stage 4 -- complex, needs full build time)
3. Senior Reviewer third (Stage 5 -- can overlap with Fraud Analyst if typing fast)
4. Finance last (Stage 6 -- shortest, most structured)

### Why 4 Agents for One Member
- Senior Reviewer AGENTS.md is shorter than Assessor or Fraud Analyst (~130 vs ~180 lines)
- Finance is the simplest agent (~100 lines) with mostly structured calculation logic
- Finance uses Sonnet (simpler model assignment, less nuanced AGENTS.md needed)
- Member A has only 1 agent to type but carries the integration testing load
- Member B has 2 agents plus policy data verification
- Member C has 4 agents but 2 of them are significantly simpler

### What to Test After Each Agent Is Ready
- **Assessor:** After Claims Officer runs, check pipeline.assessor section has: repair_estimate_usd, total_loss, parts_recommendation, labor_hours_estimate, completed_at. Check pre_existing_damage_flags if applicable.
- **Fraud Analyst:** After Assessor runs, check pipeline.fraud_analyst section has: risk_score, risk_level, flags (array), recommendation, completed_at. Verify flags reference specific evidence from prior stages.
- **Senior Reviewer:** After Fraud Analyst runs, check pipeline.senior_reviewer section has: decision, decision_reasoning, conditions (if CONDITIONAL), escalated_to_human (if ESCALATE_HUMAN), fcsp_timeline_check, completed_at.
- **Finance:** After Senior Reviewer APPROVED, check pipeline.finance section has: payment_amount_usd, deductible_applied_usd, subrogation_candidate, payment_reference, completed_at. Verify payment = estimate - deductible (capped at limit).

### How to Signal "Ready for Integration"
- After Assessor complete (11:30): Tell Member A "Assessor ready"
- After Fraud Analyst complete (12:30): Tell Member A "Fraud Analyst ready"
- After Senior Reviewer complete (13:00): Tell Member A "Senior Reviewer ready"
- After Finance complete (14:00): Tell Member A "All 4 agents ready -- full pipeline possible"

### Secret Addition Responsibility
- If secret addition affects damage assessment (new damage types, valuation changes): update Assessor AGENTS.md
- If secret addition affects fraud (new patterns, new red flags): update Fraud Analyst AGENTS.md
- If secret addition affects decisions (new approval conditions, new escalation triggers): update Senior Reviewer AGENTS.md
- If secret addition affects payment (new calculation rules, new payment methods): update Finance AGENTS.md
- Implement during secret addition integration window (15:30-16:30)

---

## Cross-Workstream Dependencies

| Dependency | From | To | When Resolved |
|-----------|------|-----|---------------|
| Router spawns Front Desk | A needs B's Front Desk | Integration test | 11:30 (Checkpoint 1 prep) |
| Router spawns Claims Officer | A needs B's Claims Officer | Integration test | 12:00 |
| Router spawns Assessor | A needs C's Assessor | Integration test | 12:30 |
| Router spawns Fraud Analyst | A needs C's Fraud Analyst | Integration test | 13:30 |
| Router spawns Senior Reviewer | A needs C's Senior Reviewer | Integration test | 14:00 |
| Router spawns Finance | A needs C's Finance | Integration test | 14:30 |
| Fraud reads Assessor output | C's Fraud Analyst reads C's Assessor output | Same member | N/A (same workstream) |
| Claims Officer reads policy | B's Claims Officer reads policy files | B deploys both | N/A (same workstream) |

**Key insight:** No workstream blocks another during build hours. Member B and C type AGENTS.md independently. Member A integrates agents as they become available. The only synchronization points are the two integration checkpoints.

---

## Workload Balance

| Member | Agents | Est. Lines | Build Time | Other Duties |
|--------|--------|------------|------------|-------------|
| A | 1 (Router) | ~250 | 10:30-11:30 | Integration testing (11:30-15:00), demo prep lead |
| B | 2 (Front Desk, Claims Officer) | ~260 | 10:30-11:30 | Policy verification, integration support |
| C | 4 (Assessor, Fraud, SR, Finance) | ~560 | 10:30-14:00 | Integration support after 14:00 |

Member C has the highest AGENTS.md typing volume but the lowest integration testing burden. Member A has the lowest typing volume but the highest integration/debugging burden. Member B is balanced.

---

*Team work split for: Ohio Mutual Auto -- Multi-Agent Claims Processing System*
*OpenClaw Business Engineering Hackathon, Feb 21, 2026*
