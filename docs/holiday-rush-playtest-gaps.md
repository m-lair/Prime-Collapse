# Holiday Rush: stronger testing plan

October 28, 2026. Reassessment of existing evidence using `game-testing-playbook.md`. No additional gameplay or balance simulations were executed for this report.

## What the current evidence supports

The existing validation report establishes rule regressions, several reachable routes and native lifecycle/save/replay checks. It does not establish a forgiving learning curve, a useful variety of strategies, low-input viability or player enjoyment.

The scripted constructive route completed at 694 of 720 seconds: **26 seconds remaining, about 3.6% of the time budget**. This is a margin calculation for one route, not a player win rate or proof that the challenge is too hard. Its policy also used approximately one shipment action per active second; the exact input count should be logged before reporting it as measured.

The native low-tap run delivered 364 packages, while the scripted constructive route delivered 1,501. Different input and upgrade policies confound that comparison. It cannot isolate whether tapping, purchase timing, UI friction or another factor caused the gap.

## Priority experiments

| Question | Experiment | Decision enabled |
| --- | --- | --- |
| Does management matter more than continuous tapping? | Hold purchase/decision policy fixed; sweep 0, 0.25, 0.5 and 1 tap per active second | Whether input burden is central, optional or masking economy issues |
| Is there room for mistakes? | Baseline versus one delayed upgrade, one poor decision and one period of inattention | Whether intended challenge has a recoverable learning path |
| Are choices meaningfully different? | Compare mixed decision paths under the same resources and input budget | Whether constructive choices, cheaper choices and risk-taking create distinct viable plans |
| Can visible information support a useful plan? | Expert UI-only run without consulting the winning recipe; record predictions and source-knowledge leakage | Specific briefing, upgrade-description or feedback risks to test with humans |
| Does losing teach the next attempt? | Capture failure explanation, change one plan on retry, compare result | Whether the result communicates an actionable cause of failure |
| Can a lower-input player participate? | Low-input strategy search plus actual assistive-input walkthrough | Concrete access barriers; keep unperformed physical/VoiceOver checks explicit |

Do not tune package target, prices or timer from these hypotheses alone. Run comparable experiments first. Preserve original traces and report the exact build. Investigate whether paid constructive choices combine ethics, morale and throughput benefits so strongly that other options become uncompetitive; this is currently a hypothesis, not a confirmed dominant strategy.

## Run record

For each run record: build/commit, device or headless engine, source-informed or UI-only, starting state, controlled/uncontrolled randomness, input cadence and actual delivered actions, purchase sequence/timestamps, decision sequence, elapsed time, packages, money, ethics/morale minima, result, screenshot/trace, deviations and unknowns.

Report observations before explanations. Do not count agent feedback or replay actions as player demand. For human sessions record whether help was provided and whether replay was voluntary. The question “want more challenges?” measures stated interest; it does not establish willingness to pay.

## First human session

Let the player discover the challenge without prescribing the successful policy. Afterward ask what they thought the goal required, what caused the outcome, and what they would try next. Compare this with agent predictions. Keep human comments verbatim when supplied and separate them from interpretation.

Existing evidence: `holiday-rush-validation.md`, `holiday-rush-evidence/native-deadline-result.json`. Research and source links: `game-testing-playbook.md`.
