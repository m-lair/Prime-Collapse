# Holiday Rush validation — October 28, 2026

## Implemented

- Reform uses earned run income rather than cash on hand. Loop evaluation runs after gameplay changes and requires 60 foreground stability seconds; eligibility loss resets the timer. Terminal outcomes and their banked-reward guard survive normal save/reload.
- Ending requirements are visible in the dashboard. Main-game lifecycle resets foreground timing. Event return restores a terminal company, and delayed collapse presentations cannot interrupt the challenge. Ending content is scrollable so restart controls remain reachable on smaller layouts.
- Holiday Rush has an isolated game state and atomic save, 12 active minutes, 1,500 packages, minimum ethics 40 and morale 40%, three authored decisions, explicit start/resume, result/retry/share, optional local feedback, and explicit diagnostic export.
- Event badge eligibility uses completion time in the configured window. Badge ownership persists separately across practice replays, including migration from existing result records. The event-window resource currently has null dates.
- Event deep link: `primecollapse://events/holiday-rush`. It opens briefing/paused session after onboarding and never automatically starts or resets a run.
- Local event metadata, launch/review copy, native screenshot previews, crop/export code and release/pilot checklist are in `marketing/holiday-rush/`.
- App version prepared as 1.3 (build 1). No app upload or distribution performed.

## Automated verification

| Check | Observed result |
| --- | --- |
| Unmodified baseline suite | 71 passed, 0 failed |
| Ending regressions | Three original assertions failed before fixes; 32 focused ending/persistence tests passed after fixes |
| All ending routes | Public catalog/gameplay routes reach Collapse, Reform and Loop, with snapshot restoration and zero second prestige award |
| Engine simulations | 120 runs: 10 Collapse, 75 Reform, 35 Loop; no terminal flags/timeouts. Dedicated ethical Reform and Loop strategies each succeeded 20/20 |
| Holiday Rush tests | 15 passed, including deadline ordering, decision pause, save recovery/error, isolated economy, badge retention/migration, replay and explicit resume |
| Routing | Valid event URL plus seven invalid URL cases verified red → green, then included in full XCTest suite |
| Full integrated suite | **95 passed, 0 failed, 0 skipped**, iPhone 17 Pro Max / iOS 26.5 simulator |
| Build and source checks | Simulator build succeeded; `git diff --check` clean; event-window JSON present in app bundle |
| Reviews | Engine, challenge and integration spec compliance approved; code-quality review found no actionable defects |

Full suite result: `/Users/marcus/Library/Developer/XcodeBuildMCP/workspaces/Game-9fab573dd6a9/result-bundles/test_sim_2026-10-28T01-07-42-980Z_pid60834_25ab9e17.xcresult`.

The suite/build emits existing warnings (preview traits, Game Center APIs, unused values and unreachable catch); a pricing test deliberately logs its zero-scaling warning. Passing tests do not establish an App Store release or human retention.

## Challenge pacing evidence

Headless real-engine playthrough: one manual shipment each active second, retain $100 while buying selected automation/training upgrades, hire toward ten workers, and make all three authored decisions.

| Choices | Outcome | Packages | Active time | Final ethics / morale |
| --- | --- | --- | --- | --- |
| Fund constructive choices | Success | 1,501 | 694 seconds | 100 / 100% |
| Free balanced choices | Deadline | 1,269 | 720 seconds | Above minimums |
| Aggressive choices | Deadline | 1,669 | 720 seconds | 23 / 25% |

These demonstrate an attainable goal with consequential tradeoffs. They are scripted strategies, not human difficulty or demand measurements. The base-game simulation still uses some system randomness; exact distributions can vary. See `simulation/ending-regressions.md` and `simulation/loop-validation-report.md` for route methodology and limitations.

## Native UI observed

- Built and launched on isolated iPhone 17 Pro Max / iOS 26.5 profile `Prime Collapse Monetization QA`.
- Main-game Holiday Rush entry opens the briefing with an explicit Start button. Start opens challenge gameplay.
- Warm event link from a staged collapsed-company save opens the separate challenge. Returning originally stranded the company; this was reproduced before the fix and then verified to restore the Economic Collapse ending screen after the fix.
- On a fresh iPad Pro 13-inch / iPadOS 26.5 profile, a cold event link first shows onboarding; dismissing onboarding opens the Holiday Rush briefing without starting a run.
- Completed an unaccelerated 720-active-second iPad walkthrough: 364 packages, ethics 100, morale 100%. Touch shipping, logistics/worker purchases and all three paid constructive decisions worked. This low-tap QA run reached the deadline; it is not a human difficulty study.
- Pause/resume and Home/background preserved the paused challenge counters. Returning to the company and reentering retained the challenge. Replay started a fresh challenge and retained the prior result and optional local feedback.
- Main-company checkpoint matched exactly after challenge completion and replay: 3 packages, $2.85, one worker, $2.85 lifetime earnings and zero ethical choices. Before/after evidence is in `holiday-rush-evidence/`.
- Result sharing and diagnostic export opened native share sheets and were dismissed without sending. Accessibility activation reproduced a missing share-opening record with the old gesture handler (zero records); an explicit button action fixed it (one `share_sheet_opened` record). This measures opening, not completed sharing. Optional Maybe feedback visibly saved and persisted through replay.
- Ending touch scrolling and Play Again worked on iPhone after hiding decorative background/confetti effects from accessibility. Previously dozens of decorative images burdened the accessibility tree. The final share fix built successfully and was verified natively on iPad; the 95-test suite above predates these two view-only fixes.
- iPad portrait/landscape and enlarged text size 7 were inspected; text wrapped and Resume remained reachable. Accessibility labels/actions were inspected, but a full spoken VoiceOver walkthrough was not performed.
- Captured actual briefing/decision UI on iPhone and iPad. Event/social previews are deterministic crops of actual native decision screenshots; exact dimensions/aspect ratios checked, with no artwork generation or upscaling.

UI fixture tests used isolated simulator data only. The staged main save was backed up in the task's temporary directory. No personal app install or production data was modified.

## Remaining native verification

The Mac was unlocked and the native walkthrough resumed. Remaining verification:

- A physical-device player pilot and a full spoken VoiceOver/gesture walkthrough.
- A human win-oriented playtest for difficulty and repeat interest; scripted success and a low-tap native deadline run do not measure player demand.
- Replace/review preview event media using final active-event captures after dates are chosen, including App Store Connect's overlay/crop preview.

## External release state

**October 28 update:** 1.3 (4) has since been uploaded through Xcode Cloud and verified Testing in the internal Holiday Rush Playtest group. See `holiday-rush-testflight.md`. The paragraph below records the implementation handoff before that separately authorized distribution.

No TestFlight upload/distribution, App Store event creation/submission, review approval, public release, agreement acceptance or public marketing post was performed. Event dates/storefronts remain unselected and must match the app's event-window resource before submission. The CLI has no configured API credentials; an existing signed-in browser session was not used for release mutations.

Pilot diagnostics stay local until deliberately exported. No remote analytics service was added, and public aggregate completion/replay or willingness to pay has not been measured.

Existing prestige and game snapshots remain separate files; normal reload idempotence is tested, but an abrupt crash between those two writes retains the pre-existing transaction-consistency limitation.
