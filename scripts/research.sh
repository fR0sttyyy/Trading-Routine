#!/usr/bin/env bash
# Research wrapper. Market numbers via Yahoo Finance (no key, no LLM),
# news/catalysts via Tavily. Drop-in replacement for gemini.sh.
#
# Usage:
#   bash scripts/research.sh quote SYM [SYM ...]   # live quote(s)
#   bash scripts/research.sh context               # standard market-context bundle
#   bash scripts/research.sh news "<query>"        # news/catalysts via Tavily
#
# Fallback contract (matches gemini.sh): exits 3 when a source is unavailable
# (e.g. TAVILY_API_KEY unset, or a data call fails) so callers fall back to
# WebSearch. Numbers come from a market-data API and CANNOT be hallucinated —
# that is the whole point of replacing the LLM research path for quotes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a; source "$ENV_FILE"; set +a
fi

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required" >&2; exit 1; }

UA="Mozilla/5.0 (compatible; trading-routine/1.0)"
YF="https://query1.finance.yahoo.com/v8/finance/chart"

# URL-encode a symbol (^GSPC, ES=F, etc. contain reserved chars).
urlenc() { printf '%s' "$1" | jq -sRr @uri; }

# Print "SYMBOL  PRICE  (+/-PCT%)" for one Yahoo symbol. Returns non-zero on failure.
yf_quote() {
  local sym="$1" enc resp
  enc="$(urlenc "$sym")"
  resp="$(curl --fail-with-body -sS -H "User-Agent: $UA" \
    "$YF/$enc?range=1d&interval=1d")" || return 1
  echo "$resp" | jq -e -r --arg s "$sym" '
    .chart.result[0].meta as $m
    | ($m.regularMarketPrice // empty) as $p
    | ($m.chartPreviousClose // $m.previousClose // empty) as $pc
    | if $p == null or $pc == null or $pc == 0 then empty
      else
        (($p - $pc) / $pc * 100 * 100 | round / 100) as $chg
        | "\($s)\t\($p)\t\(if $chg >= 0 then "+" else "" end)\($chg)%"
      end
  ' || return 1
}

cmd="${1:-}"
shift || true

case "$cmd" in
  quote)
    [[ $# -ge 1 ]] || { echo "usage: research.sh quote SYM [SYM ...]" >&2; exit 1; }
    ok=0
    for s in "$@"; do
      if yf_quote "$s"; then ok=1; fi
    done
    # If every symbol failed, signal fallback.
    [[ "$ok" == "1" ]] || { echo "WARNING: no Yahoo data. Fall back to WebSearch." >&2; exit 3; }
    ;;

  context)
    # Standard pre-market "Market Context" bundle. Edit the lists to taste.
    declare -A LABEL=(
      ["^GSPC"]="S&P 500"      ["^IXIC"]="Nasdaq"        ["^DJI"]="Dow"
      ["^VIX"]="VIX"           ["ES=F"]="S&P futures"    ["NQ=F"]="Nasdaq futures"
      ["CL=F"]="WTI crude"     ["BZ=F"]="Brent crude"
      ["XLE"]="Energy"         ["XLB"]="Materials"       ["XLI"]="Industrials"
      ["XLK"]="Tech"           ["XLV"]="Healthcare"      ["XLP"]="Staples"
      ["XLF"]="Financials"
    )
    ORDER=("^GSPC" "^IXIC" "^DJI" "^VIX" "ES=F" "NQ=F" "CL=F" "BZ=F" \
           "XLE" "XLB" "XLI" "XLK" "XLV" "XLP" "XLF")
    ok=0
    printf '%-16s %-12s %-10s %s\n' "INSTRUMENT" "SYMBOL" "PRICE" "CHG"
    for s in "${ORDER[@]}"; do
      if line="$(yf_quote "$s")"; then
        ok=1
        IFS=$'\t' read -r sym price chg <<<"$line"
        printf '%-16s %-12s %-10s %s\n' "${LABEL[$s]}" "$sym" "$price" "$chg"
      else
        printf '%-16s %-12s %-10s %s\n' "${LABEL[$s]}" "$s" "n/a" "(fetch failed)"
      fi
    done
    [[ "$ok" == "1" ]] || { echo "WARNING: no Yahoo data. Fall back to WebSearch." >&2; exit 3; }
    ;;

  news)
    query="${1:-}"
    [[ -n "$query" ]] || { echo "usage: research.sh news \"<query>\"" >&2; exit 1; }
    if [[ -z "${TAVILY_API_KEY:-}" ]]; then
      echo "WARNING: TAVILY_API_KEY not set. Fall back to WebSearch." >&2; exit 3
    fi
    body="$(jq -n --arg q "$query" '{
      query: $q,
      topic: "news",
      days: 3,
      max_results: 6,
      include_answer: true
    }')"
    # Tavily current auth is a Bearer token. If your key is the older style,
    # remove the header and add  "api_key": $k  into the JSON body instead.
    resp="$(curl --fail-with-body -sS \
      -H "Authorization: Bearer ${TAVILY_API_KEY}" \
      -H "Content-Type: application/json" \
      -X POST -d "$body" "https://api.tavily.com/search")" \
      || { echo "WARNING: Tavily call failed. Fall back to WebSearch." >&2; echo "$resp" >&2; exit 3; }

    # Print the synthesized answer (if any) then the source list with dates.
    echo "$resp" | jq -e -r '
      (if (.answer // "") != "" then "SUMMARY: \(.answer)\n" else "" end)
      + "SOURCES:\n"
      + ( [ .results[]? | "- \(.title) [\(.published_date // "n/a")]\n  \(.url)" ]
          | join("\n") )
    ' || { echo "WARNING: empty/unparseable Tavily response. Fall back to WebSearch." >&2; exit 3; }
    ;;

  *)
    echo "Usage: bash scripts/research.sh <quote|context|news> [args]" >&2
    exit 1
    ;;
esac
