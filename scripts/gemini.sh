#!/usr/bin/env bash
# Research wrapper using Google Gemini.
# Usage: bash scripts/gemini.sh "<query>"
# Exits with code 3 if GEMINI_API_KEY is unset so callers can fall back.
#
# FIXED:
#   - Enables Grounding with Google Search (tools:[{google_search:{}}]).
#     Without it, Gemini answers from TRAINING DATA — the cause of dead research.
#   - Default model moved OFF the -lite tier, which does not reliably support
#     grounding, to a grounding-capable model.
#   - API key sent as a header, not in the URL query string (keeps it off argv).
#   - --fail-with-body so API errors surface instead of returning silent "".
#   - Emits exit code 4 if a market query comes back ungrounded, so callers can
#     fall back to WebSearch instead of trusting stale data.
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

# Must be a grounding-capable model. NOT a -lite tier.
MODEL="${GEMINI_MODEL:-gemini-3.5-flash}"

SYS="You are a market research assistant. Use Google Search for every query. \
Report only facts grounded in current web sources, with dates. If you cannot \
retrieve live data, reply exactly 'NO LIVE DATA' — never answer from training data."

# tools:[{google_search:{}}] is the fix — it turns on live web grounding.
payload=$(jq -n --arg text "$query" --arg sys "$SYS" \
  '{
     contents: [ { parts: [ { text: $text } ] } ],
     system_instruction: { parts: [ { text: $sys } ] },
     tools: [ { google_search: {} } ]
   }')

resp=$(curl --fail-with-body -sS \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$payload") || { echo "ERROR: Gemini API call failed. Fall back to WebSearch." >&2; echo "$resp" >&2; exit 3; }

text=$(echo "$resp" | jq -r '.candidates[0].content.parts[]?.text // empty')
if [[ -z "$text" ]]; then
  echo "ERROR: empty Gemini response. Fall back to WebSearch." >&2
  echo "$resp" >&2
  exit 3
fi

# If grounding never fired, this was training-data output. Refuse it.
grounded=$(echo "$resp" | jq -r '.candidates[0].groundingMetadata != null')
if [[ "$grounded" != "true" ]]; then
  echo "WARNING: Gemini response was NOT grounded (no search performed). Fall back to WebSearch." >&2
  exit 4
fi

echo "$text"
