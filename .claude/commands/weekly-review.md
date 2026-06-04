---
description: Run the Friday weekly review workflow locally
---

Load .env for credentials (local mode). Run the weekly review workflow.

Follow all steps from routines/weekly-review.md EXCEPT:
- Skip the env-var block (credentials come from .env)
- Skip the git commit and push at the end

STEP 1 — Read full week of trade log, research log, existing weekly review, strategy.
STEP 2 — Pull week-end account state and positions.
STEP 3 — Compute week metrics including S&P 500 comparison via Perplexity.
STEP 4 — Append full review section to memory/WEEKLY-REVIEW.md.
STEP 5 — Update memory/TRADING-STRATEGY.md if a rule needs to change.
STEP 6 — Send one ClickUp message with headline numbers.
