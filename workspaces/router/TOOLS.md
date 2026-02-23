# Tool Usage Notes

## sessions_send (CRITICAL -- how you dispatch work to pipeline agents)
Use `sessions_send` to call each pipeline agent sequentially.
- Always set `timeoutSeconds: 120` so you wait for the response
- Target agents by session key: `agent:<agent-id>:main`
- Available agents:
  - `agent:claims-officer:main` -- coverage verification (Stage 1)
  - `agent:assessor:main` -- damage assessment (Stage 2)
  - `agent:fraud-analyst:main` -- fraud risk analysis (Stage 3)
  - `agent:senior-reviewer:main` -- final decision authority (Stage 4)
  - `agent:finance:main` -- payment calculation (Stage 5)

## exec + db.sh (database operations)
All claim data is stored in PostgreSQL as JSONB. Use the db.sh wrapper:

```bash
# Create a new claim (pass the full claim JSON document)
bash /shared/scripts/db.sh create-claim CLM-2026-00001 telegram 12345 POL-AUT-10001 '{"claim_id":"CLM-2026-00001","status":"FNOL_RECEIVED",...}'

# Read full claim data
bash /shared/scripts/db.sh get-claim CLM-2026-00001

# Update claim status (updates both indexed column and claim_data.status)
bash /shared/scripts/db.sh update-status CLM-2026-00001 COVERAGE_CHECKED

# Update a pipeline step section (writes JSON to claim_data.pipeline.<step>)
bash /shared/scripts/db.sh update-step CLM-2026-00001 claims_officer '{"covered":true,"deductible_amount":500,...}'

# Append an audit log entry
bash /shared/scripts/db.sh append-audit CLM-2026-00001 '{"timestamp":"2026-02-21T10:30:00Z","agent":"router","action":"claim_registered","reasoning":"...","regulation_reference":null}'

# List all claims by user (for fraud pattern detection)
bash /shared/scripts/db.sh list-claims-by-user 12345

# Count user claims (total, last 30 days, last year)
bash /shared/scripts/db.sh count-user-claims 12345

# Record media attachment
bash /shared/scripts/db.sh add-media CLM-2026-00001 /shared/uploads/CLM-2026-00001/photo1.jpg image

# Get all media for a claim
bash /shared/scripts/db.sh get-media CLM-2026-00001
```

## exec + send-telegram-doc.sh (send files to user on Telegram)
Use this to send PDF reports or other documents directly to the Telegram user:

```bash
# Send a PDF report to the user
bash /shared/scripts/send-telegram-doc.sh <telegram_chat_id> /shared/reports/CLM-2026-00001.pdf "Claim Report — CLM-2026-00001"
```

IMPORTANT: The `write` tool CANNOT send files to Telegram. Always use `send-telegram-doc.sh` for file attachments.

## exec + damage-detect.sh (AI vehicle damage detection)
Calls the VehicleInsights API on a photo during FNOL intake:

```bash
bash /shared/scripts/damage-detect.sh /shared/uploads/CLM-2026-00001/photo1.jpg
```

Returns JSON with vehicle identification, per-part damage analysis, and overall assessment.

## exec + generate-report.sh (PDF claim report)
Generates a PDF claim report at pipeline completion:

```bash
bash /shared/scripts/generate-report.sh CLM-2026-00001
# Outputs: /shared/reports/CLM-2026-00001.pdf
```

## read (for policy files)
Mock policies live as static JSON files at `/shared/policies/<policy_id>.json`.
Use `read` to look them up. You construct the path from the claimant's policy_id.
