# ⚡ Ripple HUD

**Make any Claude model work like a frontier model — Fable 5's judgment, workflow, and token discipline as a Claude Code plugin** (`ripple-hud`, formerly `fable-mode`; the operating style itself is still the `fable-mode` skill).

**Fable is a persona**: the frontier model's work ethic, installed on whatever model you can afford. It reads less, writes less, verifies more — and it stays in character for the whole session (`fable off` to release it).

*Claude Code plugin · reduces token usage and API cost on Haiku, Sonnet, and Opus · benchmarked against the frontier model with the harness included · exports to Cursor, Codex, Zed, and any AGENTS.md-aware agent on any model provider.*

![Same graded outcomes at a quarter of the cost](assets/benchmark.svg)

**→ [Full setup guide](INSTALL.md)** · [Benchmark results](evals/RESULTS.md) · [Portable AGENTS.md](AGENTS.md) · [Changelog](CHANGELOG.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-orange)](https://code.claude.com/docs/en/plugins)
[![Release](https://img.shields.io/github/v/release/Dallenlol/ripple-hud)](https://github.com/Dallenlol/ripple-hud/releases)

Frontier models don't win by writing more — they win by judgment: reading only what matters, fixing root causes instead of symptoms, attacking their own answers before trusting them, and saying what happened in one sentence instead of five paragraphs. `fable-mode` distills that operating style from Claude Fable 5 into a ~1,500-token behavioral layer that loads automatically at the start of every Claude Code session, so cheaper models (Opus, Sonnet, Haiku) work the same way — and spend dramatically fewer tokens doing it.

Honest framing up front: this is a behavioral layer, not a model swap. It can't add raw capability — what it does is close the *process* gaps that separate models in practice: first-plausible-path commitment, unverified answers, bloated context, and padded output.

## Quick start

```
/plugin marketplace add Dallenlol/ripple-hud
/plugin install ripple-hud@ripple-hud-marketplace
```

That's it. The operating style injects automatically on session start, resume, `/clear`, and after compaction. Pick any model (`/model opus`, `/model sonnet`) and work normally. To re-assert it manually mid-session: `/ripple-hud:fable-mode`.

## Intensity levels — auto by default

You don't have to classify anything. fable-mode silently routes every task to one of three levels:

| Level | When (auto-detected) | What runs |
|---|---|---|
| **lite** | Trivial asks: quick questions, one-line edits, renames | Direct answer/edit — no ceremony, because the ceremony would cost more than the task |
| **full** | Real work: features, fixes, refactors, reviews | The complete operating loop (triage → understand → choose → execute → verify → report) |
| **deep** | Hard reasoning or high stakes: novel algorithms, subtle correctness, security/money — or a first approach that just failed | The loop **plus** the hard-problem protocol: invariants first, competing approaches, adversarial self-attack, executable checks, subagent cross-checks |

Misrouted tasks escalate immediately (lite → deep mid-task is encouraged; moving down is not). To pin a level, just say `fable level: lite` (or `full`/`deep`) in chat — or persist it across sessions:

```bash
mkdir -p ~/.claude/ripple-hud && echo deep > ~/.claude/ripple-hud/level
```

## What it does

**1. Runs every task through Fable 5's operating loop** — triage the ask (question vs. change request; define DONE first), understand before touching anything (trace the flow, every caller), choose the smallest correct approach (reuse > stdlib > dependency > new code; root cause over symptom), execute (parallel tool batching, targeted edits), verify (run the check that would fail if you were wrong), report (outcome in the first sentence).

**2. Routes hard problems into a deeper gear** — see the levels table above. Deep tokens go only where they buy correctness.

**3. Enforces token discipline that maps to real billing mechanics:**

| Rule | Why it saves tokens |
|---|---|
| Grep first, read line ranges, never whole files | Input tokens scale with relevance, not file size |
| Never re-read after an edit; never re-derive known facts | Kills the most common duplicated input spend |
| Targeted edits over full-file rewrites | Output cost scales with the diff, not the file |
| Delegate broad exploration to subagents, keep only conclusions | Main context stays small, so **every subsequent turn** is cheaper |
| Keep early context stable (prompt-cache hygiene) | Cache misses are the silent cost multiplier of long sessions |
| Outcome-first replies, `file:line` refs, no pasted code | Output tokens are the most expensive; this is pure savings |

The injected prompt itself costs ~1,500 tokens per session — it pays for itself in the first avoided file re-read.

## Built-in statusline: Ripple HUD

**Ripple HUD** is a two-line HUD at the bottom of your terminal — level, model, branch, state-loop indicator, session output tokens, cost, duration, lines changed, and the two meters that matter most at a glance: **context window** (with tokens remaining) and **your plan's usage limits** (5-hour and 7-day windows, native from Claude Code for Pro/Max subscribers):

![Ripple HUD statusline](assets/statusline.svg)

While a prompt is running, line 2 leads with a live segment: elapsed time, an **estimated time remaining** (`⏳ 1m12s ~2m left`, or `running long` once past it) and the tool in progress (`▸ Bash npm +2`, or `✻ thinking`). The estimate is the median of your recent prompt durations in this project (scaled when a level is pinned) — a guess from history, not real progress, since Claude Code doesn't report how far along a turn is. The HUD stays quiet until something needs attention: the spend rate appears only above $0.25/min, the cache hit rate only below 80% or when the cache goes cold, tokens-left only past 60% context, and the 7-day meter and reset times only past 50%. A yellow `●3` beside the branch counts uncommitted files. A pinned `deep` level is highlighted. The installer sets `refreshInterval: 2` so the clock keeps ticking during long tool calls.

Usage meters turn **yellow at 50%** and red at 80%, with the window's reset time next to them, and a red `⚠ full ~40m` when your current burn rate would exhaust the window before it resets — you know you're halfway through your quota the moment it happens, not when you hit the wall. The context meter turns yellow at 60% and red at 85%: your cue to `/clear` between unrelated tasks. Opt-in install (refuses to clobber an existing statusline without `--force`):

```bash
scripts/install-statusline.sh   # see INSTALL.md for the full walkthrough
```

The renderer is a single ~45ms script reading only local files. Pin levels on the fly with `/ripple-hud:fable-level lite|full|deep|auto`.

## The closed loop — it learns your model's bad habits

Static system prompts are open-loop: they say the same thing no matter what the model actually does. Fable closes the loop, entirely locally: the `Stop` hook reads each session's transcript and mechanically detects discipline violations — re-reading a file right after editing it, reading the same file three times, rewriting whole files where a targeted edit would do, ending a session of edits with no verification run. At the next session start, the hook injects **one** targeted corrective for the worst recurring habit:

> Habit check (from your recent sessions on this machine): you re-read files right after editing them 4 times — an edit succeeded unless the tool errored; never re-read to check your own work. Fix this today.

No telemetry, no cloud, no config — the transcripts never leave your machine, and the corrective is one line so it never bloats your context. Over sessions, the prompt stops being generic and starts being about *your* model's specific waste.

## The state loop — stop paying for your chat history

The single biggest token sink in long sessions is the conversation itself: every turn re-bills the entire history as input. The state loop replaces it with a project memory file:

```
/ripple-hud:fable-state on
```

From then on, Fable maintains `.fable-state.md` in your project root at the end of every substantive turn — goal, decisions with reasons, what's done, what's next, key files — rewritten for density, never appended. When the context meter runs hot, just `/clear`: the SessionStart hook injects the state file into the fresh session automatically, and work continues from ~2k tokens of curated context instead of 100k+ of raw history. It beats built-in compaction three ways: you control when, the model curates *what matters* rather than summarizing everything, and the file persists across sessions and is yours to read or edit. The statusline shows `✎ state` while the loop is active. `/ripple-hud:fable-state off` to stop.

## See what it saves you

fable-mode logs per-session token usage **locally** (nothing is transmitted anywhere): a `Stop` hook appends one JSON line per session to the plugin's data directory. Ask for your numbers any time:

```
/ripple-hud:fable-stats
```

You get totals and a recent-session breakdown — output tokens, fresh input, cache reads — straight from your own transcripts.

## Measured

The benchmark ships in this repo — [`evals/`](evals/) contains six graded tasks (root-cause instinct, triage discipline, reuse-over-reimplement, YAGNI, and two green-test-suite traps) and a stdlib-only runner that A/Bs them on your own account. Full tables in [`evals/RESULTS.md`](evals/RESULTS.md).

**The headline, measured with real CLI-reported costs:** on the full suite, **Sonnet + fable-mode matched Claude Fable 5 on every graded outcome — 6/6 vs 6/6 — at $2.88 vs $10.71, i.e. 73% cheaper than running the frontier model itself.**

![Marathon tier: fable-mode cuts report length 35%, turns 14%, output tokens 8% at identical pass rates](assets/chart-marathon.svg)

![Haiku easy tier: 57% shorter reports, 27% fewer output tokens and turns at identical pass rates](assets/chart-haiku.svg)

Every chart is generated from [`evals/published.json`](evals/published.json) by [`evals/render_charts.py`](evals/render_charts.py) — CI fails if the visuals drift from the published numbers. Further highlights from the 2026-07-07 suite:

- **Haiku 4.5, easy tier:** identical pass rates, **−27% output tokens, −27% turns, −57% report length** with fable-mode. On one task the control wandered for 15 turns; fable-mode landed the one-decorator answer in 7.
- **Opus 4.8:** 12/12 graded checks pass in both conditions — the deltas are in shape: fable-mode reports are 19% shorter overall with nothing graded missing.
- **Hard tier, both models:** fable-mode deliberately spends *more* (up to ~1.9×) — the deep gear buys invariant-checking and executable verification exactly where being wrong is expensive, funded by savings everywhere else. Both models, both conditions, found the green-suite trap bugs; in earlier manual A/Bs the fable arm additionally surfaced a spec ambiguity the control missed.

```bash
evals/run.py --runs 3 --model haiku   # reproduce on your own account
```

## Use it outside Claude Code

**claude.ai (web / desktop / mobile):** zip the `skills/fable-mode/` folder, then upload it at **Settings → Capabilities → Skills** (custom skills require a paid plan).

**Cursor, Codex, Zed, and any AGENTS.md-aware tool — on any model provider:** copy [`AGENTS.md`](AGENTS.md) into your repo root (or your tool's global instructions location). It's generated from the same skill and written harness-neutral, so it works whether the agent underneath is Claude, GPT, Gemini, or a local model — one source of truth, every harness, every provider.

## How it works

```
ripple-hud/
├── .claude-plugin/
│   ├── plugin.json           # plugin manifest
│   └── marketplace.json      # repo doubles as its own marketplace
├── hooks/
│   ├── hooks.json            # SessionStart → inject style · Stop → log stats
│   ├── session_start.sh      # strips frontmatter, prints the skill body
│   └── stop_stats.sh         # local per-session token log (no telemetry)
├── skills/
│   ├── fable-mode/SKILL.md   # the operating style — single source of truth
│   └── fable-stats/SKILL.md  # /ripple-hud:fable-stats usage reports
├── evals/                    # reproducible A/B benchmark (6 graded tasks)
├── scripts/build-agents-md.sh
└── AGENTS.md                 # generated portable export
```

No dependencies, no build step, no telemetry, nothing leaves your machine. CI validates manifests, hook scripts, skill frontmatter, and AGENTS.md sync on every push.

## What it is not

It won't make a small model derive novel mathematics like a frontier model, and it can't add knowledge the base model lacks. It also never trades away correctness for brevity: input validation, error handling, security, and verification are explicitly exempt from all token thrift. When brevity and correctness conflict, correctness wins — that rule is in the prompt.

## Local development

```
/plugin marketplace add /path/to/fable-mode
/plugin install ripple-hud@ripple-hud-marketplace
```

Edit `skills/fable-mode/SKILL.md`, run `scripts/build-agents-md.sh`, validate with `claude plugin validate .`, and run the evals before shipping prompt changes — that's the regression suite for the prompt.

## License

[MIT](LICENSE)
