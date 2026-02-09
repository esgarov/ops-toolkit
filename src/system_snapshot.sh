#!/usr/bin/env bash
set -euo pipefail

now() {
  date "+%Y-%m-%d %H:%M:%S %z"
}

echo "=== SYSTEM SNAPSHOT ==="
echo "time: $(now)"
echo "host: $(hostname)"
echo "user: $(whoami)"
echo

echo "--- uptime ---"
uptime
echo

echo "--- os ---"
cat /etc/os-release
echo

echo "--- disk ---"
df -h
echo

echo "--- memory ---"
free -h
echo

echo "--- top cpu processes ---"
ps aux --sort=-%cpu | head -n 6

