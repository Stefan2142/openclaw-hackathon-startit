# Tool Usage Notes

## exec + db.sh (database operations)
```bash
# Read full claim data
bash /shared/scripts/db.sh get-claim <claim_id>

# Update your pipeline section
bash /shared/scripts/db.sh update-step <claim_id> claims_officer '{"covered":true,"policy_status":"active","coverage_type":"collision","deductible_amount":500,"coverage_limit":null,"exclusions_checked":["intentional_acts: not applicable","racing: not applicable"],"denial_reason":null,"um_uim_route":"not_applicable","completed_at":"2026-02-21T10:30:00Z","agent_session":"your-session-key"}'

# Update claim status
bash /shared/scripts/db.sh update-status <claim_id> COVERAGE_CHECKED

# Append audit log entry
bash /shared/scripts/db.sh append-audit <claim_id> '{"timestamp":"2026-02-21T10:30:00Z","agent":"claims-officer","action":"coverage_verified","reasoning":"...","regulation_reference":"FCSP Act: all exclusions documented"}'
```

## read (for policy files)
Policy files live at `/shared/policies/<policy_id>.json`. Use `read` to look them up.
The Router provides the policy_id in your task message.
