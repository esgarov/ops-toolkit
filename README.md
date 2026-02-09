# ops-toolkit

A lightweight toolkit for collecting system snapshots and performing basic host health checks.
Designed to run on Linux (Ubuntu). A Docker-based runtime is provided for consistent execution across systems.

## Quick start (Docker / Ubuntu)
```bash
docker compose run --rm ops ./src/system_snapshot.sh
