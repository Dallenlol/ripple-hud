---
description: Pin or clear the fable-mode intensity level (lite | full | deep | auto)
---

Set the fable-mode intensity level to: **$ARGUMENTS**

- If the argument is `lite`, `full`, or `deep`: run `mkdir -p ~/.claude/ripple-hud && echo <level> > ~/.claude/ripple-hud/level`, then confirm in one line and apply that level immediately for the rest of this session.
- If the argument is `auto`, `clear`, or empty: run `rm -f ~/.claude/ripple-hud/level`, confirm that auto-routing is active, and resume classifying each task yourself.
- Anything else: reply with the valid options (`lite | full | deep | auto`) and change nothing.
