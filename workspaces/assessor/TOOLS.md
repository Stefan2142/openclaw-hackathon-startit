# Tool Usage Notes

## exec + db.sh (database operations)
```bash
# Read full claim data
bash /shared/scripts/db.sh get-claim <claim_id>

# Get media (photos) for the claim
bash /shared/scripts/db.sh get-media <claim_id>

# Update your pipeline section
bash /shared/scripts/db.sh update-step <claim_id> assessor '{"repair_estimate_usd":4200,"total_loss":false,"acv_usd":null,"salvage_value_usd":null,"parts_recommendation":"OEM","labor_hours":18,"rental_days":7,"pre_existing_damage_flags":[],"hidden_damage_likely":false,"completed_at":"2026-02-21T10:30:00Z","agent_session":"your-session-key"}'

# Update claim status
bash /shared/scripts/db.sh update-status <claim_id> ASSESSED

# Append audit log entry
bash /shared/scripts/db.sh append-audit <claim_id> '{"timestamp":"2026-02-21T10:30:00Z","agent":"assessor","action":"estimate_completed","reasoning":"..."}'
```
