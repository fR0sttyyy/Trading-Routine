# Trading Bot

An autonomous AI trading agent built on Claude Code. Runs on a daily cron schedule, places real trades on Alpaca, researches via Gemini, and notifies via ClickUp.

**Strategy:** Swing trading — stocks only, no options, ever.

---

## How It Works

Five cloud routines fire each weekday. Each one spins up a fresh Claude Code container, clones this repo, reads memory, acts, writes memory back, commits, and pushes. Claude is the bot — there is no separate process.

| Routine | Time (CT) | What It Does |
|---------|-----------|--------------|
| Pre-market | 6:00 AM | Research catalysts, write trade ideas |
| Market-open | 8:30 AM | Execute planned trades, set trailing stops |
| Midday | 12:00 PM | Cut losers, tighten stops on winners |
| Daily summary | 3:00 PM | Snapshot portfolio, send ClickUp recap |
| Weekly review | 4:00 PM Fri | Grade the week, update strategy if needed |

---

## Strategy Rules (non-negotiable)

- No options. Ever. Stocks only.
- Max 5–6 open positions at a time
- Max 20% of equity per position
- Max 3 new trades per week
- 10% trailing stop on every position as a real GTC order
- Cut losers at −7% from entry
- Tighten trail to 7% at +15%, to 5% at +20%
- Exit a sector after 2 consecutive failed trades
- Patience beats activity

---

## Repository Layout

```
trading-bot/
├── CLAUDE.md                  # Agent rulebook — auto-loaded every session
├── README.md                  # This file
├── env.template               # Copy to .env for local use
├── .gitignore                 # Excludes .env
├── .claude/
│   └── commands/              # Ad-hoc slash commands for local use
│       ├── portfolio.md
│       ├── trade.md
│       ├── pre-market.md
│       ├── market-open.md
│       ├── midday.md
│       ├── daily-summary.md
│       └── weekly-review.md
├── routines/                  # Cloud routine prompts (production)
│   ├── README.md
│   ├── pre-market.md
│   ├── market-open.md
│   ├── midday.md
│   ├── daily-summary.md
│   └── weekly-review.md
├── scripts/                   # API wrappers — the only way to touch external APIs
│   ├── alpaca.sh
│   ├── gemini.sh
│   └── clickup.sh
└── memory/                    # Agent's persistent state — committed to main
    ├── TRADING-STRATEGY.md
    ├── TRADE-LOG.md
    ├── RESEARCH-LOG.md
    ├── WEEKLY-REVIEW.md
    └── PROJECT-CONTEXT.md
```

---

## Prerequisites

- [Alpaca](https://alpaca.markets) account (paper trading to start)
- [Gemini API](https://www.gemini.ai) key
- [ClickUp](https://clickup.com) account with a Chat channel for notifications
- Claude Code with access to cloud routines

---

## Local Setup

```bash
# 1. Clone the repo
git clone https://github.com/fR0sttyyy/Trading-Routine.git
cd Trading-Routine

# 2. Copy env template and fill in your credentials
cp env.template .env
# Edit .env with your Alpaca, Gemini, and ClickUp keys

# 3. Smoke test — should print your Alpaca account cleanly
# Open repo in Claude Code, then run:
/portfolio
```

---

## Cloud Routine Setup

Do this once per routine (repeat for all five):

1. Claude Code cloud → **Routines → New Routine**
2. Select this repo, branch: `main`
3. Add all env vars from `env.template` directly in the routine config — **do NOT commit a `.env` file**
4. Toggle **"Allow unrestricted branch pushes"** ON — without this, `git push` silently fails
5. Set the cron schedule and timezone (see table above, cron strings in `routines/README.md`)
6. Paste the prompt from `routines/<name>.md` **verbatim** — do not paraphrase
7. Save → **Run now** to verify before relying on the schedule

---

## Memory Model

All state lives in `memory/` as markdown files committed to `main`. No database, no external state store.

| File | Purpose | Updated |
|------|---------|---------|
| `TRADING-STRATEGY.md` | The rulebook | Friday if a rule changes |
| `TRADE-LOG.md` | Every trade + daily EOD snapshot | Every trade, every EOD |
| `RESEARCH-LOG.md` | One entry per day | Pre-market daily |
| `WEEKLY-REVIEW.md` | Friday recaps with letter grade | Weekly |
| `PROJECT-CONTEXT.md` | Static background and mission | Rarely |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Clone fails / "repository not accessible" | Install the Claude GitHub App on this repo |
| `git push` fails with proxy/permission error | Enable "Allow unrestricted branch pushes" on the routine |
| API key not found in cloud | Add it to the routine's env vars — not to `.env` |
| ClickUp message missing | One of the three `CLICKUP_*` vars is unset |
| Yesterday's trades missing | Previous run didn't commit+push — check `git log origin/main` |

---

## Ad-hoc Commands (local only)

Run these inside Claude Code with your local `.env` loaded:

| Command | Description |
|---------|-------------|
| `/portfolio` | Read-only account + positions snapshot |
| `/trade SYMBOL SHARES buy\|sell` | Manual trade with full rule validation |
| `/pre-market` | Run pre-market research manually |
| `/market-open` | Run market-open execution manually |
| `/midday` | Run midday scan manually |
| `/daily-summary` | Run daily summary manually |
| `/weekly-review` | Run weekly review manually |
