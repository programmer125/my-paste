#!/bin/zsh

set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
    echo "Usage: $0 <process-name|pid> [duration-seconds] [interval-seconds]" >&2
    exit 64
fi

target="$1"
typeset -i duration="${2:-30}"
typeset -i interval="${3:-1}"
typeset -i elapsed=0

if [[ "$target" == <-> ]]; then
    pid="$target"
else
    pid="$(pgrep -x "$target" | head -n 1)"
fi

if [[ -z "${pid:-}" ]]; then
    echo "Process not found: $target" >&2
    exit 1
fi

echo "timestamp,pid,cpu_percent,rss_kb"
while (( elapsed <= duration )); do
    metrics="$(ps -o %cpu=,rss= -p "$pid" | awk '{$1=$1; print $1 "," $2}')"
    if [[ -z "$metrics" ]]; then
        echo "Process exited before sampling completed." >&2
        exit 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S'),$pid,$metrics"
    sleep "$interval"
    (( elapsed += interval ))
done
