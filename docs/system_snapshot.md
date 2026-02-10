# system_snapshot.sh

Collects a quick Linux system snapshot for troubleshooting and automation.

## Run

```bash
docker compose run --rm ops ./src/system_snapshot.sh

## Exit codes
- `0` — OK
- `1` — Warning (threshold exceeded)

## Configuration
Thresholds can be overridden via environment variables:

```bash
DISK_WARN_PERCENT=90 LOAD_WARN=4.0 docker compose run --rm ops ./src/system_snapshot.sh

