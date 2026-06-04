---
description: Run the market-open execution workflow locally
---

Load .env for credentials (local mode). Run the market-open execution workflow.

Follow all steps from routines/market-open.md EXCEPT:
- Skip the env-var block (credentials come from .env)
- Skip the git commit and push at the end

STEP 1 — Read today's research log. If missing, run pre-market steps inline.
STEP 2 — Re-validate planned trades with fresh quotes.
STEP 3 — Run the buy-side gate on each planned order.
STEP 4 — Execute buys (market orders, day TIF).
STEP 5 — Place 10% trailing stop GTC immediately after each fill.
STEP 6 — Append each trade to memory/TRADE-LOG.md.
STEP 7 — Notify via ClickUp only if a trade was placed.
