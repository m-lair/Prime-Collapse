# Holiday Rush Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development. Steps use checkbox syntax for tracking.

**Goal:** Repair ending progression and deliver an isolated free Holiday Rush challenge plus App Store event marketing assets.

**Architecture:** Retain the existing game engine and Codable saves. Add a dedicated challenge controller, snapshot, and SwiftUI flow with its own save directory; never route it through base-game Game Center or prestige. Deep links open a briefing without mutating progress.

**Tech Stack:** Swift, SwiftUI, Observation, XCTest, Xcode simulator, local Codable JSON; actual game captures for promotional assets. User explicitly prohibits AI artwork.

## 1. Ending evaluation
Files: Models/GameState.swift, Models/SavedGameState.swift, Models/EventManager.swift, tests/P0RegressionTests.swift, tools/loop-sim/*.
- [x] Run existing simulator tests as baseline.
- [x] Add regressions for lifetime earnings versus cash, income/tap-triggered Loop entry, eligibility reset, ending priority and save restoration; run and observe expected failures.
- [x] Centralize evaluation and thresholds. Use earned milestones, foreground stability time, consistent clock, terminal guards, optional backward-compatible snapshot fields. Ensure event choices invoke the evaluator.
- [x] Audit early event affordability and add a modest constructive choice with a real tradeoff where required. Prove all three endings through public gameplay methods, including ethical Reform without injected completion state, restored saves, and exactly-once prestige awards.
- [x] Improve the scripted ethical spending policy and clock; add a purposeful Loop strategy. Fix the run script's missing prestige source. Run engine routes and report limitations; do not optimize for equal ending percentages.
- [x] Run focused regression and persistence tests. Commit only owned files with `fix: make ending progression consistent and attainable`.

## 2. Isolated challenge engine
Files: new Models/HolidayRush/HolidayRushSession.swift and supporting focused files; new tests/HolidayRushTests.swift.
- [x] Write tests against the proposed session API and run to establish red.
- [x] Implement 720 active-second session, 1,500 parcels, ethics >=40, morale >=0.4; start with three matching owned workers and $150. No prestige bonuses.
- [x] Provide advance(seconds:), shipPackage(), purchase(upgrade:), choose(index:), start/replay, save/resume, result, best result, feedback, export URL and strict deep-link matcher. Inject storage directory/date for tests.
- [x] Pause timer and production during decisions, background, and outside challenge. Cap credited time at deadline and next scheduled decision. Decisions at 120, 300, 480 seconds; random base events/endings disabled only for this session.
- [x] Test exact deadline ordering, no background income, idempotent outcomes, repeated links, save reload/corruption, and main-game separation. Persist versioned local diagnostics with explicit export. A dated completion badge requires a configured participation window; no arbitrary schedule.
- [x] Write challenge saves atomically and surface failures/recovery in the UI using the existing save-health pattern.
- [x] Run focused tests and commit owned files with `feat: add isolated Holiday Rush challenge sessions`.

## 3. SwiftUI integration
Files: ContentView.swift, Prime_CollapseApp.swift, new Views/HolidayRush/*, Info.plist, DashboardView.swift, tests/HolidayRushRoutingTests.swift.
- [x] Test strict URL matching and opening behavior before routing implementation.
- [x] Add a prominent Holiday Rush entry, briefing/start/resume, dashboard goal progress, shared upgrade choices, authored event choices, result/replay/return, local feedback, diagnostics export and share card.
- [x] Route `primecollapse://events/holiday-rush` after onboarding; opening never automatically starts/resets. Main game pauses and resumes safely behind the full-screen challenge.
- [x] Show exact base ending progress and stability requirement from engine policy. Handle loaded terminal state before simulation starts.
- [ ] Build, test, and perform touch-driven walkthrough on isolated iPhone 17 Pro Max. Verify save/return/replay, background pause, cold/warm deep links and share sheet.
- [x] Commit integration as `52aae82 feat: integrate Holiday Rush event entry and visible ending progress`.

## 4. Event and marketing package
Files: marketing/holiday-rush/*.
- [x] Verify current Apple event image sizes and metadata requirements from official sources.
- [x] Capture actual game visuals; export landscape card, portrait detail and social media assets with source provenance. No AI artwork or generated illustrative assets. Inspect final dimensions/format and visual composition.
- [x] Provide event metadata JSON, local draft copy, review notes, launch caption, player pilot guide, and release checklist. Dates/window configuration remain explicitly required before public event submission.
- [x] Ensure every claim matches the tested build. Do not submit/publish/accept agreements as part of local preparation.
- [x] Commit event preview package and validation documentation with conventional docs prefix.

## 5. Review and delivery
- [x] Review spec compliance and code quality, address issues, and run integrated tests/build (95 passed).
- [ ] Finish remaining native walkthrough after Mac unlock; see validation document for explicit gaps.
- [x] Record test counts, engine evidence, screenshots, and external release gaps in docs/holiday-rush-validation.md.
- [ ] Deliver branch/commit, runnable build and asset links. No claim of TestFlight distribution, App Store approval, public launch, or aggregate demand measurement without separate verification.
