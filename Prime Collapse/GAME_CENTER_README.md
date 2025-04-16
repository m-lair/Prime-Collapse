# Game Center Integration for Prime Collapse

This document outlines how Game Center is integrated into the Prime Collapse game.

## Overview

Prime Collapse uses Apple's GameKit framework to provide Game Center features including:

- Player authentication
- Leaderboards for tracking game progress globally
- Achievements for gameplay milestones
- Display of player progress in the game's dashboard

## Setup Requirements

To use Game Center in the app:

1. The Xcode project must have Game Center capability enabled
2. The Info.plist file is configured with Game Center settings
3. You must configure leaderboards and achievements in App Store Connect

## Leaderboards

The game uses the following leaderboards:

- `total_packages_shipped`: Tracks the total number of packages shipped
- `total_money_earned`: Tracks the total money earned in the game

## Achievements

The game includes the following achievements:

- `first_worker_hired`: Unlocked when the player hires their first worker
- `automation_milestone`: Based on automation rate progress (up to 10 packages/sec)
- `ethical_choices`: Based on number of ethical choices made
- `economic_collapse`: Unlocked when the player reaches the economic collapse phase
- `reform_ending`: Unlocked when the player achieves the reform ending

## Implementation Details

### GameCenterManager

The `GameCenterManager` class handles all Game Center functionality:

- Player authentication
- Leaderboard submission
- Achievement reporting
- UI presentation

### Integration Points

Game Center is integrated at these points:

1. **App Launch**: Authentication happens automatically in `Prime_CollapseApp`
2. **Game State Changes**: Updates achievements and leaderboards when game state changes
3. **Dashboard**: Displays player info and buttons to view leaderboards and achievements
4. **Game Save**: Updates scores when the game state is saved

### Testing Game Center

To test Game Center:

1. Use the iOS Simulator's Game Center sandbox environment
2. Sign in with your sandbox account through Settings app
3. Run the app and Game Center authentication should happen automatically

## Troubleshooting

Common issues:

- Authentication failures: Check device is properly signed into Game Center
- Missing leaderboards/achievements: Ensure they are properly configured in App Store Connect
- Score submission failures: Verify network connectivity and authentication status 