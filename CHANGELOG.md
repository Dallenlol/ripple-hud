# Changelog

## v2.0.0 — 2026-10-29

- **Renamed to Ripple HUD**: the plugin is now `ripple-hud` (marketplace `ripple-hud-marketplace`, repo `Dallenlol/ripple-hud`, commands `/ripple-hud:…`). The Fable operating style keeps its names: the `fable-mode` skill, `fable-level`, `fable-state`, `.fable-state.md`, `fable on/off`. **Breaking for existing installs**: run `/plugin marketplace add Dallenlol/ripple-hud`, `/plugin install ripple-hud@ripple-hud-marketplace`, then `/plugin uninstall fable-mode@fable-mode-marketplace`. The data folder moves from `~/.claude/fable-mode` to `~/.claude/ripple-hud` on the first session start; a symlink stays at the old path, so an existing `statusLine` setting keeps working. On Windows, where Git Bash may copy instead of linking, rerun `install-statusline.ps1`.

## v1.8.4 — 2026-10-29

- **Ripple HUD limit forecast** (bash edition): the 5h/7d meters now say when the window fills versus when it resets (`⚠ full ~15:40, 1h00m before ↻16:40`), or the headroom you'll have left at reset (`~22% spare at ↻16:40`, shown from 50%). The 5h rate uses the last ~30 min of usage, from samples every HUD on the machine shares in `limit-samples.json`; until there are enough samples, and for the 7d window, it averages over the window so far. When a window is at risk, a third line shows the target burn rate and the cut needed, plus the cheapest fixes for this machine's busiest sessions over the last 30 min: `/compact` for big contexts, `→sonnet`, or pause, with `pause bg` for sessions nobody has prompted. Per-session cost is cached 60 s in `burn-cache.json`. New `statusline/test-statusline.sh` self-test. The PowerShell edition still shows the old `⚠ full` warning.

## v1.8.3 — 2026-10-20

- **PowerShell Ripple HUD at parity**: `statusline.ps1` now renders the same calm HUD as the bash edition — prompt timer and estimate (sharing `eta-cache.json` with bash), current tool, threshold-only spend/cache/tokens-left/7-day/reset segments, `⚠ full` burn warning, dirty-file count, thin meters. Still Windows PowerShell 5.1 compatible and pure-ASCII source. `install-statusline.ps1` gains an opt-in `-RefreshInterval N`; it stays off by default because each refresh spawns PowerShell (~0.4–0.6 s CPU) versus ~60 ms for bash.

## v1.8.2 — 2026-10-20

- **Calmer Ripple HUD**: thin `━` meters, `·` separators, no `out`/lines-changed/duration clutter, short tool labels (`▸ Bash npm`) so line 2 no longer truncates. Spend rate, cache rate, tokens-left, the 7-day meter and reset times now appear only when they cross a threshold.

## v1.8.1 — 2026-10-20

- **Statusline renamed to Ripple HUD**: the HUD label now reads `◈ Ripple HUD` (bash and PowerShell). The plugin itself is still `fable-mode`; nothing to reinstall.

## v1.8.0 — 2026-10-20

