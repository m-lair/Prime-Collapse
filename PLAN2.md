# 🕹 Prime Collapse: Update Plan

This document tracks the planned changes and improvements for the Prime Collapse game. Tasks are organized by category and marked with checkboxes to track progress.

## 🖥 UI/UX Improvements

* [ ] **Event System Timing Fixes**
  * [ ] Disable event interaction until fully rendered
  * [ ] Add animation/delay to make events feel more intentional
  * [ ] Ensure event choices are only tappable after a short delay

* [ ] **Fix "Show Details" Layout Issues**
  * [ ] Prevent content shifting when details are expanded
  * [ ] Consider using overlay or fixed-size containers for details
  * [ ] Test on multiple device sizes to ensure consistent layout

* [ ] **Add Clear Effect Information to Upgrades**
  * [ ] Show specific metrics affected by each upgrade
  * [ ] Display numerical changes (e.g., "+5% Worker Efficiency")
  * [ ] Use color coding to indicate positive/negative effects
  * [ ] Consider adding tooltips or info buttons for detailed explanations

* [ ] **Fix Upgrade List Ethical Indicators**
  * [ ] Review visual indicators for ethical/unethical upgrades
  * [ ] Ensure colors and symbols correctly match ethical implications
  * [ ] Add clear visual distinction between ethical categories

* [ ] **Add Game Control Buttons**
  * [ ] Implement reset/restart functionality
  * [ ] Add quit button with confirmation dialog
  * [ ] Consider adding these to main menu or settings panel

* [ ] **Dashboard View Improvements**
  * [ ] Verify all displayed metrics are accurate
  * [ ] Ensure all stats update correctly in real-time
  * [ ] Improve readability and information hierarchy
  * [ ] Add tooltips or help icons for complex metrics

## ⚙️ Game Mechanics Fixes

* [ ] **Fix Negative Money Issues**
  * [ ] Implement minimum money protection
  * [ ] Add recovery mechanics for when money drops too low
  * [ ] Prevent purchases that would cause negative balance
  * [ ] Add visual warning when money is running low

* [ ] **Worker Efficiency Updates**
  * [ ] Audit all events and upgrades that affect worker efficiency
  * [ ] Ensure consistent application of efficiency modifiers
  * [ ] Fix any bugs where efficiency changes aren't properly applied
  * [ ] Consider adding visual indicator when efficiency changes

* [ ] **Event System Logic Review**
  * [ ] Verify all event effects are correctly applied
  * [ ] Ensure event choices have appropriate consequences
  * [ ] Fix any inconsistencies in event outcomes
  * [ ] Validate event trigger conditions and frequencies

* [ ] **Customer Satisfaction Evaluation**
  * _Dependency: Complete metrics review first_
  * [ ] Analyze impact of customer satisfaction on gameplay
  * [ ] Either enhance its importance or remove completely
  * [ ] If keeping, ensure clear visual feedback when it changes
  * [ ] Consider merging with public perception if too similar

* [ ] **Worker Metrics Simplification**
  * [ ] Review current worker-related metrics for redundancy
  * [ ] Consider consolidating similar metrics
  * [ ] Improve visual representation and explanation
  * [ ] Add tutorial elements to explain worker mechanics

## 🎮 Game Balance and Progression

* [ ] **Improve Game Phase Progression**
  * [ ] Balance early game (first 5 minutes)
    * [ ] Ensure player can make meaningful choices quickly
    * [ ] Provide clear direction on initial upgrades
  * [ ] Tune mid-game (5-15 minutes)
    * [ ] Smooth out difficulty curve
    * [ ] Ensure consistent challenge and reward
  * [ ] Refine late-game (15+ minutes)
    * [ ] Provide compelling endgame goals
    * [ ] Ensure all endings feel satisfying and achievable

* [ ] **End Game Screen Improvements**
  * [ ] Add lifetime total money earned stat
  * [ ] Differentiate between current money and total earned
  * [ ] Consider adding more stats (e.g., ethical choices made)
  * [ ] Improve visual presentation of end game results

## 🆕 Content Additions

* [ ] **New Upgrades**
  * [ ] Design and implement 3-5 early game upgrades
  * [ ] Design and implement 3-5 mid game upgrades
  * [ ] Design and implement 3-5 late game upgrades
  * [ ] Ensure balance between ethical and unethical options
  * [ ] Update upgrade manager to include new options

## 📈 Final Testing and Tuning

* [ ] **Comprehensive Playtest**
  * _Dependency: Complete all other fixes first_
  * [ ] Test all game phases for balance
  * [ ] Verify all metrics and systems function correctly
  * [ ] Check all endings and achievement conditions
  * [ ] Validate Game Center integration

* [ ] **Performance Optimization**
  * [ ] Audit for memory leaks or excessive CPU usage
  * [ ] Optimize rendering of complex UI elements
  * [ ] Ensure smooth animations and transitions
  * [ ] Test on older device models if possible

## 📝 Implementation Notes

When implementing these changes, consider the following project structure:

```
Prime Collapse/
├── Models/
│   ├── GameState.swift          - Core game state and logic
│   ├── SavedGameState.swift     - SwiftData persistence model
│   ├── Upgrade.swift            - Upgrade data structure
│   ├── UpgradeManager.swift     - Available upgrades and pricing
│   ├── GameEvent.swift          - Random event model
│   └── EventManager.swift       - Event generation and handling
├── Views/
│   ├── Components/              - Reusable UI components
│   ├── Dashboard/               - Analytics and statistics views
│   ├── GameEnding/              - End-game screens and effects
│   ├── Upgrades/                - Upgrade shop and items
│   └── EventView.swift          - Event popup and choice UI
├── GameCenterManager.swift      - Game Center integration
└── Prime_CollapseApp.swift      - App entry point
```

Always maintain the separation between game state logic and UI to ensure maintainability. 