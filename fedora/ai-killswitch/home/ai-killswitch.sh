#!/usr/bin/bash
# AI kill switch: stop all Claude Code and Codex processes of this user,
# and all commands that they started.
#
#   ~/ai-killswitch.sh            stop them
#   ~/ai-killswitch.sh --dry-run  only list what would be stopped

dry=0
[[ $1 == --dry-run || $1 == -n ]] && dry=1

# 1. Find the agent processes.
mapfile -t roots < <(
    ps -u "$(id -u)" -o pid=,comm=,args= | awk '
        $2 == "claude" || $2 == "codex" || $2 ~ /^codex-/ { print $1; next }
        /@openai\/codex|@anthropic-ai\/claude-code/        { print $1 }'
)

# 2. Add all processes that they started (children, grandchildren, ...).
declare -A seen
queue=("${roots[@]}")
while ((${#queue[@]})); do
    pid=${queue[0]}
    queue=("${queue[@]:1}")
    [[ -n ${seen[$pid]} ]] && continue
    seen[$pid]=1
    mapfile -t kids < <(pgrep -P "$pid")
    queue+=("${kids[@]}")
done

# Never stop this script or the shell that started it.
unset "seen[$$]" "seen[$PPID]"

pids=("${!seen[@]}")
if ((${#pids[@]} == 0)); then
    echo "No Claude Code or Codex processes are running."
    exit 0
fi

echo "Processes found: ${#pids[@]}"
ps -o pid=,comm=,args= -p "$(IFS=,; echo "${pids[*]}")" | cut -c1-110

if ((dry)); then
    echo "Dry run: nothing was stopped."
    exit 0
fi

# 3. Ask them to stop. After 2 seconds, force the ones that are left.
kill -TERM "${pids[@]}" 2>/dev/null
sleep 2
left=()
for pid in "${pids[@]}"; do
    kill -0 "$pid" 2>/dev/null && left+=("$pid")
done
((${#left[@]})) && kill -KILL "${left[@]}" 2>/dev/null

echo "Stopped ${#pids[@]} processes (${#left[@]} needed force)."
