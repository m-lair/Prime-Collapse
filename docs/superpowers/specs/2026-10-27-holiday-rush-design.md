# Ending balance and Holiday Rush

Status: approved October 27, 2026 and implemented. Remaining native verification and release steps are recorded in `docs/holiday-rush-validation.md`.

## Goal

Make Prime Collapse's base-game endings fair and understandable, then ship one free, replayable Holiday Rush challenge that can support an App Store In-App Event. Learn whether players finish a challenge, replay it, and express interest in more.

Source project: `/Users/marcus/Developer/Prime Collapse/Prime Collapse/Prime Collapse.xcodeproj`. The inspected checkout is version 1.2 at `c7ca8eb`; equivalence to the distributed binary is unverified.

## Evidence and limits

A fresh 100-run automated simulation produced 69 collapses, 11 reforms, no Loop endings, and 20 timeouts. These are scripted strategies, not observed players. The simulator buys aggressively and spends money that might otherwise fund ethical choices. Its synthetic clock also mixes with production calls to `Date()`. Do not use the ending distribution as a target or treat it as measured player difficulty.

Current source checks Reform against current cash, despite describing money earned. Loop eligibility is evaluated after upgrade purchases, rather than on income ticks. This can miss eligibility reached through automation or tapping. The existing Loop test starts inside the final instability window, so it does not prove a player can enter it naturally.

## Alternatives and decision

1. Recommended: fix ending evaluation, then add a separate challenge session with fixed starting conditions. Preserves existing progress and supports fair replay comparisons.
2. Run the event inside the player's current company. Smaller initial UI change, but prestige and existing wealth dominate difficulty and restarting risks ordinary progress.
3. Add a new campaign framework and multiple challenges now. More extensible, but unnecessary before validating the first challenge.

Proceed with option 1. Build only the small amount of session separation needed for this challenge.

## Phase 1: ending correctness and balance

- Keep Collapse tied to ethics reaching zero. Terminal outcomes cannot be overwritten or awarded twice.
- Reform requires five positive choices, ethics at least 50, and lifetime run earnings of at least $1,000. Purchases should not erase economic progress toward the ending.
- Loop requires 1,500 packages, three workers, lifetime run earnings of at least $2,500, and ethics between 15 and 25. Evaluate eligibility consistently after taps, purchases, event choices, and automation updates.
- Entering Loop starts a visible 60-second stability objective. Maintain the ethics band and worker requirement throughout; leaving them resets the objective. Economic milestones remain earned. Collapse takes priority. Reform and Loop remain distinct paths.
- Use a consistent supplied clock for ending evaluation. Avoid entering or completing the Loop window because a synthetic test clock differs from wall time. Save and restore pending ending progress; a foreground-only stability duration must not complete during background time.
- Display exact requirements and progress in the game, using the same values as the evaluator.
- Audit early ethical event choices for situations that force harm solely because all constructive choices cost more than the early economy can plausibly supply. Add or rebalance a modest constructive option where justified, with a real tradeoff. Do not globally make ethical play costless.
- First repair the simulation clock and its ethical strategy's spending policy. Add a deliberate Loop strategy. Use reproducible random input where feasible and report strategy assumptions.
- Acceptance: deterministic end-to-end engine runs can reach each ending through public gameplay methods, all terminal paths persist and award prestige once, and an ethical strategy can finish Reform without fixture-only state injection. Do not require equal ending frequencies.

## Phase 2: Holiday Rush gameplay

Free standalone challenge. Initial tuning hypothesis: ship 1,500 packages within 12 minutes of active gameplay while ending with ethics at least 40 and morale at least 40%. Start with three workers, $150, and no prestige bonuses. Tune these numbers using simulation and hands-on play before release.

- A Holiday Rush card opens a briefing with goal, duration, starting conditions, and Start/Resume controls. Starting requires an explicit player action and never resets the main company.
- Reuse shipping, upgrades, ethics, and morale. Use a separate game state, save location, and event manager. Challenge income and outcomes do not alter base-game money, prestige, achievements, or leaderboards.
- Use a foreground gameplay timer. Pause both the timer and production while reading a challenge decision, while backgrounded, or outside the challenge. No offline challenge income. Save remaining time and pending choices across relaunches. Cap each production tick to remaining active time, including a tick that crosses the deadline.
- Show packages/target, remaining time, ethics, and morale directly in the challenge UI.
- Three authored decision points, at approximately 2, 5, and 8 active minutes: seasonal staffing, delivery backlog/overtime, and a late priority shipment. Offer viable ethical and aggressive approaches with clearly stated tradeoffs. Suppress unrelated random events and base-game endings in this mode.
- Success occurs when the package target and minimum ethics/morale are satisfied before the deadline; failure occurs on collapse or when time expires without meeting the goal. Define boundary ordering explicitly: final production/choice resolves, then success, then deadline failure. Once resolved, freeze the run.
- Result screen shows outcome, delivery count, time, ethics, morale, best local result, Replay, Return to Company, and Share. Preserve the last result. Replay resets only the challenge.
- Include a small earned local completion badge with no economy bonus. No paid products, ads, or storefront promises.
- Offer a neutral, optional feedback action after the result: "Would you play more challenges like this?" with Yes/Maybe/No and a local response. Do not present this as evidence of willingness to pay.

