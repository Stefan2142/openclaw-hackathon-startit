#!/bin/bash
# ============================================================
# Ohio Mutual Claims Database CLI
# ============================================================
# Wraps PostgreSQL operations so OpenClaw agents can interact
# with the claims database via the exec tool.
#
# The claims table stores the full claim JSON document in a
# single claim_data JSONB column matching claim.schema.json.
#
# Commands:
#   db.sh create-claim <claim_id> <channel> <user_id> <policy_id> '<claim_json>'
#   db.sh get-claim <claim_id>
#   db.sh update-status <claim_id> <new_status>
#   db.sh update-step <claim_id> <step_name> '<json_data>'
#   db.sh append-audit <claim_id> '<audit_json>'
#   db.sh list-claims-by-user <user_id>
#   db.sh count-user-claims <user_id>
#   db.sh get-active-claim <user_id>
#   db.sh list-claims-by-status <status>
#   db.sh add-media <claim_id> <file_path> [media_type]
#   db.sh get-media <claim_id>
#   db.sh log-trace <claim_id> <agent_id> <event_type> '<message>' ['<details_json>']
#   db.sh get-traces <claim_id> [agent_id]
# ============================================================

DB_NAME="${OPENCLAW_DB_NAME:-openclaw_claims}"
DB_USER="${OPENCLAW_DB_USER:-openclaw}"
DB_HOST="${OPENCLAW_DB_HOST:-localhost}"
DB_PORT="${OPENCLAW_DB_PORT:-5432}"

PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -A"

