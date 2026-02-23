#!/bin/bash
# ============================================================
# Claim Report PDF Generator
# ============================================================
# Reads claim data from DB and generates a PDF report.
# Called by Router at pipeline completion (PAYMENT_ISSUED or DENIED).
#
# Usage: generate-report.sh <claim_id>
# Output: /shared/reports/<claim_id>.pdf (path printed to stdout)
# ============================================================

CLAIM_ID="$1"
if [ -z "$CLAIM_ID" ]; then
  echo "Usage: generate-report.sh <claim_id>" >&2
  exit 1
fi

DB_NAME="${OPENCLAW_DB_NAME:-openclaw_claims}"
DB_USER="${OPENCLAW_DB_USER:-openclaw}"
DB_HOST="${OPENCLAW_DB_HOST:-localhost}"
DB_PORT="${OPENCLAW_DB_PORT:-5432}"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -A"

REPORT_DIR="/shared/reports"
mkdir -p "$REPORT_DIR"

MD_FILE="$REPORT_DIR/${CLAIM_ID}.md"
PDF_FILE="$REPORT_DIR/${CLAIM_ID}.pdf"

# Read full claim JSON
CLAIM_JSON=$($PSQL -c "SELECT claim_data FROM claims WHERE claim_id = '$CLAIM_ID';")

if [ -z "$CLAIM_JSON" ]; then
  echo "Claim not found: $CLAIM_ID" >&2
  exit 1
fi

# Extract fields with python3
python3 -c "
import json, sys
from datetime import datetime

c = json.loads('''$CLAIM_JSON''')

status = c.get('status', 'UNKNOWN')
submitted = c.get('submitted_at', 'N/A')
claimant = c.get('claimant', {})
incident = c.get('incident', {})
pipeline = c.get('pipeline', {})
dd_list = pipeline.get('damage_detection', [])
co = pipeline.get('claims_officer', {}) or {}
assessor = pipeline.get('assessor', {}) or {}
fraud = pipeline.get('fraud_analyst', {}) or {}
sr = pipeline.get('senior_reviewer', {}) or {}
finance = pipeline.get('finance', {}) or {}

# Status display
status_display = status.replace('_', ' ')
if status == 'PAYMENT_ISSUED':
    status_label = 'APPROVED — PAYMENT ISSUED'
elif status == 'DENIED':
    status_label = 'DENIED'
elif status == 'ESCALATED':
    status_label = 'ESCALATED — PENDING HUMAN REVIEW'
else:
    status_label = status_display

today = datetime.utcnow().strftime('%Y-%m-%d')

md = []
md.append('# Ohio Mutual — Claim Report')
md.append('')
md.append(f'**Claim ID:** {c.get(\"claim_id\", \"N/A\")}  ')
md.append(f'**Date Filed:** {submitted[:10] if submitted != \"N/A\" else \"N/A\"}  ')
md.append(f'**Report Date:** {today}  ')
md.append(f'**Status:** {status_label}')
md.append('')
md.append('---')
md.append('')

# Claimant
md.append('## Claimant Information')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
md.append(f'| Name | {claimant.get(\"name\", \"N/A\")} |')
md.append(f'| Policy ID | {claimant.get(\"policy_id\", \"N/A\")} |')
md.append(f'| Phone | {claimant.get(\"phone\", \"N/A\")} |')
if claimant.get('email'):
    md.append(f'| Email | {claimant.get(\"email\")} |')
md.append('')

# Incident
md.append('## Incident Details')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
md.append(f'| Date | {incident.get(\"date\", \"N/A\")} |')
if incident.get('time'):
    md.append(f'| Time | {incident.get(\"time\")} |')
md.append(f'| Location | {incident.get(\"location\", \"N/A\")} |')
md.append(f'| Type | {incident.get(\"type\", \"N/A\")} |')
if incident.get('police_report_number'):
    md.append(f'| Police Report | {incident.get(\"police_report_number\")} |')
if incident.get('injuries_reported'):
    md.append(f'| Injuries | {incident.get(\"injuries_reported\")} |')
md.append('')

desc = incident.get('description', '')
if desc:
    md.append(f'**Description:** {desc}')
    md.append('')

other = incident.get('other_party', {})
if other and isinstance(other, dict) and (other.get('name') or other.get('vehicle')):
    md.append('**Other Party:**')
    if other.get('name'):
        md.append(f'- Name: {other[\"name\"]}')
    if other.get('vehicle'):
        md.append(f'- Vehicle: {other[\"vehicle\"]}')
    if other.get('insurance_company'):
        md.append(f'- Insurance: {other[\"insurance_company\"]}')
    md.append('')

# Vehicle & Damage Detection (AI)
if dd_list and len(dd_list) > 0:
    dd = dd_list[0] if isinstance(dd_list, list) else dd_list
    veh = dd.get('vehicle', {})
    damages = dd.get('damages', [])
    overall = dd.get('overall_assessment', {})

    md.append('## Vehicle Identification (AI)')
    md.append('')
    md.append('| Field | Value |')
    md.append('|-------|-------|')
    make = veh.get('make', 'Unknown')
    model = veh.get('model', 'Unknown')
    year = veh.get('year', 'Unknown')
    color = veh.get('color', 'Unknown')
    md.append(f'| Vehicle | {year} {make} {model} |')
    md.append(f'| Color | {color.title()} |')
    md.append(f'| Driveable | {\"Yes\" if overall.get(\"driveable\", True) else \"No\"} |')
    md.append(f'| Safety Impact | {overall.get(\"safety_impact\", \"N/A\").title()} |')
    md.append('')

    if damages:
        md.append('## Damage Detected (AI Vision)')
        md.append('')
        md.append('| Part | Severity | Action | Est. Cost (USD) |')
        md.append('|------|----------|--------|----------------|')
        total_min = 0
        total_max = 0
        for d in damages:
            cost = d.get('estimated_cost', {})
            cmin = cost.get('min', 0)
            cmax = cost.get('max', 0)
            total_min += cmin
            total_max += cmax
            md.append(f'| {d.get(\"part\", \"N/A\").title()} | {d.get(\"severity\", \"N/A\").title()} | {d.get(\"repair_action\", \"N/A\").title()} | \${cmin:,}–\${cmax:,} |')
        md.append(f'| **Total AI Estimate** | | | **\${total_min:,}–\${total_max:,}** |')
        md.append('')

