#!/usr/bin/env bash
set -euo pipefail

# ---- Configuration (can be overridden by env vars) ----
DISK_WARN_PERCENT="${DISK_WARN_PERCENT:-80}"
LOAD_WARN="${LOAD_WARN:-2.0}"

now() {
  date "+%Y-%m-%d %H:%M:%S %z"
}

status=0

echo "=== SYSTEM SNAPSHOT ==="
echo "time: $(now)"
echo "host: $(hostname)"
echo "user: $(whoami)"
echo

echo "--- uptime ---"
uptime
echo

echo "--- load average ---"
load_avg=$(awk '{print $1}' /proc/loadavg)
echo "load: $load_avg"
echo

awk -v l="$load_avg" -v w="$LOAD_WARN" 'BEGIN { exit (l > w) ? 1 : 0 }' || {
  echo "WARNING: load average $load_avg > $LOAD_WARN"
  status=1
}


echo "--- os ---"
cat /etc/os-release
echo

echo "--- disk ---"
df -h
echo

disk_used=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

if [ "$disk_used" -ge "$DISK_WARN_PERCENT" ]; then
  echo "WARNING: disk usage is ${disk_used}% (>= ${DISK_WARN_PERCENT}%)"
  status=1
fi


echo "--- memory ---"
free -h
echo

echo "--- top cpu processes ---"
ps aux --sort=-%cpu | head -n 6

if [ "$status" -eq 0 ]; then
  echo "STATUS: OK"
else
  echo "STATUS: WARNING"
fi

exit "$status"

