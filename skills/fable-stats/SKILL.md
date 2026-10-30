---
name: fable-stats
description: Summarize the token usage fable-mode has logged across sessions — totals, per-session breakdown, recent trend. Use when the user asks about token usage, spend, stats, or savings from fable-mode.
---

# fable-mode stats

fable-mode's Stop hook logs one JSON line per session to `~/.claude/ripple-hud/stats.jsonl`. Fields: `session`, `ts` (unix), `turns`, `out` (output tokens), `in` (fresh input tokens), `cache_read`, `cache_create`.

Summarize it with:

```bash
python3 - <<'PY'
import json, os, time
path = os.path.expanduser("~/.claude/ripple-hud/stats.jsonl")
if not os.path.exists(path):
    print("no stats logged yet"); raise SystemExit
rows = [json.loads(l) for l in open(path) if l.strip()]
tot = {k: sum(r.get(k, 0) for r in rows) for k in ("turns", "out", "in", "cache_read")}
print(f"sessions: {len(rows)} | turns: {tot['turns']} | output tokens: {tot['out']:,} | fresh input: {tot['in']:,} | cache reads: {tot['cache_read']:,}")
print(f"estimated output tokens saved vs unassisted: ~{int(tot['out'] * 0.37):,} (rough — scaled from the published easy-tier benchmark ratio, evals/RESULTS.md)")
for r in rows[-10:]:
    print(f"{time.strftime('%m-%d %H:%M', time.localtime(r.get('ts', 0)))}  turns={r['turns']:<3} out={r['out']:>8,}  in={r['in']:>9,}  cache={r['cache_read']:>11,}")
PY
```

Rows may also carry a `viol` dict (discipline violations detected per session: `reread_after_edit`, `repeat_reads`, `write_over_edit`, `no_verification`). If any are non-zero across recent sessions, add one line naming the worst habit and its trend.

Report the totals and the recent-session table, then one sentence of interpretation (e.g., rising cache-read share means long sessions — suggest `/clear` between unrelated tasks). Don't estimate dollar costs unless the user provides their pricing. All data is local; nothing is transmitted anywhere.
