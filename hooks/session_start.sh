#!/bin/bash
# Injects the fable-mode operating style into context at session start.
# Single source of truth is the skill file; strip its YAML frontmatter and print the body.
set -euo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/hooks/data_dir.sh"

echo "FABLE MODE ACTIVE — apply the following operating style for the entire session:"
awk 'f; /^---$/ { if (++c == 2) f = 1 }' "$ROOT/skills/fable-mode/SKILL.md"

# Keep the installed statusline copy in sync with the plugin version (no-op if not installed).
if [ -f "$DATA_DIR/statusline.sh" ] && [ -f "$ROOT/statusline/statusline.sh" ]; then
  cp -f "$ROOT/statusline/statusline.sh" "$DATA_DIR/statusline.sh" 2>/dev/null || true
  chmod +x "$DATA_DIR/statusline.sh" 2>/dev/null || true
fi

# Closed loop: inject ONE corrective for the worst recurring habit from the last
# few sessions (detected by stop_stats.sh from the transcripts, all local).
if [ -f "$DATA_DIR/stats.jsonl" ]; then
  CORRECTIVE="$(python3 - "$DATA_DIR/stats.jsonl" <<'PY' 2>/dev/null
import json, sys
rows = []
for line in open(sys.argv[1]):
    try:
        rows.append(json.loads(line))
    except Exception:
        pass
recent = rows[-3:]
agg = {}
for r in recent:
    for k, v in (r.get("viol") or {}).items():
        agg[k] = agg.get(k, 0) + v
msgs = {
    "reread_after_edit": "re-read files right after editing them {n} times — an edit succeeded unless the tool errored; never re-read to check your own work",
    "repeat_reads": "read the same file 3+ times in {n} sessions-worth of work — read the relevant range once and trust your context",
    "write_over_edit": "rewrote whole files with Write {n} times where a targeted edit would do — output cost scales with the diff, not the file",
    "no_verification": "ended {n} session(s) with edits but no verification run — always run the check that would fail if you were wrong",
}
best = max(((k, v) for k, v in agg.items() if v >= 2 or (k == "no_verification" and v >= 1)),
           key=lambda kv: kv[1], default=None)
if best:
    print(f"Habit check (from your recent sessions on this machine): you {msgs[best[0]].replace('{n}', str(best[1]))}. Fix this today.")
PY
)"
  [ -n "$CORRECTIVE" ] && { echo ""; echo "$CORRECTIVE"; }
fi

# Optional persistent level pin: echo lite|full|deep > "$DATA_DIR/level"
if [ -f "$DATA_DIR/level" ]; then
  LEVEL="$(tr -cd 'a-z' < "$DATA_DIR/level")"
  case "$LEVEL" in
    lite|full|deep) echo "" ; echo "User-pinned fable-mode level: $LEVEL — honor it until the user changes it." ;;
  esac
fi

# State loop (toggle: /ripple-hud:fable-state on|off). Injects the project memory
# file so a /clear'd session resumes from ~2k tokens instead of the full history.
if [ -f "$DATA_DIR/state-loop" ]; then
  echo ""
  if [ -f ".fable-state.md" ]; then
    echo "PROJECT STATE LOOP ACTIVE — .fable-state.md is your continuation context (the chat may have been cleared; trust this file):"
    echo '---'
    head -c 12000 .fable-state.md
    echo ""
    echo '---'
  else
    echo "PROJECT STATE LOOP ACTIVE — no .fable-state.md in this project yet; create it at the end of your first substantive turn."
  fi
  cat <<'RULES'
State-loop discipline: at the end of every substantive turn, create or update .fable-state.md in the project root — goal, key decisions with reasons, what's done, what's next, key file paths — in the simplest form that lets a fresh session continue perfectly. Rewrite for density rather than appending; keep it under ~150 lines.
Clearing policy — suggest at breakpoints, never on a timer: when a task just completed AND context is above ~40%, add one line: "Natural breakpoint — /clear when ready, .fable-state.md carries the thread." Mid-task, stay quiet below ~85%; above it, say "finish this step, then /clear." Never suggest clearing right after a turn the user may want to tweak. (Clearing too often costs more than it saves: cached history is cheap to re-read; rebuilding context after /clear is not.)
RULES
fi
