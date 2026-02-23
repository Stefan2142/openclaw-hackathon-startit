#!/bin/bash
# ============================================================
# Send Document to Telegram
# ============================================================
# Uses Telegram Bot API to send a file as a document.
# Called by Router at pipeline completion to attach PDF reports.
#
# Usage: send-telegram-doc.sh <chat_id> <file_path> [caption]
# ============================================================

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:?Set TELEGRAM_BOT_TOKEN env var}"
CHAT_ID="$1"
FILE_PATH="$2"
CAPTION="${3:-}"

if [ -z "$CHAT_ID" ] || [ -z "$FILE_PATH" ]; then
  echo '{"ok":false,"error":"Usage: send-telegram-doc.sh <chat_id> <file_path> [caption]"}' >&2
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "{\"ok\":false,\"error\":\"File not found: $FILE_PATH\"}" >&2
  exit 1
fi

API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendDocument"

if [ -n "$CAPTION" ]; then
  curl -s -X POST "$API_URL" \
    -F "chat_id=$CHAT_ID" \
    -F "document=@${FILE_PATH}" \
    -F "caption=$CAPTION" \
    -F "parse_mode=Markdown"
else
  curl -s -X POST "$API_URL" \
    -F "chat_id=$CHAT_ID" \
    -F "document=@${FILE_PATH}"
fi
