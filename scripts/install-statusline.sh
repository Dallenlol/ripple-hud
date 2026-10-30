#!/bin/bash
# Installs the Ripple HUD statusline: copies the renderer to a stable path and
# points ~/.claude/settings.json at it. Refuses to overwrite a different
# statusline unless --force is given.
#
# Cross-platform: on macOS/Linux the copied script is invoked directly (shebang).
# On Windows, Claude Code runs the statusLine command through cmd, which cannot
# execute a bare .sh — so we wrap it in the Git Bash executable that is running
# this installer.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$HOME/.claude/ripple-hud"
SETTINGS="$HOME/.claude/settings.json"
TARGET="$DATA/statusline.sh"

mkdir -p "$DATA"
cp -f "$ROOT/statusline/statusline.sh" "$TARGET"
chmod +x "$TARGET"

# On Windows, resolve the running bash to a Windows-style path so the command
# works when Claude Code launches it via cmd. Empty on macOS/Linux.
BASH_EXE=""
if [ "${OS:-}" = "Windows_NT" ]; then
  for cand in "$(command -v bash).exe" "$(command -v bash)"; do
    if [ -f "$cand" ]; then
      BASH_EXE="$(cygpath -m "$cand" 2>/dev/null || echo "$cand")"
      break
    fi
  done
fi

FORCE="${1:-}" TARGET="$TARGET" SETTINGS="$SETTINGS" BASH_EXE="$BASH_EXE" python3 - <<'PY'
import json, os, sys

# Windows consoles default to cp1252 and can't encode this script's arrows; force
# UTF-8 so the success/notice messages don't crash the installer.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

settings_path = os.environ["SETTINGS"]
target = os.environ["TARGET"]
bash_exe = os.environ.get("BASH_EXE", "").strip()
force = os.environ.get("FORCE") == "--force"

# Build the command Claude Code will run. Windows needs the bash wrapper; other
# platforms execute the shebang'd script directly.
tgt = target.replace("\\", "/")
if os.name == "nt" and bash_exe:
    command = f'"{bash_exe}" "{tgt}"'
else:
    command = target

settings = {}
if os.path.exists(settings_path):
    settings = json.load(open(settings_path))

existing = settings.get("statusLine", {}).get("command", "")
# Treat it as "ours" if the installed script path already appears in the command.
if existing and tgt not in existing.replace("\\", "/") and not force:
    print(f"A different statusline is configured:\n  {existing}\n"
          f"Re-run with --force to replace it, or keep your current one — "
          f"the fable renderer stays available at {tgt}")
    sys.exit(0)

# refreshInterval re-runs the renderer on a timer so the in-flight prompt clock and
# current-tool segment keep ticking during long tool calls (event updates go quiet then).
settings["statusLine"] = {"type": "command", "command": command, "refreshInterval": 2}
if os.path.exists(settings_path):
    import shutil
    shutil.copy2(settings_path, settings_path + ".bak")
tmp = settings_path + ".tmp"
json.dump(settings, open(tmp, "w"), indent=2)
os.replace(tmp, settings_path)
print(f"Ripple HUD statusline installed -> {command}\n"
      f"Restart Claude Code (or start a new session) to see it.")
PY
