#!/bin/bash
# ============================================================
# Vehicle Damage Detection API Wrapper
# ============================================================
# Calls RapidAPI VehicleInsights damage detection on a local
# image file and returns structured JSON.
#
# Usage: damage-detect.sh <image_path>
# Returns: Full API JSON response to stdout
#
# The Router calls this during FNOL when photos are provided.
# Result is stored in claim_data.damage_detection[] array.
# ============================================================

RAPIDAPI_KEY="${RAPIDAPI_KEY:?Set RAPIDAPI_KEY env var}"
RAPIDAPI_HOST="vehicle-damage-detection1.p.rapidapi.com"
API_URL="https://${RAPIDAPI_HOST}/damage_detection"

IMAGE_PATH="$1"

if [ -z "$IMAGE_PATH" ]; then
  echo '{"code":"400","status":"FAILED","message":"Usage: damage-detect.sh <image_path>"}'
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "{\"code\":\"404\",\"status\":\"FAILED\",\"message\":\"File not found: $IMAGE_PATH\"}"
  exit 1
fi

curl -s -X POST "$API_URL" \
  -H "X-Rapidapi-Key: $RAPIDAPI_KEY" \
  -H "X-Rapidapi-Host: $RAPIDAPI_HOST" \
  -F "imageFile=@${IMAGE_PATH}"
