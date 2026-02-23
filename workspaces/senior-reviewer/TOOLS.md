# Tool Usage Notes

## exec + db.sh (database operations)
```bash
# Read full claim data
bash /shared/scripts/db.sh get-claim <claim_id>

# Update your pipeline section
bash /shared/scripts/db.sh update-step <claim_id> senior_reviewer '{"decision":"APPROVED","decision_reasoning":"...","conditions":[],"escalated_to_human":false,"escalation_reason":null,"fcsp_timeline_check":{"acknowledgment_deadline":"2026-03-06","decision_deadline":"2026-04-02","payment_deadline":"2026-05-02","compliant":true},"completed_at":"2026-02-21T10:32:00Z","agent_session":"your-session-key"}'

# Update claim status
bash /shared/scripts/db.sh update-status <claim_id> REVIEWED

# Append audit log entry
bash /shared/scripts/db.sh append-audit <claim_id> '{"timestamp":"2026-02-21T10:32:00Z","agent":"senior-reviewer","action":"decision_approved","reasoning":"...","regulation_reference":"FCSP Act: decision within regulatory window"}'
```
