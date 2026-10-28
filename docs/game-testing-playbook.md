# Agent game-testing playbook

Research and operating protocol, October 28, 2026. Applies to Prime Collapse and future small games. This is a reusable testing procedure, not a claim that additional playthroughs have been performed.

## Start with the intended experience

Write down the audience, genre, session length, core loop, intended challenge and what the player should understand. Treat these as hypotheses until the designer confirms them. For Holiday Rush, the working hypothesis is a short management challenge about investment, throughput and workforce tradeoffs. Whether continuous tapping should be central is unresolved.

Use the MDA framework to connect rules, resulting behavior and intended experience. A working timer is a mechanics check; a timer that makes every upgrade too late is a dynamics problem; whether the pressure is enjoyable requires player evidence. MDA is an analytical lens, not a formula for fun. [1]

Maintain a small genre brief before each new game: core and progression loops, resource sources/sinks, feedback loops, player skill being tested, expected session rhythm, failure/recovery and plausible strategy families. Use comparable games only after actually observing their relevant behavior; familiarity with their names is not comparative playtesting.

## Separate evidence types

| Method | Can establish | Cannot establish alone |
| --- | --- | --- |
| Unit/invariant tests | Rule correctness, terminal ordering, reward/save invariants | Readability, input feel, enjoyment |
| Headless engine simulation | Strategy reachability, sensitivity, reproducible economy traces | What players discover or choose |
| UI-only agent play | Visible affordances, practical actions, route failures, feedback | A genuinely naive person's understanding or emotion |
| Expert game review | Evidence-backed risks and competing explanations | Population preferences or retention |
| Human playtest | Observed understanding, friction, reactions and voluntary behavior | Market-wide rates from a small convenience sample |

The implementing agent already knows the design. A UI-information-only pass limits decisions to visible information, but does not erase that knowledge. Call it an expert walkthrough, never a naive-user experiment. Agent-authored Yes/Maybe/No feedback is QA data and must never count as demand.

## Two passes with different information

1. **Experience pass:** Use only the briefing, visible UI and observed consequences to choose actions. Before acting, record what the UI suggests will happen. Do not consult source, debug values or a winning recipe during this pass. Record where knowledge of the implementation may have influenced a choice. Preserve the first run before retries.
2. **System pass:** Inspect rules and run controlled simulations to explain the observations. Search for exploits, unreachable outcomes, price cliffs, timing boundaries and uncompetitive strategies. Reproduce important predictions through the UI.

Do not weaken deliberate challenge just because an agent loses. Distinguish intended pressure from confusing feedback, input barriers and inconsistent rules. Hodent's game UX guidance emphasizes testing explanations against design intent rather than treating a complaint or an expert opinion as a diagnosis. [2]

## Explicit behavior profiles

These are test policies, not demographic models. Declare their limits before execution.

| Policy | Test question |
| --- | --- |
| UI-guided explorer | Can a plausible sequence based on visible descriptions make progress? |
| Deliberate manager | Can investment and timing produce a win with limited manual input? |
| Active tapper | How much does extra tapping change the outcome? |
| Low-input player | Does the game permit progress without sustained repetitive input? |
| Recovery run | Can one delayed purchase, missed opportunity or poor choice be recovered from? |
| Adversarial run | Can pause, repeat actions, reload, time changes or exact-boundary ordering bypass constraints? |

For an action game, substitute movement, aim, reaction and spatial-navigation policies. For puzzles, test rule discovery, valid alternate solutions and hint dependence. For management/incremental games, prioritize compounding income, investment timing, resource sinks and decision quality. Do not reuse one genre's checklist unchanged.

## Balance and economy experiments

- Record a baseline before tuning. Define the uncertain question and the smallest experiment that can distinguish explanations.
- Use the production engine and public actions. Inject a controlled clock/random seed where supported; do not imply deterministic replay if some randomness remains uncontrolled.
- Fix the policy and vary one factor first: input cadence, upgrade order, decision route, purchase delay or starting resources. Keep human-paced UI runs separate from accelerated simulations.
- For Holiday Rush, start with no manual taps, one per four active seconds, one per two seconds and one per second. These are experimental settings, not claims about normal users. Sweep mixed decision routes as well as all-care/all-balanced/all-fast.
- Track final packages, success conditions, time margin, total taps, money spent, first useful upgrade time, decision choices, resource minima and point of failure. A terminal screenshot alone cannot explain a run.
- Test a delayed purchase, one suboptimal choice and a short period of inattention. Report whether a failure remains recoverable with legal actions; distinguish a proven search result from a rough estimate.
- Check marginal value and payback time of upgrades using the actual changing rates. A simple cost / extra-income-rate estimate is only local; compounding and thresholds can invalidate it.
- Investigate dominant strategies: one option being better in every relevant outcome may make an apparent choice hollow. A single successful route does not prove dominance, nor do three route examples establish a balanced strategy space.
- Compare the same policy across relevant seeds and report denominator, distribution and failures. Repeating an identical deterministic run is not additional independent evidence. Never report scripted success frequency as a human win rate.

Do not set a universal target win rate. Agree whether the game is meant to reward first-attempt mastery, learning over retries, or long-term optimization before judging difficulty.

