# Holiday Rush management playthrough — October 28, 2026

## Result

Completed a fresh, unaccelerated UI-only agent run: **778 / 1,500 packages in 720 active seconds**, final ethics **53**, morale **57%**, six workers. Deadline failure; workforce requirements were met. All three authored decisions completed. Exactly **120 manual shipment button actions** were issued, in bursts early in the run; none after the final burst at about 145 active seconds. This is about 10 actions per active minute averaged over the run, not a sustained cadence or a validated human input profile.

Environment: isolated iPhone 17 Pro Max / iOS 26.5 simulator `Prime Holiday Manager Playtest`, ID `431FAD3F-155D-47ED-8933-00027218D051`. Local simulator build **1.3 (1)** from the gameplay revision delivered in `aa5e230`; this was not a test of the signed TestFlight binary **1.3 (4)**. The device and app data were fresh. No existing player save was reset. No feedback response was selected, exported to anyone, or counted as demand.

## Method

Policy: prioritize automatic production, stay above the workforce thresholds, and limit manual shipping to 120 actions. Select purchases from visible descriptions and affordability; do not consult source or hidden state during play. Prior implementation knowledge remains a bias. Tool calls and observation/analysis consumed active time; reaction latency and purchase delays are not representative measurements of human play.

The first risk-taking choice was followed by a workforce-recovery choice; the final risk was chosen after checking that its displayed penalties would leave both requirements above 40. This is a mixed route, not the previously scripted all-constructive winning recipe. The tap cap and purchase delays constrain the outcome, so this is not evidence that all lower-input strategies are impossible or that 1,500 is intrinsically unfair.

## Recorded timeline

Purchase times below are action timestamps in UTC. Active-time checkpoints come from observed countdowns; action processing can add a few seconds.

| UTC | Action / observation | Visible state where captured |
| --- | --- | --- |
| 13:20:08 | Start fresh challenge | 3 workers, $150 |
| 13:20:21 | Hire fourth worker, $104.86 | Worker count changed to 4 |
| 13:20:40 | First 20 manual shipments | 30 packages; 692 seconds left; $74 |
| 13:20:45 | Optimize Logistics, $60 | Purchased card disappeared; no numeric production preview |
| 13:21:16 | Return to HUD from shopping | 47 packages; 655 seconds left; $30 |
| 13:21:33 | 50 shipment actions total | 86 packages; 638 seconds left; $69 |
| 13:21:51 | Improve Packaging, $75, after reaching 60 manual actions | 101 packages / $84 observed before purchase |
| 13:22:05 | 80 shipment actions total | 133 packages; 605 seconds left; $45 |
| 13:22:13 | First decision checkpoint | 136 packages; 600 seconds left; $47; ethics100/morale80% |
| 13:22:27 | Demand faster shifts | Free; ethics −22, morale −18%, efficiency +30%; observed ethics78/morale62% |
| 13:22:56 | Final 40 shipments; 120 total | 196 packages; 575 seconds left; $113 |
| 13:24:01 | No additional manual inputs | 245 packages; 509 seconds left; $167 |
| 13:24:56 | Saving for sorting | 286 packages; 455 seconds left; $212 |
| 13:25:00 | Automate Sorting, $200 | Ethics fell from78 to75; card removed |
| 13:25:42 | Second decision checkpoint | 311 packages; 420 seconds left; $40 |
| 13:26:02 | Protect rest breaks | Paid overtime $65 unavailable; free choice restored morale62→72%, ethics75→80, efficiency −10% |
| 13:27:06 | Passive production | 352 packages; 359 seconds left; $84 |
| 13:28:25 | Saving for worker | 405 packages; 279 seconds left; $142 |
| 13:28:31 | Hire fifth worker, $134.22 | Worker count changed to5 |
| 13:29:13 | Final decision checkpoint | 436 packages; 240 seconds left; $42; ethics80/morale72% |
| 13:29:24 | Skip safety checks | Paid $95 unavailable; free risk predicted and produced ethics50/morale47%, efficiency +50% |
| 13:30:25 | Late production | 506 packages; 181 seconds left; $118 |
| 13:30:32 | Basic Training, $100 | Observed ethics53/morale57% afterward |
| 13:31:45 | Passive production | 618 packages; 101 seconds left; $141 |
| 13:32:22 | Saving for worker | 671 packages; 64 seconds left; $199 |
| 13:32:27 | Hire sixth worker, $171.80 | Worker count changed to6 |
| 13:33:30 | Terminal screen observed | 778 packages; 720 active seconds; ethics53/morale57% |

## Findings

| Finding | Evidence | Classification / next check |
| --- | --- | --- |
| Upgrade value is hard to compare | Logistics, Packaging, Sorting and Training descriptions describe improvements but do not quantify added production or payback; no production-rate readout in the challenge HUD | Verified UI observation; usability risk. Show current output and measurable upgrade deltas, then test whether decisions become easier to explain |
| Shopping separates decisions from the budget/timer | Buying/browsing scrolls the HUD out of view on the phone; returning to the top was necessary to inspect progress | Verified layout observation; usability risk. Consider a compact persistent budget/time/output summary |
| Spending can remove the next paid workforce option | Sorting purchase left $40 at the second decision; overtime needed$65. Production pauses, so waiting cannot earn the missing$25 | Intended-rule interaction, not a defect. Test whether reserve costs should be forecast before decisions |
| This lower-input strategy missed the volume target badly | Final778/1500, short722 packages; 51.9% of goal with120 manual actions and several investments | Observed balance outcome for this policy only. Compare controlled input and upgrade policies before tuning goal/timer |
| Outcome feedback gives little guidance for retry | Result shows packages, active time and workforce values plus generic “Try another balance…” text; no spending/production breakdown or specific next-attempt insight | Verified content observation; usability/replay risk. Explain the limiting condition and summarize throughput/investment history without prescribing one winning solution |
| Choices communicate immediate workforce consequences clearly | First, second and final choices produced displayed ethics/morale deltas; unavailable paid choices explicitly said “Not enough cash” | Positive functional observation; does not prove all economy effects or accessibility |

No verified crash, stuck state or incorrect terminal outcome occurred in this run. No code or balance changes were made from these findings.

## Interpretation and next experiment

The game offers a management objective but insufficient quantitative feedback to assess investments. That is the strongest actionable expert finding from this run. The input dependency and sorting payback remain hypotheses: several purchases, varying morale/efficiency and tool delays confound a causal comparison.

Next controlled experiment: hold an explicit purchase/decision policy fixed and vary manual shipping cadence, recording actual action count and economy deltas with the production engine. Separately compare worker-first and automation-first plans. Do not turn the previous scripted win or this UI loss into a human success-rate claim. Human fun, comfort and willingness to replay remain unmeasured.

Evidence: [result screenshot](holiday-rush-evidence/manager-playtest/result.png), [result and final snapshot](holiday-rush-evidence/manager-playtest/result.json), plus early and halfway captures in the same directory. The saved game snapshot was read only after the terminal result; it did not inform gameplay choices.
