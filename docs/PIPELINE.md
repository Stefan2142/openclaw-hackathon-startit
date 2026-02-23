# Ohio Mutual Claims Pipeline

## Pipeline Flow

```
User (Telegram)
    |
    v
[Router] ── FNOL intake + orchestration
    |
    v
[Claims Officer] ── coverage verification
    |
    v
[Assessor] ── damage estimation (financial data stripped)
    |
    v
[Fraud Analyst] ── pattern detection + risk scoring
    |
    v
[Senior Reviewer] ── decision authority
    |
    v
[Finance] ── payment calculation + disbursement
    |
    v
User (Telegram) ── outcome notification
```

## Status Transitions

```
                          (from any stage)
                         +-> ESCALATED
                         |
                         +-> ERROR
                         |
FNOL_RECEIVED --> COVERAGE_CHECKED --> ASSESSED --> FRAUD_ANALYZED --> REVIEWED --> PAYMENT_ISSUED
                       |                                                  |
                       +-> DENIED                                         +-> DENIED
```

---

## Agent Descriptions

### 1. Router (Orchestrator)

**Uloga:** Prima sve korisnicke poruke preko Telegrama. Obavlja FNOL intake (kategorizacija, prioritizacija, provera kompletnosti). Kreira claim u bazi. Poziva agente sekvencijalno, validira output svakog pre nego sto pozove sledeceg.

- **Input:** Telegram poruka (tekst + fotografije)
- **Output:** Kreiran claim u bazi, pozvani pipeline agenti
- **Stop condition:** Pipeline zavrsen (PAYMENT_ISSUED, DENIED, ESCALATED, ERROR)

### 2. Claims Officer (Coverage Verification)

**Uloga:** Proverava da li polisa pokriva prijavljeni incident. Cita polisu iz /shared/policies/, proverava da je aktivna na dan incidenta, odredjuje tip pokrica, proverava sve exclusion-e.

- **Input:** claim_id, policy file path
- **Output:** covered (true/false), deductible, coverage_limit, exclusions_checked, denial_reason
- **Stop condition:** Coverage determination complete

### 3. Assessor (Damage Estimation)

**Uloga:** Procenjuje stetu na osnovu opisa i fotografija. Odredjuje repair vs total loss (Ohio 100% ACV pravilo), preporucuje OEM vs aftermarket delove, procenjuje rental dane, flaguje pre-existing damage i hidden damage.

- **Input:** claim_id via `get-claim-assessor` (financial fields stripped — separation of duties)
- **Output:** repair_estimate_usd, total_loss, acv_usd, parts_recommendation, rental_days, pre_existing_damage_flags, hidden_damage_likely
- **Stop condition:** Assessment complete
- **Key design:** Ne vidi deductible i coverage_limit — sprečava anchoring bias

### 4. Fraud Analyst (Pattern Detection)

**Uloga:** Analizira claim protiv 7 fraud pattern-a. Racuna risk score (0-100), odredjuje risk level, preporucuje akciju (CLEAR/INVESTIGATE/REFER_SIU). NE donosi odluku o denial-u — samo flaguje i preporucuje.

- **Input:** claim_id, user_id (za claim history)
- **Output:** risk_score, risk_level, flags[], recommendation
- **Stop condition:** Analysis complete

#### 7 Fraud Patterns

| # | Pattern | Opis | Key Indicators |
|---|---------|------|----------------|
| 1 | Staged Collision | Namerno izazvana nesreca | Low speed + high damage, suspicious location |
| 2 | Inflated Claim | Uvecana legitimna steta | Estimate >> incident description, pre-existing included |
| 3 | Paper Accident | Potpuno izmisljen incident | No police + no witnesses + no photos |
| 4 | Owner Give-Up | Vehicle disposal as theft | Financial distress + declining vehicle + convenient theft |
| 5 | Premium Fraud | Misrepresentation | Undisclosed drivers, garaged address fraud |
| 6 | Prior Damage Inclusion | Stara steta prijavljena kao nova | Pre-existing flags from Assessor, damage inconsistent with incident |
| 7 | Multiple Claim Pattern | Serijski claims | Frequency anomaly, similar patterns across claims |

