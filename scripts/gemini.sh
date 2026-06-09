#!/usr/bin/env bash
# Research wrapper. All market research goes through Google Gemini.
# Usage: bash scripts/gemini.sh "<query>"
# Exits with code 3 if GEMINI_API_KEY is unset so callers can fall back.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

query="${1:-}"
if [[ -z "$query" ]]; then
  echo "usage: bash scripts/gemini.sh \"<query>\"" >&2
  exit 1
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "WARNING: GEMINI_API_KEY not set. Fall back to WebSearch." >&2
  exit 3
fi

MODEL="${GEMINI_MODEL:-gemini-3.1-flash-lite}"

payload="$(python -c "
import json, sys
print(json.dumps({
  'system_instruction': {
    'parts': [{'text': 'You are a precise financial research assistant. Cite every claim. Be concise.'}]
  },
  'contents': [
    {'role': 'user', 'parts': [{'text': sys.argv[1]}]}
  ],
  'tools': [{'google_search': {}}]
}))
" "$query")"

curl -fsS \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$payload" | python -c "
import json, sys
data = json.load(sys.stdin)
text = data['candidates'][0]['content']['parts'][0]['text']
print(text)
"
echo
