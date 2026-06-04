---
description: Run the pre-market research workflow locally
---

Load .env for credentials (local mode). Run the pre-market research workflow.

Follow all steps from routines/pre-market.md EXCEPT:
- Skip the env-var block (credentials come from .env)
- Skip the git commit and push at the end

STEP 1 — Read memory for context:
- memory/TRADING-STRATEGY.md
- tail of memory/TRADE-LOG.md
- tail of memory/RESEARCH-LOG.md

STEP 2 — Pull live account state:
  bash scripts/alpaca.sh account
  bash scripts/alpaca.sh positions
  bash scripts/alpaca.sh orders

STEP 3 — Research market context via Perplexity. Run
bash scripts/perplexity.sh "<query>" for each catalyst, futures, VIX,
earnings, economic calendar, sector momentum, and each held ticker.
Fall back to WebSearch if Perplexity exits 3.

STEP 4 — Write a dated entry to memory/RESEARCH-LOG.md:
- Account snapshot, market context, 2-3 trade ideas, risk factors, decision.