## Experience review

| Lens | Inspect | Useful evidence |
| --- | --- | --- |
| Teaching | Goal, constraints, controls and first useful action | Visible instruction, wrong inference, recovery |
| Feedback | Action acknowledgement, affordable/locked state, changed output | Before/action/after capture and state |
| Agency | Distinct useful strategies, understandable consequences | Comparable traces with different decisions |
| Pacing | Decision spacing, idle stretches, pressure and payoff | Timestamped action/decision timeline |
| Fairness | Consistent rules, visible failure causes, chance versus skill | Expected/actual outcomes and repeated trials |
| Recovery | Meaningful response after a mistake, useful retry information | Mistake and subsequent legal recovery attempt |
| Replay | Different plan possible after loss, quick restart | Changed strategy and outcome; human voluntary retry |
| Monetization | Clear value, truthful claims, no intentional frustration to sell relief | Actual offer/price/reward flow; separate human demand evidence |

Do not infer a player emotion from animation or a generated persona. Phrase expert findings as testable risks: “failure explanation omits morale; test whether players understand the loss,” rather than “players feel cheated.”

## Accessibility and mobile reality

Microsoft's input guidance identifies speed, duration and complexity as separate barriers; remapping alone does not solve them. Its difficulty guidance treats challenge as an interaction between the player's abilities and particular barriers. Apply these principles to mobile input rather than copying console controls. [3][4]

- Measure sustained tap demand separately from strategic difficulty. Test lower-input alternatives where available; do not assume holding is accessible to everyone either.
- Verify larger text, contrast, non-color cues, reduced motion and reachable controls. Check screen-reader labels, navigation order, spoken changing values, activation and pauses with the screen reader actually enabled. An AX tree inspection is only a partial check.
- Test interruption/background/return, cold launch, save migration and losing connectivity if used. Preserve player progress and make timer behavior understandable.
- Use simulator checks for repeatable layouts and lifecycle. Use physical devices for touch comfort, haptics, audio, heat, battery and sustained performance; mark unavailable measurements untested.
- Measure frame pacing and input responsiveness with profiling tools before diagnosing performance. Agent/tool round-trip delay is not player reaction time or game latency. If UI automation cannot deliver a cadence, use headless simulation for that experiment and report the separation.

## Evidence and triage

Every finding needs build/commit, device, starting save, input policy, timestamps, expected/actual behavior, reproduction steps and a capture or state trace. Keep observation, interpretation and proposed fix in separate fields.

Classify as verified defect, balance risk, usability risk, preference or untested hypothesis. Severity reflects player consequence and reach; confidence reflects evidence. A reproducible save loss can block a build; a speculative pacing preference cannot be silently promoted to the same status.

Reproduce a suspected bug before fixing it, minimize the steps, patch it, and rerun the affected route plus relevant regressions. Recheck screenshots against actual state; do not invent bugs to fill a report. A controlled vision-language-model game-testing study reports that misleading AI judgments can also mislead human reviewers; it does not establish human-level end-to-end play or fun assessment. [5]

## Short human handoff

After agent checks, give a player one neutral task: “Try this challenge as you normally would.” Do not supply the winning strategy. Allow reading and decision time; do not interpret silence as disengagement. Record interventions separately. Ask afterward what the goal was, why they lost/won, what they would change on another attempt, and whether they want to replay. Observe voluntary retry rather than equating a prompted answer with behavior.

Use small sessions to diagnose problems, not estimate market demand. Measure actual completion/retry and later return separately when sufficient consented data exists. Do not pool agent QA diagnostics with pilot-player responses. No remote telemetry is implied by this protocol.

## Default execution order

1. Identify build and intended experience; choose the top three uncertainties.
2. Run the smallest relevant rule/invariant checks.
3. Run a UI-information-only experience pass and preserve its trace.
4. Run targeted strategy/sensitivity experiments and reproduce critical results natively.
5. Check interruption, saves, accessibility and retry on relevant devices.
6. Deliver a short evidence report with blockers, hypotheses and the remaining human questions.
7. After human feedback, compare predictions with observations and revise the project playbook. Do not claim improved speed or accuracy until measured against comparable work.

Research alone does not train or permanently modify the underlying model. Load this document for future game-testing sessions; expand the genre brief when the game changes.

## Sources

1. Hunicke, LeBlanc, Zubek, [MDA: A Formal Approach to Game Design and Game Research](http://www.cs.northwestern.edu/~hunicke/MDA.pdf). Foundational design framework; not a validation standard.
2. Celia Hodent, [5 Misconceptions about UX](https://celiahodent.com/five-misconceptions-ux/). Practitioner guidance on game UX, design intent and hypothesis testing.
3. Microsoft, [XAG 107: Input](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107). Principles adapted to mobile; not a claim of Xbox or Apple certification.
4. Microsoft, [XAG 108: Game difficulty options](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/108). Evaluate barriers independently; no blanket requirement to implement every example.
5. [Human-AI Collaborative Game Testing with Vision Language Models: An Experiment Report](https://arxiv.org/html/2501.11782v2). Controlled visual-defect study/preprint; limited evidence for generalizing to autonomous gameplay or player research.
