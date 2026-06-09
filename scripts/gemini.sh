#!/usr/bin/env bash
# Research wrapper using Google Gemini.
# Usage: bash scripts/gemini.sh "<query>"
# Exits with code 3 if GEMINI_API_KEY is unset so callers can fall back.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a; source "$ENV_FILE"; set +a
fi

query="${1:-}"
if [[ -z "$query" ]]; then
  echo "usage: bash scripts/gemini.sh \"<query>\"" >&2; exit 1
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "WARNING: GEMINI_API_KEY not set. Fall back to WebSearch." >&2; exit 3
fi

MODEL="${GEMINI_MODEL:-gemini-3.1-flash-lite}"

payload=$(jq -n --arg text "$query" \
  '{"contents":[{"parts":[{"text":$text}]}]}')

curl -s \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$payload" \
  | jq -r '.candidates[0].content.parts[0].text'
