#!/usr/bin/env bash
# Alpaca API wrapper. All trading API calls go through here.
# Usage: bash scripts/alpaca.sh <subcommand> [args...]
#
# Hardened version:
#   - Fails SAFE to paper trading unless ALPACA_LIVE=1 is explicitly set
#   - Preserves API error bodies (--fail-with-body) so failures are debuggable
#   - Keeps credentials out of the process table (curl --config via stdin)
#   - Auto-injects a client_order_id for idempotency on retries
#   - Pre-trade guard layer on `order`: enforces the rules that are checkable
#     from live account state (no options, max position size, max open positions)
#   - close-all / cancel-all require explicit --yes confirmation
#
# Guards enforce only STATELESS, live-checkable rules. Stateful rules
# (max 3 new trades/week, never move a stop down, exit sector after 2 fails)
# depend on memory/ history and are NOT enforceable here — keep those in the
# routine logic, or add a separate stateful pre-flight check.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${ALPACA_API_KEY:?ALPACA_API_KEY not set in environment}"
: "${ALPACA_SECRET_KEY:?ALPACA_SECRET_KEY not set in environment}"

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required for pre-trade guards" >&2; exit 1; }

# ---- Endpoint selection: fail SAFE to paper unless explicitly told to go live.
if [[ "${ALPACA_LIVE:-0}" == "1" ]]; then
  API="${ALPACA_ENDPOINT:-https://api.alpaca.markets/v2}"
else
  API="${ALPACA_ENDPOINT:-https://paper-api.alpaca.markets/v2}"
fi
DATA="${ALPACA_DATA_ENDPOINT:-https://data.alpaca.markets/v2}"

# ---- Risk limits (override via env). Defaults mirror CLAUDE.md.
MAX_POSITION_PCT="${MAX_POSITION_PCT:-20}"     # max % of equity per single position
MAX_OPEN_POSITIONS="${MAX_OPEN_POSITIONS:-6}"  # max distinct open positions

# ---- Auth helper: pass credentials via stdin config so they never hit argv/ps.
# --fail-with-body: non-zero exit on HTTP >=400 BUT still prints the error body.
acurl() {
  curl --fail-with-body -sS \
    --config <(printf 'header = "APCA-API-KEY-ID: %s"\nheader = "APCA-API-SECRET-KEY: %s"\n' \
      "$ALPACA_API_KEY" "$ALPACA_SECRET_KEY") \
    "$@"
}

