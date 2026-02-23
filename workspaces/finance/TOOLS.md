# Tool Usage Notes

## exec + db.sh (database operations)
```bash
# Read full claim data (MUST verify Senior Reviewer approval before payment)
bash /shared/scripts/db.sh get-claim <claim_id>

# Update your pipeline section
bash /shared/scripts/db.sh update-step <claim_id> finance '{"payment_amount_usd":3700,"deductible_applied_usd":500,"depreciation_applied_usd":0,"subrogation_candidate":true,"subrogation_target":"State Farm SF-98-7654321","payment_method":"direct_deposit","payment_reference":"PAY-2026-00001","supplement_eligible":false,"completed_at":"2026-02-21T10:33:00Z","agent_session":"your-session-key"}'

# Update claim status
bash /shared/scripts/db.sh update-status <claim_id> PAYMENT_ISSUED

# Append audit log entry
bash /shared/scripts/db.sh append-audit <claim_id> '{"timestamp":"2026-02-21T10:33:00Z","agent":"finance","action":"payment_issued","reasoning":"...","regulation_reference":"FCSP Act: payment issued within regulatory window"}'
```
