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
    * [x] `moralDecay`
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
* [ ] Separate upgrade screen
* [ ] Optional "Dashboard" showing morality score and collapse risk

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
* [x] `moralDecay` increases with unethical upgrades
* [x] Add visible indicators (e.g. red tint UI, warning banners)
* [x] When `moralDecay` >= 100, start Collapse Phase:
    * [x] Slowdowns, flashing alerts, broken UI elements
    * [x] Disabling automation
    * [x] Show "Collapse Ending" view

## 💾 Step 7: Save Progress with SwiftData (Completed)
* [x] Persist `GameState` with SwiftData
* [x] Auto-save changes with `@ModelContext`
* [x] Load on app launch, create fresh state if none found
* [x] Implement proper schema versioning for future migrations

## 🔐 Step 8: Optional Sign in with Apple
* [ ] Use Apple's `SignInWithAppleButton` (SwiftUI-native)
* [ ] On sign-in, show user's name on dashboard
* [ ] Keep fallback guest mode by default

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
* Automation follows this formula: packages shipped = automationRate × timeElapsed
* Multiple ending types: Collapse, Reform, and Loop, each triggered by different game conditions

### SwiftData Notes for Future Developers
* The app uses a versioned schema approach for SwiftData migrations
* Current version is SchemaV1
* When adding new properties to SavedGameState:
  1. Create SchemaV2 in Prime_CollapseApp.swift with the updated model
  2. Implement the migration plan as described in the comments
  3. Always provide default values for new non-optional properties
  4. Test migrations thoroughly before releasing
* Be careful with array properties - they can cause materialization issues during migration

### Next Steps Suggestions
* Implement the separate upgrade screen with more detailed upgrade information
* Develop more detailed ending screens with stats and narrative conclusions
* Add more upgrades with different effects (not just automation rate multipliers)
* Add more visual polish to the upgrade cards
* Implement a settings screen with save/reset options
* Consider adding analytics to track player decisions and game progression patterns 