#### Scoring Framework

- **0-25 (Low):** No significant indicators → CLEAR
- **26-50 (Medium):** Some indicators, insufficient convergence → CLEAR with notes
- **51-75 (High):** Multiple converging indicators → INVESTIGATE
- **76-100 (Critical):** Strong pattern match with known scheme → REFER_SIU

#### Pattern Combinations (High Risk)

- Paper Accident + Multiple Claims = organized fraud ring indicator
- Inflated Claim + Prior Damage = soft fraud escalation
- Staged Collision + Multiple Claims = professional staging operation

### 5. Senior Reviewer (Decision Authority)

**Uloga:** Jedini agent koji donosi konacnu odluku. Cita SVE prethodne pipeline stage-ove, proverava FCSP timeline compliance, donosi jednu od 4 odluke.

- **Input:** claim_id (full claim data)
- **Output:** decision, decision_reasoning, conditions[], fcsp_timeline_check
- **Stop condition:** Decision made

#### 4 Decisions

| Decision | Opis | Trigger |
|----------|------|---------|
| APPROVED | Sve proslo bez problema | Coverage OK + estimate reasonable + fraud low/CLEAR |
| DENIED | Claim odbijen | Coverage denied OR fraud evidence strong enough |
| CONDITIONAL | Odobreno uz uslove | Additional docs needed, pre-existing flagged, investigate |
| ESCALATE_HUMAN | Potreban ljudski pregled | 7 escalation triggers (below) |

#### 7 Escalation Triggers

1. **High Fraud Risk** — converging fraud indicators, REFER_SIU
2. **Significant Claim Value** — estimate unusually high for incident type
3. **Total Loss Determination** — ACV involves significant judgment
4. **Legal Representation** — attorney involvement noted
5. **Bad Faith Risk** — FCSP deadlines approaching/exceeded
6. **Coverage Ambiguity** — uncertain coverage determination
7. **Prior Fraud History** — claimant has prior fraud flags

### 6. Finance (Payment Processing)

**Uloga:** Racuna finalni iznos placanja. Primenjuje deductible, depreciaciju, coverage limit cap. Odredjuje subrogation potencijal. Kreira payment reference.

- **Input:** claim_id (full claim data including senior_reviewer decision)
- **Output:** payment_amount_usd, deductible_applied_usd, depreciation_applied_usd, subrogation info, payment_reference
- **Stop condition:** Payment issued

---

## Separation of Concerns

| Aspect | Who Handles It |
|--------|---------------|
| Coverage determination | Claims Officer |
| Damage estimation | Assessor (without financial context) |
| Fraud detection | Fraud Analyst (flags only, no denial power) |
| Final decision | Senior Reviewer (sole authority) |
| Payment calculation | Finance |
| Status transitions | Router (sole authority) |
| User communication | Router (sole channel) |

---

## Terminal States

| State | Meaning | Can Resume? |
|-------|---------|-------------|
| PAYMENT_ISSUED | Claim settled, payment sent | No (supplementals possible) |
| DENIED | Claim rejected with documented reason | No (appeal possible) |
| ESCALATED | Paused for human adjuster | Yes (after human resolution) |
| ERROR | Unrecoverable agent failure | Manual intervention required |

---

## Observability

All agents log structured traces to the `agent_traces` table:
- **START** — agent begins processing, includes input summary
- **STEP** — intermediate milestone with decision data
- **END** — agent completes, includes full output JSON
- **ERROR** — failure with context about what went wrong

Query traces: `bash /shared/scripts/db.sh get-traces <claim_id> [agent_name]`

---

## Data Segregation

The Assessor agent receives claim data via `get-claim-assessor` which strips:
- `pipeline.claims_officer.deductible_amount`
- `pipeline.claims_officer.coverage_limit`

This is enforced at the SQL level (PostgreSQL `#-` operator) to prevent anchoring bias. The Assessor's damage estimate must be based purely on the physical damage, not influenced by knowing what the policy will pay.

Finance is the only agent that sees both the damage estimate AND the financial limits to calculate the final payment.
