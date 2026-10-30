#!/bin/bash
# Self-test for the Ripple HUD limit forecast and slowdown plan.
# Runs statusline.sh (or statusline.ps1 with `ps1`) against a throwaway HOME with
# fake transcripts and limit samples.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" = ps1 ]; then HUD=(pwsh -NoProfile -File "$DIR/statusline.ps1"); else HUD=(bash "$DIR/statusline.sh"); fi
fail=0

# fixture <home> <samples-json-or-empty>: three sessions burning in the last 30 min
fixture() {
  python3 - "$1" "$2" <<'PY'
import json, os, sys, time
from datetime import datetime, timezone
home, samples = sys.argv[1], sys.argv[2]
now = time.time()
iso = lambda t: datetime.fromtimestamp(t, timezone.utc).isoformat().replace("+00:00", "Z")
proj = f"{home}/.claude/projects"
os.makedirs(f"{home}/.claude/fable-mode", exist_ok=True)
if samples:
    open(f"{home}/.claude/fable-mode/limit-samples.json", "w").write(samples)

def write(path, cwd, model, n, ctx, prompted, sidechain=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        if prompted:
            f.write(json.dumps({"type": "user", "timestamp": iso(now - 900), "cwd": cwd,
                                "message": {"role": "user", "content": "do the thing"}}) + "\n")
        for i in range(n):
            u = {"input_tokens": 1000, "cache_creation_input_tokens": 4000,
                 "cache_read_input_tokens": ctx - 5000, "output_tokens": 2000}
            f.write(json.dumps({"type": "assistant", "timestamp": iso(now - 800 + i), "cwd": cwd,
                                "isSidechain": sidechain,
                                "message": {"id": f"{path}-{i}", "model": model, "usage": u}}) + "\n")

write(f"{proj}/-p-Setmo/aaaa1111.jsonl", "/p/Setmo", "claude-opus-5-5", 40, 300_000, True)
write(f"{proj}/-p-Setmo/aaaa1111/subagents/agent-x.jsonl", "/p/Setmo", "claude-sonnet-5-5", 10, 40_000, False, True)
write(f"{proj}/-p-hermes/bbbb2222.jsonl", "/p/hermes", "claude-sonnet-5-5", 20, 50_000, False)
write(f"{proj}/-p-fable-mode/cccc3333.jsonl", "/p/fable-mode", "claude-opus-5-5", 10, 80_000, True)
PY
}

# run <home> <five_hour pct> <resets in s> -> plain-text HUD
run() {
  local now; now=$(date +%s)
  printf '{"session_id":"cccc3333","transcript_path":"%s","model":{"display_name":"Opus"},"workspace":{"current_dir":"%s"},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%s},"seven_day":{"used_percentage":20,"resets_at":%s}}}' \
    "$1/.claude/projects/-p-fable-mode/cccc3333.jsonl" "$1" "$2" $((now + $3)) $((now + 5 * 86400)) |
    HOME="$1" "${HUD[@]}" | sed $'s/\x1b\\[[0-9;]*m//g'
}

check() {  # check <name> <output> <grep -E pattern> [absent]
  if printf '%s' "$2" | grep -qE "$3"; then [ "${4:-}" = absent ] && { echo "FAIL $1: found /$3/"; fail=1; }
  else [ "${4:-}" != absent ] && { echo "FAIL $1: missing /$3/"; fail=1; }; fi
}

now=$(date +%s)

# 1. at risk: 45% -> 60% over the last ~32 min = 28.4%/h, 2h left -> full ~35m early
h=$(mktemp -d)
fixture "$h" "{\"five_hour\":{\"resets\":$((now + 7200)),\"s\":[[$((now - 1900)),45]]}}"
out=$(run "$h" 60 7200)
echo "--- at risk"; echo "$out"
check risk "$out" "5h .* 60% ⚠ full ~[0-9:]+, 3[45]m[0-9]+s before ↻"
check risk "$out" "slow down 28\.[0-9]→20\.0%/h \(−30%\)"
check risk "$out" "Setmo [0-9]+% /compact"
check risk "$out" "7d" absent
python3 -c "import json,sys; s=json.load(open(sys.argv[1]))['five_hour']['s']; assert len(s)==2 and s[-1][1]==60, s" \
  "$h/.claude/fable-mode/limit-samples.json" || { echo "FAIL risk: sample not recorded"; fail=1; }

# 2. on pace: 58% -> 60% in ~32 min = 3.8%/h, 2h left -> ~32% spare, no plan
h=$(mktemp -d)
fixture "$h" "{\"five_hour\":{\"resets\":$((now + 7200)),\"s\":[[$((now - 1900)),58]]}}"
out=$(run "$h" 60 7200)
echo "--- on pace"; echo "$out"
check pace "$out" "~3[12]% spare at ↻"
check pace "$out" "slow down" absent

# 3. no samples yet: window average (30% in the first ~1h) -> full ~1h41m early
h=$(mktemp -d)
fixture "$h" ""
out=$(run "$h" 30 14430)
echo "--- window-average fallback"; echo "$out"
check fallback "$out" "⚠ full ~[0-9:]+, 1h41m before ↻"
check fallback "$out" "slow down 30\.[0-9]→17\.5%/h \(−42%\)"
check fallback "$out" "Setmo [0-9]+% /compact  ·  [a-z-]+(\(this\))? [0-9]+% "

# 4. stale samples from the previous window are dropped
h=$(mktemp -d)
fixture "$h" "{\"five_hour\":{\"resets\":$((now - 3600)),\"s\":[[$((now - 1900)),95]]}}"
out=$(run "$h" 30 14430)
check reset "$out" "1h41m before"

[ $fail = 0 ] && echo "PASS" || exit 1