# ---- Pre-trade guard. Reads the order JSON, validates against live state.
guard_order() {
  local body="$1"

  # Body must be valid JSON.
  echo "$body" | jq -e . >/dev/null 2>&1 || { echo "GUARD: order body is not valid JSON" >&2; exit 1; }

  local sym side qty notional otype
  sym="$(echo "$body"     | jq -r '.symbol      // empty')"
  side="$(echo "$body"    | jq -r '.side        // empty')"
  qty="$(echo "$body"     | jq -r '.qty         // empty')"
  notional="$(echo "$body"| jq -r '.notional    // empty')"
  otype="$(echo "$body"   | jq -r '.type        // "market"')"

  [[ -n "$sym" ]] || { echo "GUARD: order missing .symbol" >&2; exit 1; }

  # Rule: stocks only, no options. Equity tickers are short alpha(.) strings;
  # OCC option symbols (e.g. AAPL240119C00150000) and anything else are rejected.
  if ! [[ "$sym" =~ ^[A-Z]{1,5}(\.[A-Z])?$ ]]; then
    echo "GUARD: '$sym' is not a plain equity ticker — options/other instruments are blocked" >&2
    exit 1
  fi

  # Only gate position-opening BUYs for sizing/count. Sells/closes pass through.
  if [[ "$side" != "buy" ]]; then
    return 0
  fi

  # Fetch live equity once.
  local equity
  equity="$(acurl "$API/account" | jq -r '.equity')"
  [[ "$equity" =~ ^[0-9.]+$ ]] || { echo "GUARD: could not read account equity" >&2; exit 1; }

  # Determine intended notional value of this order.
  local order_value=""
  if [[ -n "$notional" ]]; then
    order_value="$notional"
  elif [[ -n "$qty" ]]; then
    # Need a price. Use latest ask; fall back to bid.
    local px
    px="$(acurl "$DATA/stocks/$sym/quotes/latest" | jq -r '.quote.ap // .quote.bp // 0')"
    [[ "$px" =~ ^[0-9.]+$ ]] && [[ "$px" != "0" ]] || { echo "GUARD: could not price $sym to size the order" >&2; exit 1; }
    order_value="$(echo "$qty * $px" | bc -l)"
  else
    echo "GUARD: order has neither .qty nor .notional" >&2
    exit 1
  fi

  # Rule: max % of equity per position.
  local max_value pct_used
  max_value="$(echo "$equity * $MAX_POSITION_PCT / 100" | bc -l)"
  if (( $(echo "$order_value > $max_value" | bc -l) )); then
    pct_used="$(echo "scale=1; $order_value * 100 / $equity" | bc -l)"
    printf 'GUARD: order ~$%.0f is %.1f%% of $%.0f equity — exceeds %s%% cap\n' \
      "$order_value" "$pct_used" "$equity" "$MAX_POSITION_PCT" >&2
    exit 1
  fi

  # Rule: max distinct open positions. Adding a NEW symbol must not exceed cap.
  local positions held count
  positions="$(acurl "$API/positions")"
  held="$(echo "$positions" | jq -r --arg s "$sym" 'any(.[]; .symbol == $s)')"
  count="$(echo "$positions" | jq 'length')"
  if [[ "$held" != "true" ]] && (( count >= MAX_OPEN_POSITIONS )); then
    echo "GUARD: already holding $count positions (cap $MAX_OPEN_POSITIONS) — '$sym' would open a new one" >&2
    exit 1
  fi

  return 0
}

cmd="${1:-}"
shift || true

case "$cmd" in
  account)
    acurl "$API/account"
    ;;
  clock)
    # Market status: {is_open, next_open, next_close}. On the trading API.
    acurl "$API/clock"
    ;;
  positions)
    acurl "$API/positions"
    ;;
  position)
    sym="${1:?usage: position SYM}"
    acurl "$API/positions/$sym"
    ;;
  quote)
    sym="${1:?usage: quote SYM}"
    acurl "$DATA/stocks/$sym/quotes/latest"
    ;;
  orders)
    status="${1:-open}"
    acurl "$API/orders?status=$status"
    ;;
  order)
    body="${1:?usage: order '<json>'}"
    guard_order "$body"
    # Inject a client_order_id for idempotency if the caller didn't set one.
    if [[ "$(echo "$body" | jq -r '.client_order_id // empty')" == "" ]]; then
      coid="bot-$(date +%Y%m%d)-$(echo "$body" | jq -r '.symbol')-$(date +%H%M%S)-$RANDOM"
      body="$(echo "$body" | jq --arg c "$coid" '. + {client_order_id: $c}')"
    fi
    acurl -H "Content-Type: application/json" -X POST -d "$body" "$API/orders"
    ;;
  cancel)
    oid="${1:?usage: cancel ORDER_ID}"
    acurl -X DELETE "$API/orders/$oid"
    ;;
  cancel-all)
    [[ "${1:-}" == "--yes" ]] || { echo "Refusing to cancel ALL orders without --yes" >&2; exit 1; }
    acurl -X DELETE "$API/orders"
    ;;
  close)
    sym="${1:?usage: close SYM}"
    acurl -X DELETE "$API/positions/$sym"
    ;;
  close-all)
    [[ "${1:-}" == "--yes" ]] || { echo "Refusing to liquidate ALL positions without --yes" >&2; exit 1; }
    acurl -X DELETE "$API/positions"
    ;;
  *)
    echo "Usage: bash scripts/alpaca.sh <account|clock|positions|position|quote|orders|order|cancel|cancel-all|close|close-all> [args]" >&2
    exit 1
    ;;
esac
echo