# Coverage
md.append('## Coverage Verification')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
if co.get('covered') is not None:
    md.append(f'| Covered | {\"Yes\" if co.get(\"covered\") else \"No\"} |')
if co.get('coverage_type'):
    md.append(f'| Coverage Type | {co.get(\"coverage_type\", \"\").title()} |')
if co.get('deductible_amount') is not None:
    md.append(f'| Deductible | \${co.get(\"deductible_amount\", 0):,.0f} |')
if co.get('coverage_limit'):
    md.append(f'| Coverage Limit | \${co.get(\"coverage_limit\", 0):,.0f} |')
if co.get('denial_reason'):
    md.append(f'| Denial Reason | {co.get(\"denial_reason\")} |')
md.append('')

# Damage Assessment
md.append('## Damage Assessment')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
if assessor.get('repair_estimate_usd') is not None:
    md.append(f'| Repair Estimate | \${assessor.get(\"repair_estimate_usd\", 0):,.0f} |')
if assessor.get('total_loss') is not None:
    md.append(f'| Total Loss | {\"Yes\" if assessor.get(\"total_loss\") else \"No\"} |')
if assessor.get('parts_recommendation'):
    md.append(f'| Parts | {assessor.get(\"parts_recommendation\", \"\")} |')
if assessor.get('hidden_damage_likely') is not None:
    md.append(f'| Hidden Damage Likely | {\"Yes\" if assessor.get(\"hidden_damage_likely\") else \"No\"} |')
md.append('')

# Fraud Analysis
md.append('## Fraud Analysis')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
if fraud.get('risk_score') is not None:
    md.append(f'| Risk Score | {fraud.get(\"risk_score\", \"N/A\")}/100 |')
if fraud.get('risk_level'):
    md.append(f'| Risk Level | {fraud.get(\"risk_level\", \"\").title()} |')
if fraud.get('recommendation'):
    md.append(f'| Recommendation | {fraud.get(\"recommendation\", \"\")} |')
flags = fraud.get('flags', [])
if flags and len(flags) > 0:
    flag_strs = [f.get('description', f.get('pattern', '')) for f in flags if isinstance(f, dict)]
    if flag_strs:
        md.append(f'| Flags | {\"; \".join(flag_strs)} |')
md.append('')

# Senior Reviewer Decision
md.append('## Decision')
md.append('')
md.append('| Field | Value |')
md.append('|-------|-------|')
if sr.get('decision'):
    md.append(f'| Decision | **{sr.get(\"decision\", \"\")}** |')
if sr.get('decision_reasoning'):
    reasoning = sr.get('decision_reasoning', '')
    if len(reasoning) > 200:
        reasoning = reasoning[:200] + '...'
    md.append(f'| Reasoning | {reasoning} |')
conds = sr.get('conditions', [])
if conds and len(conds) > 0:
    for i, cond in enumerate(conds, 1):
        md.append(f'| Condition {i} | {cond} |')
md.append('')

# Payment (only if issued)
if finance.get('payment_amount_usd') is not None:
    md.append('## Payment')
    md.append('')
    md.append('| Field | Value |')
    md.append('|-------|-------|')
    md.append(f'| Payment Amount | **\${finance.get(\"payment_amount_usd\", 0):,.0f}** |')
    if finance.get('deductible_applied_usd') is not None:
        md.append(f'| Deductible Applied | \${finance.get(\"deductible_applied_usd\", 0):,.0f} |')
    if finance.get('depreciation_applied_usd') is not None:
        md.append(f'| Depreciation Applied | \${finance.get(\"depreciation_applied_usd\", 0):,.0f} |')
    if finance.get('payment_method'):
        md.append(f'| Payment Method | {finance.get(\"payment_method\", \"\").replace(\"_\", \" \").title()} |')
    if finance.get('payment_reference'):
        md.append(f'| Reference | {finance.get(\"payment_reference\", \"\")} |')
    if finance.get('subrogation_candidate'):
        target = finance.get('subrogation_target', 'Yes')
        md.append(f'| Subrogation | {target} |')
    if finance.get('supplement_eligible'):
        md.append(f'| Supplement Eligible | Yes |')
    md.append('')

md.append('---')
md.append('')
md.append('*Generated by Ohio Mutual Claims AI Pipeline*')

print('\n'.join(md))
" > "$MD_FILE" 2>/dev/null

if [ $? -ne 0 ] || [ ! -s "$MD_FILE" ]; then
  echo "Failed to generate markdown report" >&2
  exit 1
fi

# Convert to PDF
pandoc "$MD_FILE" -o "$PDF_FILE" --pdf-engine=wkhtmltopdf --quiet 2>/dev/null

if [ -f "$PDF_FILE" ]; then
  echo "$PDF_FILE"
else
  echo "Failed to generate PDF" >&2
  exit 1
fi
