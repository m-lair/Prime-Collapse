# Holiday Rush Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development. Steps use checkbox syntax for tracking.

**Goal:** Repair ending progression and deliver an isolated free Holiday Rush challenge plus App Store event marketing assets.

**Architecture:** Retain the existing game engine and Codable saves. Add a dedicated challenge controller, snapshot, and SwiftUI flow with its own save directory; never route it through base-game Game Center or prestige. Deep links open a briefing without mutating progress.

**Tech Stack:** Swift, SwiftUI, Observation, XCTest, Xcode simulator, local Codable JSON; native image generation for promotional artwork.

## 1. Ending evaluation
Files: Models/GameState.swift, Models/SavedGameState.swift, Models/EventManager.swift, tests/P0RegressionTests.swift, tools/loop-sim/*.
- [ ] Run existing simulator tests as baseline.
- [ ] Add regressions for lifetime earnings versus cash, income/tap-triggered Loop entry, eligibility reset, ending priority and save restoration; run and observe expected failures.
- [ ] Centralize evaluation and thresholds. Use earned milestones, foreground stability time, consistent clock, terminal guards, optional backward-compatible snapshot fields. Ensure event choices invoke the evaluator.
- [ ] Audit early event affordability and add a modest constructive choice with a real tradeoff where required. Prove all three endings through public gameplay methods, including ethical Reform without injected completion state, restored saves, and exactly-once prestige awards.
- [ ] Improve the scripted ethical spending policy and clock; add a purposeful Loop strategy. Fix the run script's missing prestige source. Run engine routes and report limitations; do not optimize for equal ending percentages.
- [ ] Run focused regression and persistence tests. Commit only owned files with `fix: make ending progression consistent and attainable`.

## 2. Isolated challenge engine
Files: new Models/HolidayRush/HolidayRushSession.swift and supporting focused files; new tests/HolidayRushTests.swift.
- [ ] Write tests against the proposed session API and run to establish red.
- [ ] Implement 720 active-second session, 1,500 parcels, ethics >=40, morale >=0.4; start with three matching owned workers and $150. No prestige bonuses.
- [ ] Provide advance(seconds:), shipPackage(), purchase(upgrade:), choose(index:), start/replay, save/resume, result, best result, feedback, export URL and strict deep-link matcher. Inject storage directory/date for tests.
- [ ] Pause timer and production during decisions, background, and outside challenge. Cap credited time at deadline and next scheduled decision. Decisions at 120, 300, 480 seconds; random base events/endings disabled only for this session.
- [ ] Test exact deadline ordering, no background income, idempotent outcomes, repeated links, save reload/corruption, and main-game separation. Persist versioned local diagnostics with explicit export. A dated completion badge requires a configured participation window; no arbitrary schedule.
- [ ] Write challenge saves atomically and surface failures/recovery in the UI using the existing save-health pattern.
- [ ] Run focused tests and commit owned files with `feat: add isolated Holiday Rush challenge sessions`.

## 3. SwiftUI integration
Files: ContentView.swift, Prime_CollapseApp.swift, new Views/HolidayRush/*, Info.plist, DashboardView.swift, tests/HolidayRushRoutingTests.swift.
- [ ] Test strict URL matching and opening behavior before routing implementation.
- [ ] Add a prominent Holiday Rush entry, briefing/start/resume, dashboard goal progress, shared upgrade choices, authored event choices, result/replay/return, local feedback, diagnostics export and share card.
- [ ] Route `primecollapse://events/holiday-rush` after onboarding; opening never automatically starts/resets. Main game pauses and resumes safely behind the full-screen challenge.
- [ ] Show exact base ending progress and stability requirement from engine policy. Handle loaded terminal state before simulation starts.
- [ ] Build, test, and perform touch-driven walkthrough on isolated iPhone 17 Pro Max. Verify save/return/replay, background pause, cold/warm deep links and share sheet.
- [ ] Commit with `feat: integrate Holiday Rush gameplay and event entry`.

## 4. Event and marketing package
Files: marketing/holiday-rush/*.
- [ ] Verify current Apple event image sizes and metadata requirements from official sources.
- [ ] Generate event artwork matching the game's blue parcel identity; deliver landscape card, portrait detail, square social art, copy and source provenance. Inspect final dimensions/format and visual composition.
- [ ] Provide event metadata JSON, local draft copy, review notes, launch caption, player pilot guide, and release checklist. Dates/window configuration remain explicitly required before public event submission.
- [ ] Ensure every claim matches the tested build. Do not submit/publish/accept agreements as part of local preparation.
- [ ] Commit with `docs: prepare Holiday Rush event and marketing package`.

## 5. Review and delivery
- [ ] Review spec compliance then code quality, address issues, run final relevant test suite/build and repeat affected walkthroughs.
- [ ] Record test counts, engine evidence, screenshots, and external release gaps in docs/holiday-rush-validation.md.
- [ ] Deliver branch/commit, runnable build and asset links. No claim of TestFlight distribution, App Store approval, public launch, or aggregate demand measurement without separate verification.
