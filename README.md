# Prime Collapse

An iOS idle/incremental game that simulates running a package delivery business while navigating ethical dilemmas in the pursuit of profit.

## Game Overview

In Prime Collapse, you start as a small package delivery operation and gradually build your empire. The game explores the tension between profit maximization and ethical business practices. Your choices impact the moral standing of your company, potentially leading to economic collapse or reform.

## Key Features

- **Incremental Gameplay**: Ship packages manually or automatically with workers and upgrades
- **Ethical Decision System**: Choose between ethical and unethical upgrades that affect your company's moral decay
- **Random Events**: Face unexpected situations with multiple choices that impact your business
- **Multiple Endings**: Discover different game outcomes based on your choices:
  - **Collapse**: Unethical decisions lead to economic collapse
  - **Reform**: Ethical choices create a sustainable business
  - **Loop**: Navigate a specific path to discover a special ending
- **Game Center Integration**: Leaderboards and achievements to track your progress
- **Persistent Progress**: Game state automatically saved using SwiftData

## Game Mechanics

- **Package Shipping**: Tap to ship packages manually, or hire workers for automation
- **Upgrade System**: Invest in improvements with varying ethical implications
- **Moral Decay**: Unethical decisions increase moral decay, while ethical choices decrease it
- **Random Events**: Experience workplace issues, market opportunities, PR events, and regulatory inspections
- **Economic Collapse**: When moral decay reaches 100, your business begins to collapse
- **Automation**: Build a self-sustaining delivery empire with increasing automation rates

## Technical Architecture

- Built with **SwiftUI** using the latest iOS frameworks
- State management via the **Observation** framework
- Data persistence with **SwiftData**
- Game Center integration for social features
- Clean architecture separating game logic, UI, and data models

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.10+
- Game Center account for leaderboards and achievements

## Installation

1. Clone this repository
2. Open `Prime Collapse.xcodeproj` in Xcode
3. Select a device or simulator target
4. Build and run the project

## How to Play

1. Start by tapping the main button to ship packages
2. Earn money with each package shipped
3. Purchase upgrades to automate shipping and increase efficiency
4. Balance ethical and unethical decisions to avoid economic collapse
5. Discover different endings based on your choices

## Project Structure

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

## License

[Your chosen license]

## Contact

[Your contact information] 