case "$1" in

  create-claim)
    # Creates a new claim with the full JSON document.
    # Usage: db.sh create-claim CLM-2026-00001 telegram 12345 POL-AUT-10001 '{"claim_id":"CLM-2026-00001",...}'
    CLAIM_ID="$2"
    CHANNEL="$3"
    USER_ID="$4"
    POLICY_ID="$5"
    CLAIM_JSON="$6"
    $PSQL -c "INSERT INTO claims (claim_id, status, channel, user_id, policy_id, claim_data)
              VALUES ('$CLAIM_ID', 'FNOL_RECEIVED', '$CHANNEL', '$USER_ID', '$POLICY_ID', '$CLAIM_JSON'::jsonb)
              RETURNING claim_data;"
    ;;

  get-claim)
    # Returns the full claim JSON document.
    # Usage: db.sh get-claim CLM-2026-00001
    CLAIM_ID="$2"
    $PSQL -c "SELECT claim_data FROM claims WHERE claim_id = '$CLAIM_ID';"
    ;;

  get-claim-assessor)
    # Returns claim JSON with financial fields STRIPPED from claims_officer section.
    # Enforces separation of duties: Assessor must not see deductible or coverage limit
    # to prevent anchoring bias in damage estimates (CCO compliance requirement).
    # Usage: db.sh get-claim-assessor CLM-2026-00001
    CLAIM_ID="$2"
    $PSQL -c "SELECT claim_data #- '{pipeline,claims_officer,deductible_amount}'
                                #- '{pipeline,claims_officer,coverage_limit}'
              FROM claims WHERE claim_id = '$CLAIM_ID';"
    ;;

  update-status)
    # Updates the claim status (both in the indexed column and inside claim_data).
    # Usage: db.sh update-status CLM-2026-00001 COVERAGE_CHECKED
    CLAIM_ID="$2"
    NEW_STATUS="$3"
    $PSQL -c "UPDATE claims
              SET status = '$NEW_STATUS',
                  claim_data = jsonb_set(
                    jsonb_set(claim_data, '{status}', '\"$NEW_STATUS\"'),
                    '{updated_at}', to_jsonb(to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'))
                  )
              WHERE claim_id = '$CLAIM_ID'
              RETURNING claim_data;"
    ;;

  update-step)
    # Updates a pipeline step section within claim_data.
    # Usage: db.sh update-step CLM-2026-00001 claims_officer '{"covered":true,"deductible_amount":500,...}'
    CLAIM_ID="$2"
    STEP="$3"
    JSON_DATA="$4"
    $PSQL -c "UPDATE claims
              SET claim_data = jsonb_set(
                jsonb_set(claim_data, '{pipeline,$STEP}', '$JSON_DATA'::jsonb),
                '{updated_at}', to_jsonb(to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'))
              )
              WHERE claim_id = '$CLAIM_ID'
              RETURNING claim_data->'pipeline'->'$STEP';"
    ;;

  append-audit)
    # Appends an audit log entry to the audit_log array inside claim_data.
    # Usage: db.sh append-audit CLM-2026-00001 '{"timestamp":"...","agent":"claims-officer","action":"coverage_verified","reasoning":"..."}'
    CLAIM_ID="$2"
    AUDIT_JSON="$3"
    $PSQL -c "UPDATE claims
              SET claim_data = jsonb_set(
                claim_data,
                '{audit_log}',
                COALESCE(claim_data->'audit_log', '[]'::jsonb) || '$AUDIT_JSON'::jsonb
              )
              WHERE claim_id = '$CLAIM_ID'
              RETURNING jsonb_array_length(claim_data->'audit_log') AS audit_count;"
    ;;

  list-claims-by-user)
    # Lists all claims for a given user ID.
    # Usage: db.sh list-claims-by-user 12345
    USER_ID="$2"
    $PSQL -c "SELECT json_agg(claim_data) FROM claims WHERE user_id = '$USER_ID';"
    ;;

  count-user-claims)
    # Returns claim count stats for a user (total, last 30 days, last year).
    # Usage: db.sh count-user-claims 12345
    USER_ID="$2"
    $PSQL -c "SELECT json_build_object(
                'user_id', '$USER_ID',
                'total', count(*),
                'last_30_days', count(*) FILTER (WHERE created_at > NOW() - INTERVAL '30 days'),
                'last_year', count(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 year')
              ) FROM claims WHERE user_id = '$USER_ID';"
    ;;

  get-active-claim)
    # Returns the active (non-terminal) claim for a user.
    # Terminal states: PAYMENT_ISSUED, DENIED, ESCALATED, ERROR
    # Returns empty if no active claim exists.
    # Usage: db.sh get-active-claim telegram_user_123
    USER_ID="$2"
    $PSQL -c "SELECT claim_data FROM claims
              WHERE user_id = '$USER_ID'
              AND status NOT IN ('PAYMENT_ISSUED', 'DENIED', 'ESCALATED', 'ERROR')
              ORDER BY created_at DESC LIMIT 1;"
    ;;

  list-claims-by-status)
    # Lists all claims with a given status.
    # Usage: db.sh list-claims-by-status ASSESSED
    STATUS="$2"
    $PSQL -c "SELECT json_agg(claim_data) FROM claims WHERE status = '$STATUS';"
    ;;

  add-media)
    # Records a media file reference for a claim.
    # Usage: db.sh add-media CLM-2026-00001 /shared/uploads/CLM-2026-00001/photo1.jpg image
    CLAIM_ID="$2"
    FILE_PATH="$3"
    MEDIA_TYPE="${4:-image}"
    $PSQL -c "INSERT INTO claim_media (claim_id, file_path, media_type)
              VALUES ('$CLAIM_ID', '$FILE_PATH', '$MEDIA_TYPE')
              RETURNING row_to_json(claim_media.*);"
    ;;

  get-media)
    # Returns all media files for a claim.
    # Usage: db.sh get-media CLM-2026-00001
    CLAIM_ID="$2"
    $PSQL -c "SELECT json_agg(row_to_json(m)) FROM claim_media m WHERE claim_id = '$CLAIM_ID';"
    ;;

  log-trace)
    # Logs an agent activity trace to the agent_traces table.
    # event_type: START (agent begins), STEP (key decision), END (agent done), ERROR (failure)
    # Usage: db.sh log-trace CLM-2026-00001 claims-officer START 'Beginning coverage verification'
    # Usage: db.sh log-trace CLM-2026-00001 assessor STEP 'Repair estimate: $4,500' '{"estimate":4500}'
    CLAIM_ID="$2"
    AGENT_ID="$3"
    EVENT_TYPE="$4"
    MESSAGE="$5"
    DETAILS="${6:-null}"
    if [ "$DETAILS" = "null" ]; then
      $PSQL -c "INSERT INTO agent_traces (claim_id, agent_id, event_type, message)
                VALUES ('$CLAIM_ID', '$AGENT_ID', '$EVENT_TYPE', '$MESSAGE')
                RETURNING json_build_object('id', id, 'agent', agent_id, 'event', event_type, 'message', message, 'at', created_at);"
    else
      $PSQL -c "INSERT INTO agent_traces (claim_id, agent_id, event_type, message, details)
                VALUES ('$CLAIM_ID', '$AGENT_ID', '$EVENT_TYPE', '$MESSAGE', '$DETAILS'::jsonb)
                RETURNING json_build_object('id', id, 'agent', agent_id, 'event', event_type, 'message', message, 'at', created_at);"
    fi
    ;;

  get-traces)
    # Returns all traces for a claim, optionally filtered by agent.
    # Usage: db.sh get-traces CLM-2026-00001
    # Usage: db.sh get-traces CLM-2026-00001 claims-officer
    CLAIM_ID="$2"
    AGENT_FILTER="$3"
    if [ -n "$AGENT_FILTER" ]; then
      $PSQL -c "SELECT json_agg(json_build_object(
                  'id', id, 'agent', agent_id, 'event', event_type,
                  'message', message, 'details', details, 'at', created_at
                ) ORDER BY created_at)
                FROM agent_traces
                WHERE claim_id = '$CLAIM_ID' AND agent_id = '$AGENT_FILTER';"
    else
      $PSQL -c "SELECT json_agg(json_build_object(
                  'id', id, 'agent', agent_id, 'event', event_type,
                  'message', message, 'details', details, 'at', created_at
                ) ORDER BY created_at)
                FROM agent_traces
                WHERE claim_id = '$CLAIM_ID';"
    fi
    ;;

  *)
    echo "Unknown command: $1"
    echo "Available: create-claim, get-claim, get-claim-assessor, get-active-claim, update-status, update-step, append-audit, list-claims-by-user, count-user-claims, list-claims-by-status, add-media, get-media, log-trace, get-traces"
    exit 1
    ;;
esac
