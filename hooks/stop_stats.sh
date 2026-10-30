#!/bin/bash
# Logs per-session token usage AND discipline violations to the plugin data dir.
# Local only — nothing leaves the machine. Fires on Stop; upserts one JSON line
# per session in stats.jsonl. Always exits 0, prints nothing.
#
# Violations detected from the transcript (the closed loop — session_start.sh
# injects a one-line corrective for the worst recurring habit):
#   reread_after_edit  - Read of a file right after editing it
#   repeat_reads       - same file Read 3+ times in one session
#   write_over_edit    - full-file Write to a file that already existed (was Read first)
#   no_verification    - session edited files but never ran a command afterward
set -u

INPUT="$(cat)"
. "$(dirname "$0")/data_dir.sh"
mkdir -p "$DATA_DIR" 2>/dev/null || exit 0
# Migrate stats logged by <=1.7 into the plugin data dir.
OLD="${CLAUDE_PLUGIN_DATA:-}/stats.jsonl"
if [ -n "${CLAUDE_PLUGIN_DATA:-}" ] && [ -f "$OLD" ] && [ "$OLD" != "$DATA_DIR/stats.jsonl" ]; then
  cat "$OLD" >> "$DATA_DIR/stats.jsonl" && rm -f "$OLD"
fi

HOOK_INPUT="$INPUT" STATS_FILE="$DATA_DIR/stats.jsonl" python3 - <<'PY' 2>/dev/null || true
import json, os, time

inp = json.loads(os.environ["HOOK_INPUT"])
tp, sid = inp.get("transcript_path"), inp.get("session_id", "unknown")
if not tp or not os.path.exists(tp):
    raise SystemExit

tot = {"turns": 0, "out": 0, "in": 0, "cache_read": 0, "cache_create": 0}
viol = {"reread_after_edit": 0, "repeat_reads": 0, "write_over_edit": 0, "no_verification": 0}
edited, read_counts, read_seen = set(), {}, set()
last_edit_idx, last_cmd_idx, idx = -1, -1, 0

# fable: full-file parse; cap at the last 8MB so a monster transcript can't slow the UI hook
size = os.path.getsize(tp)
with open(tp, "rb") as fh:
    fh.seek(max(0, size - 8 * 1024 * 1024))
    lines = fh.read().decode("utf-8", "ignore").splitlines()

for line in lines:
    try:
        rec = json.loads(line)
    except Exception:
        continue
    if rec.get("type") != "assistant":
        continue
    msg = rec.get("message") or {}
    u = msg.get("usage") or {}
    if u:
        tot["turns"] += 1
        tot["out"] += u.get("output_tokens", 0)
        tot["in"] += u.get("input_tokens", 0)
        tot["cache_read"] += u.get("cache_read_input_tokens", 0)
        tot["cache_create"] += u.get("cache_creation_input_tokens", 0)
    for c in msg.get("content") or []:
        if not (isinstance(c, dict) and c.get("type") == "tool_use"):
            continue
        idx += 1
        name, args = c.get("name", ""), c.get("input") or {}
        path = args.get("file_path", "")
        if name == "Read" and path:
            if path in edited:
                viol["reread_after_edit"] += 1
            read_counts[path] = read_counts.get(path, 0) + 1
            if read_counts[path] == 3:
                viol["repeat_reads"] += 1
            read_seen.add(path)
        elif name in ("Edit", "NotebookEdit") and path:
            edited.add(path)
            last_edit_idx = idx
        elif name == "Write" and path:
            if path in read_seen:
                viol["write_over_edit"] += 1
            edited.add(path)
            last_edit_idx = idx
        elif name == "Bash":
            last_cmd_idx = idx
        if name == "Read" and path in edited and read_counts.get(path, 0) > 0:
            pass
    # a successful re-read concern only applies until the file is edited again; keep simple

if last_edit_idx > 0 and last_cmd_idx < last_edit_idx:
    viol["no_verification"] = 1

sf = os.environ["STATS_FILE"]
# fable: read-modify-write race between concurrent sessions can drop one line for
# one turn; it self-heals on the next Stop. Add file locking if that ever matters.
rows = []
if os.path.exists(sf):
    for line in open(sf):
        try:
            if json.loads(line).get("session") != sid:
                rows.append(line.rstrip("\n"))
        except Exception:
            pass
rows.append(json.dumps({"session": sid, "ts": int(time.time()), **tot, "viol": viol}))
tmp = sf + ".tmp"
with open(tmp, "w") as fh:
    fh.write("\n".join(rows) + "\n")
os.replace(tmp, sf)
PY
exit 0
