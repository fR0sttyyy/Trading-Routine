# Weekly Review

Friday reviews appended here.
Template for each entry:

## Week ending YYYY-MM-DD

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $X |
| Ending portfolio | $X |
| Week return | ±$X (±X%) |
| S&P 500 week | ±X% |
| Bot vs S&P | ±X% |
| Trades | N (W:X / L:Y / open:Z) |
| Win rate | X% |
| Best trade | SYM +X% |
| Worst trade | SYM -X% |
| Profit factor | X.XX |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop |

### What Worked
- ...

### What Didn't Work
- ...

### Key Lessons
- ...

### Adjustments for Next Week
- ...

### Overall Grade: X

---

## Week ending 2026-06-09

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $100,000.00 (Jun 04 phase baseline) |
| Ending portfolio | $100,000.00 |
| Week return | $0 (0.00%) |
| S&P 500 week | N/A (live lookup unavailable) |
| Bot vs S&P | N/A |
| Trades | 0 (W:0 / L:0 / open:0) |
| Win rate | N/A (no closed trades) |
| Best trade | N/A |
| Worst trade | N/A |
| Profit factor | N/A |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| - | - | - | - | - |
| — | — | — | — | No trades this week |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop |
| - | - | - | - | - |
| — | — | — | — | None — 100% cash |

### What Worked
- Discipline: zero FOMO entries despite chip-bounce + Iran-Israel ceasefire headlines on Day 1
- Correctly flagged CPI (Wed 6/10) as a binary event and stood down for it
- Pre-market research captured sector momentum map (Materials/Energy/Semis leading; Utilities/REITs lagging)
- Capital preservation on Day 0 amid BRCM/CRWD post-earnings carnage and pre-NFP gap risk

### What Didn't Work
- Two research sessions, zero trade ideas executed — risk of analysis paralysis if pattern repeats
- No watchlist orders staged (limit/stop entries) to capture moves without screen-time
- S&P benchmark lookup failed (Gemini date-bound) — need a fallback method via SPY bars or hardcoded snapshot

### Key Lessons
- Phase baseline reset to $100k (paper refund) — sizing rules apply proportionally; 20% cap = $20k/position
- Event-driven calendar (CPI/PPI/UMich) dominated the short week — earn the right to size up by waiting for catalyst clearance
- "HOLD" is a valid output but must convert to staged orders or firm triggers, not just observations

### Adjustments for Next Week
- Post-CPI (Wed 6/10), be prepared to initiate first position if NVDA/FCX trigger holds — do not let the watchlist die in research log
- Stage limit orders at pre-defined entry triggers rather than waiting for manual market-hour fills
- Add SPY weekly close to EOD snapshots as a manual benchmark anchor (Gemini cannot resolve current dates reliably)
- Cap research-only sessions at 3 in a row — by session 4 with no fill, force a "why am I not in?" review

### Overall Grade: B-
Disciplined cash preservation in an event-heavy short week, but zero execution and no staged orders means we earned no information about our own trading edge. Pass on this week; next week must produce a real trade or a real decision-not-to.

---

## Week ending 2026-06-12

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $100,000.00 (Mon Jun 8 AM equity) |
| Ending portfolio | $100,000.00 |
| Week return | $0.00 (0.00%) |
| S&P 500 week | N/A (Gemini date-bound; manual SPY anchor pending) |
| Bot vs S&P | N/A |
| Trades | 0 (W:0 / L:0 / open:0) |
| Win rate | N/A (no closed trades) |
| Best trade | N/A |
| Worst trade | N/A |
| Profit factor | N/A |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| - | - | - | - | - |
| — | — | — | — | No trades this week |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop |
| - | - | - | - | - |
| — | — | — | — | None — 100% cash |

### What Worked
- Correctly avoided HOT CPI (Wed +4.2% YoY, highest since Apr 2023) — sat on hands instead of chasing pre-print
- Avoided ORCL AI-infra contagion fade on Thu (cloud miss + $40B raise spooked tape)
- Did not chase SpaceX Friday IPO debut ($1.78T mcap) — pure whipsaw skipped
- Identified clean sector rotation map: Materials (+22% YTD), Energy (+34.5%), Healthcare, Industrials leading; Tech/Utilities/REITs lagging
- VIX regime read accurate: spiked 22.22 on CPI day, drained to 19.44 by Fri — confirmed event-bid pattern

### What Didn't Work
- **Zero trades for the 2nd consecutive week** — 0/3 budget burned with no fills despite multiple A-list watchlist names (NVDA, FCX, XLE, XLI, XLV) named across 4 research sessions
- No staged limit orders again — every single day defaulted to "HOLD, observe at 10:00 ET" with nothing to fire if criteria met
- Watchlist names rotated daily (NVDA → FCX → XOM → XLI) without anchoring to a single thesis through the week — research without conviction commitment
- S&P benchmark still missing — Gemini can't resolve current dates, and we have not implemented the SPY-bars fallback flagged last week
- Every day had a fresh "tomorrow" excuse (CPI, PPI, ECB, UMich, SpaceX, Iran weekend) — patience is becoming permanent paralysis

### Key Lessons
- Two flat weeks = the screen is filtering for perfection, not edge. A+ setup criteria are too narrow OR the strategy doesn't account for high-VIX event-clustered weeks
- "Patience > activity" is a rule, but missing a clean breakout in a leading sector is ALSO a strategy violation — discipline cuts both ways
- Research log identifying YTD leaders (Energy +34.5%, Materials +22%) for 4 straight days without taking starter exposure = idea generation failure, not execution failure
- Event calendars will ALWAYS have a "tomorrow" — if we wait for clean tape we will never deploy capital
- Friday into binary geopolitical weekend (Iran deal) is genuinely a defensible no-trade day; the other 4 days were not

### Adjustments for Next Week
- **MANDATORY first-fill trigger by Wed close**: if any of FCX / XLI / XLV / FCX-peer (NEM, FCX, SCCO) holds above its Mon premarket low at 10:30 ET, take a starter 12-15% notional with 10% trailing stop GTC. No further research-only sessions allowed Mon-Wed.
- **Stage limit orders BEFORE market open** at pre-defined entry triggers — eliminate the "I'll watch at 10:00 ET" pattern that has now produced 0 fills in 8 sessions
- **Add manual SPY weekly close snapshot** to every Friday EOD — capture last trade price via `bash scripts/alpaca.sh quote SPY` and log to TRADE-LOG. This is our benchmark anchor since Gemini cannot resolve current dates
- **Define "A+" more concretely**: above 20-DMA + sector in YTD top-5 + no earnings within 5 days + ATR-adjusted stop fits 7% rule. If no name meets, lower bar to A: drop the 20-DMA requirement
- **Cap research-only streak at 3 sessions**: today (Fri) is session 4 with no fill — this triggers a forced "why am I not in?" review at Monday open. We failed to honor this trigger from last week's review.

### Overall Grade: C-
Cash preservation through a stagflationary, event-heavy week is real — HOT CPI Wed and ORCL-driven tech fade Thu were correctly avoided. But two consecutive zero-trade weeks with multiple identified leaders (Energy +34.5%, Materials +22%) is a strategy execution failure, not patience. We are gathering zero data on our own edge. Next week MUST produce a fill or a documented A+ rejection on a name we'd actually buy.
