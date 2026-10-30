---
description: Toggle the fable state loop — a project memory file that replaces long chat history (on | off | status)
---

Toggle the fable-mode state loop: **$ARGUMENTS**

- If the argument is `on`: run `mkdir -p ~/.claude/ripple-hud && touch ~/.claude/ripple-hud/state-loop`, then immediately create or update `.fable-state.md` in the project root (goal, key decisions with reasons, what's done, what's next, key file paths — the simplest form that lets a fresh session continue perfectly). Confirm with a one-line explanation of the workflow: the file is maintained at the end of every substantive turn; the user can `/clear` whenever the context meter runs hot, and the next session resumes from the file automatically. Suggest adding `.fable-state.md` to `.gitignore` if this is a shared repo.
- If the argument is `off`: run `rm -f ~/.claude/ripple-hud/state-loop`, confirm in one line. Leave any existing `.fable-state.md` in place.
- Anything else (or empty): report whether `~/.claude/ripple-hud/state-loop` exists and whether `.fable-state.md` exists in this project, then list the valid options (`on | off`).
