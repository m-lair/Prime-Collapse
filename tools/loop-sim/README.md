# Headless gameplay-loop simulator

Validates Prime Collapse's core loop by playing **100 games** against the *real* engine — no Xcode,
no iOS simulator, no signing. It compiles the actual engine source files in place
(`GameState`, `Upgrade`, `UpgradeManager`, `EventManager`, `GameEvent`) together with the driver, so
the simulation can never drift from shipping behavior.

```bash
bash tools/loop-sim/run.sh
```

Runs in ~30s and writes:

- `docs/simulation/loop-validation-report.md` — endings, pacing, per-archetype tables, event/choice frequencies, transcripts
- `docs/simulation/loop-validation-data.json` — raw per-game records
- `docs/simulation/loop-analysis.md` — hand-written findings & recommendations (not regenerated)

## What it models

| File | Role |
|---|---|
| `LoopSim.swift` | 5 player archetypes (greedy / ethical / balanced / idle / random) × 2 start scenarios (fresh install vs post-`reset()`), the per-second tick loop, telemetry, and report rendering |
| `main.swift` | Entry point; silences the engine's hot-path `print()`s during the run and writes the artifacts |
| `Shims.swift` | Standalone copy of the `GameEnding` enum (declared in a SwiftUI file we don't compile here) — keep in sync |
| `run.sh` | `swiftc` build of the real engine + driver, then run |

It drives the same methods the SwiftUI layer does (`processAutomation`, `shipPackage`,
`getCurrentUpgradeCost` + `applyUpgrade`, `eventTriggerChance` + `processChoice`). The time model
advances a synthetic clock 1s per tick (automation integrates identically) and rolls events 10×/s to
match the real 0.1s cadence.

### Player model caps (and why)

The archetypes cap purchases (8/decision, 40 per repeatable) and skip Hire Worker at the 150 cap.
These keep the model human-realistic **and** keep the engine away from two real bugs the sim surfaced:
the repeatable-pricing runaway and the unguarded `totalPackagesShipped` overflow. See
`docs/simulation/loop-analysis.md`.

> Requires `EventManager.allEventsForTesting` (a `#if DEBUG` read-only catalog accessor) and builds with `-D DEBUG`.
