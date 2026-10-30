# Fable — setup guide

Complete installation walkthrough for every platform Fable runs on. Total time: about two minutes.

## Prerequisites

- **Claude Code** (CLI or desktop app) — [install docs](https://code.claude.com/docs). Any recent version; the statusline's native usage meters need a build that exposes `context_window`/`rate_limits` (2026 builds do).
- **python3** on your PATH (ships with macOS; on Linux `apt install python3`) — used by the stats hook and statusline. The core skill works without it.
- A model to run it on: `/model opus`, `/model sonnet`, or `/model haiku`.

## 1. Install the plugin (Claude Code)

Inside any Claude Code session:

```
/plugin marketplace add Dallenlol/ripple-hud
/plugin install ripple-hud@ripple-hud-marketplace
```

Restart the session (or `/clear`). You should see `FABLE MODE ACTIVE` in the session context — that's the SessionStart hook injecting the operating style. It re-injects automatically on resume, `/clear`, and after compaction.

**Verify:** ask Claude "is fable mode active?" — or run `/ripple-hud:fable-mode` to re-assert it manually.

## 2. Statusline HUD (optional, recommended)

A two-line terminal HUD: level, model, branch, session output tokens, cost, duration — plus a context-window meter and your **plan usage limits** (5-hour and 7-day windows, shown for Pro/Max subscribers) that turn yellow at 50% and red at 80%:

```
◈ Ripple HUD  ·  Opus 4.8  ·  main ●3  ·  $4.12
⏳ 36s ~1m52s left   ▸ Bash npm +2  ·  ctx ━━━━━━━━ 58%  ·  5h ━━━━━━ 52% ↻03:26
```

Install it from a clone of this repo (the installer copies the renderer to a stable path, so you can delete the clone afterward).

**macOS / Linux / Git Bash / WSL** (bash + python3 renderer):

```bash
git clone https://github.com/Dallenlol/ripple-hud && ripple-hud/scripts/install-statusline.sh
```

**Native Windows without Git Bash** (pure-PowerShell renderer — needs no bash or python3):

```powershell
git clone https://github.com/Dallenlol/ripple-hud
powershell -NoProfile -ExecutionPolicy Bypass -File ripple-hud\scripts\install-statusline.ps1
```

Both write the same HUD; pick the one matching your shell. The bash installer sets `refreshInterval: 2` so the prompt timer ticks during long tool calls; the PowerShell one leaves it off (each refresh starts PowerShell, ~0.5 s of CPU) — opt in with `-RefreshInterval 5`. Each refuses to replace an existing statusline unless you pass `--force` (bash) / `-Force` (PowerShell). Uninstall by deleting the `statusLine` key from `~/.claude/settings.json`. Non-default context sizes: set `FABLE_CTX_LIMIT` (only used by the fallback path on older CLIs; new CLIs report window size natively).

## 3. Pin an intensity level (optional)

Fable auto-routes every task to lite / full / deep. To override:

```
/ripple-hud:fable-level deep     # pin (persists across sessions)
/ripple-hud:fable-level auto     # back to auto-routing
```

Or just say `fable level: lite` in chat for the current session.

## 4. Token stats

Usage is logged locally per session (no telemetry — nothing leaves your machine). Ask any time:

```
/ripple-hud:fable-stats
```

## 5. claude.ai (web / desktop / mobile — no Claude Code)

Hooks don't run on claude.ai, but the skill itself is portable:

1. Download this repo (green **Code** button → Download ZIP) and extract it.
2. Zip the `skills/fable-mode/` folder (the folder containing `SKILL.md`).
3. On claude.ai: **Settings → Capabilities → Skills** → upload the zip (custom skills require a paid plan).
4. Claude applies it automatically on matching tasks, or ask for "fable mode" explicitly.

## 6. Cursor / Codex / Zed / other agents

Copy [`AGENTS.md`](AGENTS.md) from this repo into your project root (or your tool's global instructions location). It's generated from the same skill — identical behavior, any harness.

## The state loop (optional)

`/ripple-hud:fable-state on` turns on the project memory loop: Fable maintains `.fable-state.md` in your project root every turn, and after any `/clear` the SessionStart hook re-injects it — so long projects continue from a ~2k-token state file instead of a six-figure chat history. Add `.fable-state.md` to `.gitignore` on shared repos. `off` to disable.

## Windows

The hooks are bash + python3: they work in **Git Bash / WSL**. The statusline HUD ships in two forms — the bash + python3 renderer (`install-statusline.sh`) and a pure-PowerShell renderer (`install-statusline.ps1`) that needs neither, for **native Windows without Git Bash**. The PowerShell installer edits only the `statusLine` key in `settings.json`, leaving everything else untouched. The skill itself (the operating style) is plain markdown and works everywhere Claude Code runs.

## Updating

```
/plugin update ripple-hud@ripple-hud-marketplace
```

The SessionStart hook auto-syncs your installed statusline copy on the next session.

## Uninstalling

```
/plugin uninstall ripple-hud@ripple-hud-marketplace
```

Then optionally remove `~/.claude/ripple-hud/` (stats + level pin) and the `statusLine` key in `~/.claude/settings.json`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No `FABLE MODE ACTIVE` in context | Run `/doctor` — check the plugin loaded; restart the session; confirm `hooks/session_start.sh` is executable |
| Statusline blank (bash) | Confirm `python3 --version` works; run it manually: `echo '{}' \| ~/.claude/ripple-hud/statusline.sh` |
| Statusline blank (Windows PowerShell) | Run it manually: `echo '{}' \| powershell -NoProfile -File $HOME\.claude\ripple-hud\statusline.ps1` — prints `fable` on valid-but-empty input |
| No 5h/7d usage meters | They appear only for Claude Pro/Max subscribers, after the first response in a session — API-key users have no rate-limit windows |
| `/fable-stats` says no stats | Stats appear after the first completed session with the plugin installed |
| Behavior drifts in long sessions | The style re-injects after compaction automatically; say "fable on" to re-assert instantly |
