//
//  Shims.swift
//  Prime Collapse — headless loop simulator
//
//  The headless simulator compiles the REAL game engine source files in place
//  (GameState / Upgrade / UpgradeManager / EventManager / GameEvent) so the
//  simulation can never drift from shipping behavior. The only symbol those files
//  need that lives outside the engine is `GameEnding`, which in the app is declared
//  in `Views/GameEnding/GameEndingView.swift` (a SwiftUI file we intentionally do
//  NOT compile here). This is a standalone copy of just that enum.
//
//  KEEP IN SYNC with the app's `enum GameEnding`.
//

import Foundation

enum GameEnding {
    case collapse
    case reform
    case loop
}