- **One data folder**: the hooks and `fable-stats` now use `~/.claude/fable-mode/` — the same folder the statusline and the level/state commands use — instead of `$CLAUDE_PLUGIN_DATA`, so the HUD's output-token count and level pin are actually visible. Stats logged by older versions are migrated on the next session end.
- **Statusline: live prompt segment** (bash edition): while a prompt runs, shows elapsed time, an estimated time remaining from the median of recent prompt durations (this session first, then recent sessions in the same project, cached 10 min in `eta-cache.json`; scaled by a pinned level) and the tool in progress with a parallel-call count. Also adds spend rate ($/min), prompt-cache hit rate (native `prompt_cache`, transcript fallback), a projected `⚠ full` warning on the 5h/7d limit meters, an uncommitted-file count beside the branch, and a highlighted `deep` level. The installer now sets `refreshInterval: 2`. (PowerShell renderer caught up in v1.8.3.)
- **Statusline works on native Windows without Git Bash**: added a pure-PowerShell renderer (`statusline/statusline.ps1`) and installer (`scripts/install-statusline.ps1`) — no bash or python3 needed. The installer edits only the `statusLine` key in `settings.json` (surgical string edit, since PowerShell 5.1's `ConvertTo-Json` corrupts the hooks' single-element arrays).
- **Statusline portability fixes** (bash edition): force UTF-8 stdout so the emoji/box HUD renders on Windows cp1252 consoles instead of falling back to bare `fable`; the installer now wraps the script in the Git Bash exe on Windows (Claude Code launches statusLine via cmd, which can't run a bare `.sh`) and no longer crashes on its own success message. `.gitattributes` pins `*.sh` to LF so CRLF shebangs never reach Unix checkouts.

## v1.7.0 — 2026-07-07

- **The closed loop**: the Stop hook now detects discipline violations from each session's transcript (re-reads after edits, repeated whole-file reads, Write-instead-of-Edit rewrites, edits shipped without verification) and the next session start injects one targeted corrective for the worst recurring habit. All local, one line of context cost, per-machine adaptive.
- **Marathon tier expanded to three tasks** (`marathon-config`: inverted env precedence; `marathon-defaults`: shared-mutable-default leak) at n=2 per condition on Sonnet: 12/12 pass, fable-mode −35% report length, −14% turns, −8% output tokens. Haiku fable-condition record now 9/9 all-time.
- Grading self-test extended to all marathon tasks (20 checks).

## v1.6.1 — 2026-07-07

- **Breakpoint clearing policy**: the state loop now suggests `/clear` at natural task boundaries (task complete + context above ~40%) instead of on a raw percentage timer, stays quiet mid-task below ~85%, and never right after a turn the user may want to tweak — clearing too often costs more than it saves (cache-rebuild tax). Statusline shows a `⟳ clear-worthy` chip when a breakpoint is available.
- **Provider-neutral skill wording**: subagent and compaction references now degrade gracefully on harnesses without those features — the AGENTS.md export works unchanged on Claude, GPT, Gemini, or local models.
- Regression benchmark on the reworded skill: **Haiku 7/7** (first perfect sweep, marathon task included).

## v1.6.0 — 2026-07-07

- **State loop** (`/fable-mode:fable-state on`): the model maintains a `.fable-state.md` project memory file at the end of every substantive turn; `/clear` whenever the context meter runs hot and the next session auto-resumes from the file — continuation context in ~2k tokens instead of the full chat history. Toggleable, off by default; statusline shows a `✎ state` indicator.
- **Marathon eval tier**: a 12-file orders-service fixture with a cross-file root cause (float truncation in the one shared money module), measuring the reading-discipline and root-cause behaviors that only show up beyond toy tasks.
- **Prompt-variant testing**: `evals/run.py --skill-file` A/Bs alternate SKILL.md versions — prompt changes are now measured, not guessed.
- **claude.ai one-step install**: releases ship a prebuilt `fable-mode-skill.zip` asset.
- `/fable-stats` now includes an estimated-savings line (clearly labeled as an estimate, derived from published benchmark ratios).
- README visuals (statusline HUD, benchmark chart), CONTRIBUTING.md, issue templates, Windows notes.

## v1.5.2 — 2026-07-07

Full production review pass: bulleted choose-step for small-model instruction-following, judgment-call flagging on ambiguous specs, model column + crash-safe eval runner (timeouts no longer lose results), settings.json backup on statusline install, `FABLE_CTX_LIMIT` honored again, three-way benchmark documented — and its results published: **Sonnet + fable-mode matched Fable 5 on all 6 graded outcomes at $2.88 vs $10.71 (73% cheaper).**

## v1.5.1 — 2026-07-07

Eight more craftsman rules: the one-line rung, edge-case-correct choices between equal options, deletion over addition, edit over create, no re-arguing when the user insists, YAGNI for tests, "skipped X — add when Y" reporting, requested-explanation-is-never-debt.

## v1.5.0 — 2026-07-07

Plan usage-limit meters in the statusline (5h/7d, yellow at 50%), INSTALL.md setup guide, the **Fable** persona (displayName, `fable off` escape hatch), sharper craftsman mechanics (rung zero, `fable:` ceiling comments, ship-and-offer, anti-drift clause).

## v1.4.0 — 2026-07-07

Statusline HUD (context meter, session tokens, cost, level) and the `/fable-level` pin command.

## v1.3.0 — 2026-07-07

Auto-routed intensity levels (lite/full/deep), local token stats + `/fable-stats`, AGENTS.md export, the reproducible eval harness with grading self-test, CI.

## v1.2.0 — 2026-07-07

Initial public release: the Fable operating loop, difficulty routing with the hard-problem protocol, token discipline, SessionStart injection, repo-as-marketplace packaging.
