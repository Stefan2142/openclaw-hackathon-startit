# Telegram Bot API - Quick Start

Send messages programmatically via the **OhioClaimsRouter** bot.

## Config

| Parameter | Value |
|-----------|-------|
| Bot username | `@ohio_claims_router_bot` |
| Bot token | `YOUR_BOT_TOKEN` |
| Chat ID | `YOUR_CHAT_ID` |

> Replace `YOUR_BOT_TOKEN` and `YOUR_CHAT_ID` with real values before use.

## How to get your Chat ID

1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. It replies with your numeric chat ID

## Send a message

### cURL

```bash
curl -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": YOUR_CHAT_ID,
    "text": "Hello from the API!"
  }'
```

### Python

```python
import requests

BOT_TOKEN = "YOUR_BOT_TOKEN"
CHAT_ID = "YOUR_CHAT_ID"

def send_message(text):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {"chat_id": CHAT_ID, "text": text}
    response = requests.post(url, json=payload)
    return response.json()

send_message("Hello from Python!")
```

### JavaScript (Node.js)

```javascript
const BOT_TOKEN = "YOUR_BOT_TOKEN";
const CHAT_ID = "YOUR_CHAT_ID";

async function sendMessage(text) {
  const res = await fetch(
    `https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: CHAT_ID, text }),
    }
  );
  return res.json();
}

sendMessage("Hello from Node!");
```

## Useful endpoints

| Endpoint | Description |
|----------|-------------|
| `/sendMessage` | Send a text message |
| `/sendPhoto` | Send a photo (file or URL) |
| `/sendDocument` | Send a file/document |
| `/getMe` | Get bot info |
| `/getWebhookInfo` | Check current webhook config |

Base URL: `https://api.telegram.org/bot{BOT_TOKEN}/`

## Formatting options

Pass `parse_mode` to format messages:

```json
{
  "chat_id": "YOUR_CHAT_ID",
  "text": "*Bold* and _italic_ text",
  "parse_mode": "Markdown"
}
```

Supported: `Markdown`, `MarkdownV2`, `HTML`.

## Full API docs

https://core.telegram.org/bots/api
