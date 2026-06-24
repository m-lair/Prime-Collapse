# Prime Collapse — Gameplay Loop Analysis

Hand-written analysis of the 100-game simulation in
[`loop-validation-report.md`](loop-validation-report.md) (raw per-game data in
[`loop-validation-data.json`](loop-validation-data.json)). The simulation drives the **real**
engine (`GameState`, `UpgradeManager`, `EventManager`) headless via
[`tools/loop-sim`](../../tools/loop-sim/) — 5 player archetypes × 2 start scenarios × 10 runs.
Numbers below are from one representative run; the engine uses unseeded `Double.random`, so
exact values drift run-to-run but the conclusions are stable.

## The core loop

`tap / automate → earn money → buy upgrades (each carries a moral/perception/environment cost) →
random events force ethical choices → ethics score drifts → ending`.

Ethics score (0–100, starts 100) is the spine. Upgrades and event choices push it up or down;
**collapse** fires the instant it hits 0. Two "good" outcomes (Reform, Loop) are defined but,
as shipped, are effectively decorative (see Finding 1).

## What the 100 games showed

| Outcome | Count |
|---|---|
| collapse | 53 |
| reformFlagOnly (reform criteria met, game kept running) | 21 |
| loopFlagOnly | 0 |
| stagnated | 0 |
| survivedToTimeout | 26 |

- **Reform criteria met: 30/100. Loop criteria met: 0/100.**
- Fresh-install median idle income at 60s: **$0.021/s**. First idle income: **55s (fresh) vs 1s (restarted)**.
- Lifetime earnings, balanced strategy: **$96K fresh vs $2.5M restarted** (~26×). Ethical: **$10.7K vs $75K** (~7×).

## Findings (ranked)

### P0 — correctness / crashes

1. **Reform & Loop endings never actually end the game.** `showEndingScreen` is set in exactly one
   place — the collapse alert's "Continue" button (`ContentView.swift:208`). Reaching Reform (30/100 games)
   or Loop only sets `endingType`; the game keeps running and the player never sees a win screen. The two
   "win" `GameEndingView` branches are reachable only from SwiftUI previews.

2. **Loop ending is mathematically unreachable in practice (0/100).** It requires
   `ethicsScore ∈ [15,25]` **and** `money ≥ 2500` **and** `packages ≥ 1500` **and** `workers ≥ 3`
   *simultaneously*, but nothing holds ethics in that 10-point band — it sweeps through on the way to
   collapse faster than the economic thresholds line up. Never triggered once.

3. **Repeatable-upgrade pricing is broken → unbounded buy exploit.** `validateGameState()` de-dupes
   `purchasedUpgradeIDs`, but repeatable cost scaling (`getCurrentUpgradeCost`) is derived from the count
   of that array. Result: after the de-dup, repeatables like **Performance Bonuses** and **Carbon Offset**
   stop getting more expensive, so a cash-rich player can buy them hundreds of times. Every transcript with
   money to spare shows Performance-Bonuses spam.

4. **`processAutomation` can crash with an integer-overflow trap.** Finding 3's runaway pumps
   `workerEfficiency` exponentially; `totalPackagesShipped += packagesShipped` is **not** overflow-guarded
   (only the `Int(packageAccumulator)` conversion and the money setter are). Left uncapped, the simulator
   reproduced a **SIGTRAP** crash. The fix is a saturating add / clamp on `totalPackagesShipped`.

5. **Fresh installs ship with a dead idle loop.** A brand-new game never calls `reset()`, so it keeps
   `GameState()` defaults: `workers = 0`, `baseWorkerRate = 0.0`. Hiring workers then produces **$0/s**
   (`baseWorkerRate · workers = 0`). The only thing that sets a worker rate outside `reset()` is buying
   *Optimize Logistics* (`+0.02`). Net: median fresh idle income at 60s is **$0.021/s** vs a functional
   `0.1`/worker after a restart — a ~26× early-economy gap purely from start-state seeding.
   (`SavedGameState` even defaults `baseWorkerRate = 0.1`, so the inconsistency is already latent.)

### P1 — economy / fairness

6. **Displayed price ≠ charged price.** `getCurrentUpgradeCost` (what the UI shows) applies a
   public-perception modifier and a worker-specific curve; `applyUpgrade` charges a *different* value
   (`UpgradeManager.calculatePrice`, no perception modifier). The number on the button isn't what leaves
   the wallet.

7. **Worker cap is a money sink.** At 150 workers, buying another still deducts cash, then
   `validateGameState` strips the extra worker on the next tick (the "Excessive worker count (151)…"
   churn). The player pays for nothing instead of the buy being blocked.

### P2 — feel / pacing / polish

8. **Idle income is too weak for an idle game.** The `idle` archetype survives to timeout but earns the
   least of any strategy (~$3–4K lifetime, ~3K packages). Passive play barely advances.
9. **`validateGameState()` logs on the hot path.** It runs on every `getCurrentUpgradeCost` call and
   `print()`s "DATA INTEGRITY: …", flooding the console during normal play. Gate behind a debug flag.
10. **Event mix is skewed.** *Market Boom* (267) and *Competitor Undercuts Prices* (266) dominate because
    their triggers are loose (just packages shipped), while crisis events (*Hostile Takeover* 15,
    *Systemic Crisis* 7) rarely fire behind high money gates. More variety earlier would help.

## Key events & choices (the levers that steer the ending)

**Toward collapse** (most-picked dark choices across all games):
`Tax Audit → Hide questionable deductions` (194), `Natural Disaster → Use disaster to lay off workers`
(145), `Social Media Backlash → Issue PR statement without changes` (145),
`Workplace Safety Incident → Cover it up` (107), `Worker Unrest → Ignore complaints` (90). The fastest
collapse upgrades are *Worker Replacement System* (−30 moral), *Algorithmic Wage Suppression* (−25),
*Child Labor Loopholes* (−20).

**Toward reform** (positive levers): `Environmental Inspection → Full compliance` (+8),
`Labor Law Changes → Implement full compliance` (+7), `Charity Partnership → Fully sponsor` (+8), plus the
*Sustainable Practices* (+8) and *Community Investment* (+12) upgrades. Reform needs 5 positive choices +
ethics ≥ 50 + $1000 — readily achievable (30/100), it just doesn't *do* anything yet (Finding 1).

## Recommended fixes (in order)

1. Guard `totalPackagesShipped += packagesShipped` against overflow (clamp/saturate). *(crash)*
2. Fix repeatable pricing so cost scales with true purchase count (track counts separately from the
   de-duped `purchasedUpgradeIDs`). *(exploit)*
3. Seed a fresh install via `reset()` (or set `baseWorkerRate = 0.1`, 1 worker, seed *Hire Worker*) when no
   save exists. *(dead new-player loop)*
4. Make Reform/Loop trigger the ending screen (or a deliberate prestige state) instead of only collapse.
5. Re-tune the Loop window so it can actually be hit (latch when ethics first enters 15–25 with prereqs met,
   or hold ethics in-band).
6. Reconcile displayed vs charged upgrade price.
7. Block worker purchases at the 150 cap instead of charging then stripping.
8. Strengthen passive/idle income; move `validateGameState` logging off the hot path; broaden early event triggers.

## Reproducing

```bash
bash tools/loop-sim/run.sh      # compiles the real engine headless, runs 100 games (~30s), writes this folder
```
