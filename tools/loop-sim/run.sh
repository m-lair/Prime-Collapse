#!/usr/bin/env bash
#
# Headless Prime Collapse gameplay-loop simulator.
#
# Compiles the REAL game engine source files in place (no copies, so the simulation can
# never drift from shipping behavior) together with the simulator driver, into a macOS
# command-line binary, then runs 100 games and writes docs/simulation/{report.md,data.json}.
#
# No Xcode, no iOS simulator, no code signing — builds and runs in seconds.
#
#   Usage:  bash tools/loop-sim/run.sh
#
set -euo pipefail

# Resolve repo root (two levels up from this script) and run from there so the engine
# paths and the docs/ output path are stable.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

ENGINE="Prime Collapse/Prime Collapse/Models"
BIN="${TMPDIR:-/tmp}/primecollapse-loopsim"

echo "Compiling headless simulator (real engine + driver)…"
swiftc \
  -D DEBUG \
  "$ENGINE/GameState.swift" \
  "$ENGINE/Upgrade.swift" \
  "$ENGINE/UpgradeManager.swift" \
  "$ENGINE/EventManager.swift" \
  "$ENGINE/GameEvent.swift" \
  "tools/loop-sim/Shims.swift" \
  "tools/loop-sim/LoopSim.swift" \
  "tools/loop-sim/main.swift" \
  -o "$BIN"

echo "Running 100 games…"
echo
"$BIN"
