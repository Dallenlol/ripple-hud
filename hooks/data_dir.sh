# Sourced by the hooks: the one data dir shared with the statusline and the
# level/state commands. Moves pre-2.0 data out of ~/.claude/fable-mode and leaves
# a symlink there so a statusLine command still pointing at the old path works.
DATA_DIR="$HOME/.claude/ripple-hud"
OLD_DATA_DIR="$HOME/.claude/fable-mode"
if [ -d "$OLD_DATA_DIR" ] && [ ! -L "$OLD_DATA_DIR" ] && [ ! -e "$DATA_DIR" ]; then
  mv "$OLD_DATA_DIR" "$DATA_DIR" 2>/dev/null && ln -s "$DATA_DIR" "$OLD_DATA_DIR" 2>/dev/null || true
fi
