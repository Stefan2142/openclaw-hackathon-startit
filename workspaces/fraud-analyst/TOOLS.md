# Tool Usage Notes

## exec + db.sh (database operations)
```bash
# Read full claim data
bash /shared/scripts/db.sh get-claim <claim_id>

# Check user's claim history (CRITICAL for fraud pattern detection)
bash /shared/scripts/db.sh list-claims-by-user <user_id>
bash /shared/scripts/db.sh count-user-claims <user_id>

# Update your pipeline section
bash /shared/scripts/db.sh update-step <claim_id> fraud_analyst '{"risk_score":15,"risk_level":"low","flags":[],"soft_fraud":false,"recommendation":"CLEAR","completed_at":"2026-02-21T10:31:00Z","agent_session":"your-session-key"}'

# Update claim status
bash /shared/scripts/db.sh update-status <claim_id> FRAUD_ANALYZED

# Append audit log entry
bash /shared/scripts/db.sh append-audit <claim_id> '{"timestamp":"2026-02-21T10:31:00Z","agent":"fraud-analyst","action":"fraud_analysis_complete","reasoning":"..."}'
```
