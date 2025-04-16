# 🕹 Project Plan: "Prime Collapse"
A SwiftUI clicker-style satire game about capitalism gone too far

## ⚙️ Tech Stack
* Swift 6
* SwiftUI (iOS 17+ preferred)
* Observation framework (@Observable)
* SwiftData for local persistence
* Sign in with Apple (optional, for personalization)
* No external dependencies required
* Everything runs offline, fully local

## 🔰 Step 1: Project Setup (Completed)
* [x] Create a new iOS App project in Xcode
* [x] Set minimum deployment to iOS 17 (Currently set to iOS 18.2, which is even newer)
* [x] Enable SwiftData (Added model container and SavedGameState model)
* [x] Set up proper SwiftData schema versioning for future migrations
* [ ] Add necessary entitlements for Sign in with Apple (but keep it optional)
* [ ] Create app icon + launch screen (basic placeholder is fine for now)

## 🧠 Step 2: Define Core Game Model (Completed)
* [x] Create `GameState` class with `@Observable`
    * [x] `totalPackagesShipped`
    * [x] `money`
    * [x] `workers`
    * [x] `upgrades: [Upgrade]`
    * [x] `automationRate: Double`
    * [x] `ethicsScore: Double`
    * [x] `isCollapsing`
    * [x] `lastUpdate`
    * [x] `packageAccumulator: Double`
    * [x] `ethicalChoicesMade: Int`
    * [x] `endingType: GameEnding`

## 🔁 Step 3: Game Loop (Completed)
* [x] Manual Tap Button to simulate a shipped package.
* [x] Timer using `TimelineView` or `Task` loop to automate shipping.
* [x] Use `onChange(of:)` to apply upgrades and trigger animations.

## 🎛 Step 4: UI Components (Partially Completed)
* [x] Main view with:
    * [x] Package count
    * [x] Money earned
    * [x] Tap button
    * [x] Collapse warning banner
    * [x] Upgrade list (horizontal scroll)
* [x] Separate upgrade screen
* [x] Optional "Dashboard" showing morality score and collapse risk

## 🆙 Step 5: Upgrade System (Completed)
* [x] Create `Upgrade` model:
    * [x] `id: UUID`
    * [x] `name: String`
    * [x] `description: String`
    * [x] `cost: Double`
    * [x] `effect: (GameState) -> Void`
    * [x] `isRepeatable: Bool`
    * [x] `moralImpact: Double`
* [x] Define example upgrades:
    * [x] "Hire Worker"
    * [x] "Same Day Delivery"
    * [x] "Remove Worker Breaks"
    * [x] "AI Optimization"

## 📉 Step 6: Morality & Collapse System (Completed)
* [x] `ethicsScore` decreases with unethical choices (starts at 100)
* [x] Add visible indicators (e.g. red tint UI, warning banners)
* [x] When `ethicsScore` <= 0, start Collapse Phase:
    * [x] Slowdowns, flashing alerts, broken UI elements
    * [x] Disabling automation
    * [x] Show "Collapse Ending" view

## 💾 Step 7: Save Progress with SwiftData (Completed)
* [x] Persist `GameState` with SwiftData
* [x] Auto-save changes with `@ModelContext`
* [x] Load on app launch, create fresh state if none found
* [x] Implement proper schema versioning for future migrations

## 🔐 Step 8: Game Center Integration
* [x] Add GameKit framework and necessary entitlements
* [x] Implement GKLocalPlayer authentication on app launch
* [ ] Create leaderboards for metrics like total packages shipped and money earned
* [ ] Add achievements for game milestones (first worker hired, reaching automation thresholds)
* [ ] Display player's Game Center profile on dashboard

## 🌚 Step 9: Endings (Partially Completed)
* [x] Define multiple game outcomes:
    1. [x] Collapse Ending
    2. [x] Reform Ending
    3. [x] Loop Mode
* [ ] Implement detailed ending screens with stats and narratives

## ✨ Step 10: Polish & Extras (Partially Completed)
* [x] Haptic feedback on taps
* [ ] Smooth transitions (`.transition`, `.matchedGeometryEffect`)
* [x] Confetti or glitch effects during collapse
* [ ] Stylized upgrade cards
* [ ] Game settings toggle

