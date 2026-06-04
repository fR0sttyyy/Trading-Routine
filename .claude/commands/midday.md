---
description: Run the midday scan workflow locally
---

Load .env for credentials (local mode). Run the midday scan workflow.

Follow all steps from routines/midday.md EXCEPT:
- Skip the env-var block (credentials come from .env)
- Skip the git commit and push at the end

STEP 1 — Read strategy, trade log tail, today's research log.
STEP 2 — Pull positions and open orders.
STEP 3 — Cut losers at -7%.
STEP 4 — Tighten trailing stops on winners (+15% -> 7%, +20% -> 5%).
STEP 5 — Thesis check: cut broken theses even if not at -7%.
STEP 6 — Optional Gemini research on sharp movers.
STEP 7 — Notify via ClickUp only if action was taken.
