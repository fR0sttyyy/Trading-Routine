# Cloud Routine Prompts

Paste each file verbatim into its Claude Code cloud routine. Do not paraphrase.

## Cron Schedules (America/Chicago)
| Routine | File | Cron |
|---------|------|------|
| Pre-market | pre-market.md | `0 6 * * 1-5` |
| Market-open | market-open.md | `30 8 * * 1-5` |
| Midday | midday.md | `0 12 * * 1-5` |
| Daily summary | daily-summary.md | `0 15 * * 1-5` |
| Weekly review | weekly-review.md | `0 16 * * 5` |

## Setup Checklist (per routine)
1. Routines → New Routine
2. Select repo, branch: main
3. Add all env vars (see env.template)
4. Toggle ON "Allow unrestricted branch pushes"
5. Set cron + timezone
6. Paste prompt verbatim
7. Save → Run now to test