## 🧪 Step 11: Testing & Tuning
* [ ] Test on different devices/iOS versions
* [ ] Add debug menu
* [ ] Tune upgrade pacing (~5–15 min game cycles) 

## 📋 Development Notes
### Recent Fixes
* Fixed the automation system to properly accumulate fractional packages over time
  * Added a `packageAccumulator` property to `GameState` to persist between timer updates
  * This enables low automation rates (like 0.1 packages/sec) to work correctly over time
  * Timer runs every 0.1 seconds but now accumulates partial progress
* Fixed SwiftData migration issues
  * Implemented proper schema versioning for future model changes
  * Set up a versioned schema structure in Prime_CollapseApp.swift
  * Fixed previous issues with mandatory attribute migration

### Game Architecture Notes
* The game uses a timer-based loop running at 0.1 second intervals
* `GameState` is the central model with the `@Observable` macro for SwiftUI reactivity
* Upgrades affect the game by modifying properties in `GameState`
* Ethics score starts at 100 and decreases. Collapse occurs when score hits 0.
* Automation follows this formula: packages shipped = automationRate × timeElapsed
* Multiple ending types: Collapse, Reform, and Loop, each triggered by different game conditions

### SwiftData Notes for Future Developers
* The app uses a versioned schema approach for SwiftData migrations
* Current version is SchemaV4 (as of ethicsScore rename)
* When adding new properties to SavedGameState:
  1. Create SchemaV5 (or next version) in Prime_CollapseApp.swift with the updated model
  2. Implement the migration plan (lightweight or custom) as described in the comments
  3. Always provide default values for new non-optional properties in the model's init
* Be careful with array properties - they can cause materialization issues during migration

## 🎲 Step 12: Random Events System
* [x] Create a `GameEvent` model:
    * [x] `id: UUID`
    * [x] `title: String`
    * [x] `description: String`
    * [x] `choices: [EventChoice]`
    * [x] `triggerCondition: (GameState) -> Bool`
* [x] Implement `EventChoice` model:
    * [x] `id: UUID`
    * [x] `text: String`
    * [x] `effect: (GameState) -> Void`
    * [x] `moralImpact: Double`
* [x] Add event categories:
    * [x] Workplace incidents (injuries, strikes)
    * [x] Market opportunities (rush orders, partnerships)
    * [x] PR events (media coverage, customer feedback)
    * [x] Regulatory changes (new laws affecting business)
* [x] Create timer-based event trigger system
* [x] Design modal presentation for events with choices
* [x] Add visual and haptic feedback for event notifications

## 📊 Step 13: Expanded Metrics System
* [ ] Update `GameState` with new properties:
    * [ ] `publicPerception: Double` (0-100 scale)
    * [ ] `workerSatisfaction: Double` (0-100 scale)
    * [ ] `environmentalImpact: Double` (0-100 scale)
* [ ] Modify `Upgrade` model:
    * [ ] Add impact fields for new metrics
    * [ ] Create upgrade effects that consider multiple metrics
* [ ] Update UI to display new metrics:
    * [ ] Add dashboard panels for each metric
    * [ ] Create visual indicators for critical thresholds
* [ ] Implement effects of metrics on gameplay:
    * [ ] Worker satisfaction affects automation efficiency
    * [ ] Public perception influences upgrade costs
    * [ ] Environmental impact adds regulatory consequences

## ⚖️ Step 14: Enhanced Progression Balance
* [ ] Rebalance the Loop ending:
    * [ ] Add "stability features" that slow ethics score decay for balanced players
    * [ ] Create specific upgrades that maintain equilibrium
* [ ] Enhance the ethical path:
    * [ ] Add unique ethical upgrades with competitive benefits
    * [ ] Create bonus incentives for maintaining high ethics score
* [ ] Refine ending requirements:
    * [ ] Adjust thresholds for each ending type
    * [ ] Create more gradual progression toward endings
* [ ] Implement "recovery mechanics" for players approaching collapse
    * [ ] Add special crisis-management upgrades
    * [ ] Create temporary boosts for critical situations 