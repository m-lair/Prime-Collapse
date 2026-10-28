# Ending correctness validation — 2026-10-27

Reform now counts lifetime earnings for the current run, which reset on a new company.
Loop uses the same earnings concept, 1,500 packages, three workers, and ethics 15–25 for
60 foreground seconds. The policy constants are shared with UI requirements.
Leaving the eligibility band or dropping below three workers resets stability. Terminal
state freezes shipping, automation, upgrades and event choices; collapse takes precedence
when evaluating an ongoing run.

The initial targeted XCTest run demonstrated three failures before the repair: spending
prevented Reform, the exact 60-second window did not finish, and a stale Loop window
finished after ethics left the band. The repaired focused ending suites passed 32 tests (P0RegressionTests, GameSnapshotTests,
and GameStateClampTests), including
backward-compatible snapshots, restored banked reward guards, foreground catch-up exclusion,
terminal action freezing and the Worker Unrest alternative's real production tradeoff.
The deterministic catalog routes also run in the headless simulator, including terminal
snapshot restore and duplicate-award prevention for all three endings.

The regenerated 120-run report is descriptive. It adds a deterministic deliberate Loop
strategy; its 20 runs completed Loop, and all 20 ethical-script runs completed Reform.
Random archetypes remain unseeded and the distribution is not a desired product balance.
Authored route assertions deliver eligible catalog choices directly; they do not validate
random event timing or human engagement.

Persistence uses optional new fields so older schema-1 JSON remains readable. Ending state,
loop seconds and the per-run banked flag round-trip. Prestige totals still live in the
existing separate PrestigeStore: the two atomic file writes are not a single transaction.
A process termination between prestige banking and the following game snapshot write remains
a crash-consistency limitation. UI integration must bank then capture the terminal snapshot.
Lifecycle baseline resets are a caller contract for the UI integration; the model excludes
background time when those callbacks are supplied, with a conservative two-second
maximum foreground tick gap as fallback. No device or TestFlight behavior is established here.
