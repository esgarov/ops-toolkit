#!/usr/bin/env bash
set -euo pipefail

# system_snapshot.sh
# Collects a quick Linux system snapshot and performs basic threshold checks.
#
# Exit codes:
#   0 - OK
#   1 - WARNING (threshold exceeded)
#
# Usage:
#   ./src/system_snapshot.sh
#   ./src/system_snapshot.sh --json
#   DISK_WARN_PERCENT=90 LOAD_WARN=4.0 ./src/system_snapshot.sh

DISK_WARN_PERCENT="${DISK_WARN_PERCENT:-80}"
LOAD_WARN="${LOAD_WARN:-2.0}"

MODE="text"

usage() {
  cat <<'EOF'
system_snapshot.sh - Linux system snapshot + basic health checks

Usage:
  system_snapshot.sh [--json] [--help]

Options:
  --json   Print machine-readable JSON (single line)
  --help   Show this help

Environment variables:
  DISK_WARN_PERCENT   Disk usage warning threshold for / (default: 80)
  LOAD_WARN           1-min load average warning threshold (default: 2.0)

Exit codes:
  0 OK
  1 WARNING (threshold exceeded)
EOF
}

# ---- args ----
for arg in "$@"; do
  case "$arg" in
    --json) MODE="json" ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

now() { date "+%Y-%m-%d %H:%M:%S %z"; }

status=0

# ---- data collection ----
time_now="$(now)"
host="$(hostname)"
user="$(whoami)"
uptime_line="$(uptime)"
load_avg="$(awk '{print $1}' /proc/loadavg)"
os_pretty="$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")"

disk_used="$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')"
mem_total="$(free -m | awk '/^Mem:/ {print $2}')"
mem_used="$(free -m | awk '/^Mem:/ {print $3}')"
mem_free="$(free -m | awk '/^Mem:/ {print $4}')"

top_cpu="$(ps aux --sort=-%cpu | awk 'NR==1{print; next} NR<=6{print}')"

# ---- checks ----
disk_warning="false"
load_warning="false"

if [ "$disk_used" -ge "$DISK_WARN_PERCENT" ]; then
  disk_warning="true"
  status=1
fi

awk -v l="$load_avg" -v w="$LOAD_WARN" 'BEGIN { exit (l > w) ? 1 : 0 }' || {
  load_warning="true"
  status=1
}

overall_status="OK"
if [ "$status" -ne 0 ]; then
  overall_status="WARNING"
fi

# ---- output ----
if [ "$MODE" = "json" ]; then
  # minimal JSON escaping (sufficient for our values)
  esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

  printf '{'
  printf '"time":"%s",' "$(esc "$time_now")"
  printf '"host":"%s",' "$(esc "$host")"
  printf '"user":"%s",' "$(esc "$user")"
  printf '"os":"%s",' "$(esc "$os_pretty")"
  printf '"uptime":"%s",' "$(esc "$uptime_line")"
  printf '"load_avg":%s,' "$load_avg"
  printf '"disk_used_percent":%s,' "$disk_used"
  printf '"thresholds":{"disk_warn_percent":%s,"load_warn":%s},' "$DISK_WARN_PERCENT" "$LOAD_WARN"
  printf '"warnings":{"disk":%s,"load":%s},' "$disk_warning" "$load_warning"
  printf '"memory_mb":{"total":%s,"used":%s,"free":%s},' "$mem_total" "$mem_used" "$mem_free"
  printf '"status":"%s"' "$overall_status"
  printf '}\n'
else
  echo "=== SYSTEM SNAPSHOT ==="
  echo "time: $time_now"
  echo "host: $host"
  echo "user: $user"
  echo

  echo "--- uptime ---"
  echo "$uptime_line"
  echo

  echo "--- load average ---"
  echo "load: $load_avg"
  echo

  echo "--- os ---"
  cat /etc/os-release || true
  echo

  echo "--- disk ---"
  df -h
  if [ "$disk_warning" = "true" ]; then
    echo "WARNING: disk usage is ${disk_used}% (>= ${DISK_WARN_PERCENT}%)"
  fi
  echo

  echo "--- memory ---"
  free -h
  echo

  echo "--- top cpu processes ---"
  echo "$top_cpu"
  echo

  echo "STATUS: $overall_status"
fi

exit "$status"