## Measurement

Record a small versioned local activity log for challenge starts, resumes, completions, failures, retries, shares, and feedback, without personal identifiers. Provide a diagnostic export that testers deliberately share. These local records alone cannot reveal aggregate behavior of App Store users. No new analytics service, credentials, or remote transmission is assumed.

Initial validation is a TestFlight/player pilot using exported results and direct feedback. Before an App Store-wide experiment, separately decide how aggregate behavior will be collected. App Store event analytics measure discovery and event engagement; they do not replace in-game completion and replay measurement.

## App Store event and marketing

- Badge: Challenge. Audience: appropriate for all users. Participation: free.
- Draft name: `Holiday Rush`.
- Draft short description: `Beat the rush. Protect your workforce.`
- Draft long description: `Ship 1,500 packages before time runs out. Balance overtime, morale, and ethics in a free holiday challenge.`
- Validate metadata character limits and revise numbers if gameplay tuning changes.
- Implement and test `primecollapse://events/holiday-rush` as a narrowly parsed custom URL, unless an existing owned universal-link setup is found. Opening shows briefing or resume; it never starts or resets a run automatically. Handle cold launch, onboarding, warm launch, malformed links, and repeated links.
- Keep the challenge replayable. The App Store event promotes a specific limited holiday participation window and the opportunity to earn its completion badge; configure that window in the app and event record consistently before publication. A dated badge requires successful completion within that window, using the completion timestamp, rather than the start timestamp. Outside the window, the briefing explains practice availability and does not offer the dated badge. Existing attempts/results remain accessible; an attempt completed after closing can still succeed in practice but does not earn the dated badge.
- Event dates, storefronts, and launch time are not yet selected. Maximum App Store event duration is 31 days; promotion can begin up to 14 days earlier. Do not hardcode an unapproved holiday schedule.
- Prepare event card and detail media plus a small social launch image/caption using actual game captures and simple typography. User clarification: AI for code only, no AI artwork. Validate current Apple image requirements before export. Avoid putting claims in assets that the build does not deliver.
- Prepare the App Store Connect draft metadata and review notes locally. Creating/submitting the event, accepting agreements, and releasing the app are separate consequential release steps. The previously reported agreement-update banner must be rechecked before release work.

Apple references (checked October 27, 2026):
- https://developer.apple.com/app-store/in-app-events/
- https://developer.apple.com/app-store/review/guidelines/#accurate-metadata

## Architecture and safeguards

Keep ending evaluation in the existing engine with a small shared policy for thresholds and presentation. Use an explicit Holiday Rush session/controller to own challenge lifecycle, elapsed active time, scheduled decisions, and result. Reuse existing views selectively; do not add an abstract scenario/plugin framework. Persist a Codable challenge snapshot atomically in a separate file; test corrupt-file recovery and backward compatibility of normal saves.

Do not migrate or clear normal saves. Handle cold-load endings before starting simulation, stop timers on terminal outcomes, and prevent duplicate result/reward writes. Display save failures using the existing save-health pattern.

## Verification and delivery

1. Regression tests demonstrate the current earnings/Loop trigger failures before engine changes. Cover ending priority, all evaluation triggers, stability resets, terminal idempotence, restart, and save/load.
2. Reproducible engine simulations exercise real gameplay, including purposeful Reform/Loop routes, and report pacing with limits.
3. Challenge tests cover timer pause/resume, scheduled decisions, success/failure boundaries, isolated saves/prestige/Game Center, replay, and activity export.
4. Build and run on an isolated iPhone 17 Pro Max simulator. Walk through briefing, manual shipping, purchase, every decision, result, replay, main-company restoration, and deep links. Inspect touch-driven layouts and share output. Physical-device checks remain explicit if not performed.
5. Prepare local event copy/assets and release checklist. Report local validation separately from TestFlight distribution, App Store event approval, and public launch.

Implementation order: ending evaluation and meaningful regressions; simulator corrections and balance checks; isolated Holiday Rush engine; UI/save/deep-link integration; player pilot materials and event marketing package.
