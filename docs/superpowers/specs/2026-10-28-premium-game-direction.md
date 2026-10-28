# Prime Collapse: unified game experience

Status: researched design direction, October 28, 2026. The user rejected Holiday Rush feeling like a separate form and asked for challenges to be part of the app's main entry and for a more premium game experience. This supersedes the long-form challenge UI direction. The user approved a game home screen with Continue Company and featured challenges.

## Observed problem

The company screen uses a bright blue shipping button, gradient stats and a horizontal upgrade carousel. Holiday Rush opens a separate full-screen NavigationStack with a long vertical upgrade list. The added production feedback improves information but increases text density. The two modes do not feel like the same game.

A premium direction must improve the main game and challenge flow together. Merely adding a launch menu would leave that inconsistency intact.

## Recommended player flow

```text
Launch → game home
           ├─ Continue company → shared shipping play surface
           └─ Holiday Rush → brief objective → same shipping play surface
                                                 ├─ investments tray
                                                 ├─ workforce decision moment
                                                 └─ result / retry / home
```

Returning players get one-tap Continue. Holiday Rush is a first-class mode at home, with actual saved progress or last result, not a banner inside company statistics. Avoid extra navigation layers for a single challenge. Show future challenges only when they exist.

Entry placement and the shared gameplay presentation are implemented together.

## The visual identity: a dispatch floor

Make the shipping operation the memorable element. Use a code-rendered conveyor/loading area with readable parcels and a clear dispatch interaction. Worker count and automation should change visible activity; successful shipping should move a parcel and update its destination/count. This represents actual actions and state, not an unrelated animated background.

Use existing approved app identity and assets. Proposed UI palette: ink `#182329`, loading-floor gray `#35464D`, carton `#C79B6E`, label `#F4F1E8`, dispatch orange `#E78836`, workforce teal `#6AA99A`. Validate contrast before implementation. Orange identifies shipping/actions, teal workforce health; color is always accompanied by text or shape. Keep the palette consistent across modes.

Use the system rounded typeface for title/action identity and plain system text for readable explanations. Tabular digits belong on live counters. Establish one large action, one mode objective and quiet supporting controls. Remove competing banners, heavy glow, nested rounded panels and decorative metadata strings. Do not replace them with another collection of generic cards.

All proposed new visuals are implemented as SwiftUI shapes/Canvas and motion in code. No generated illustration or purchased asset pipeline is required. Optional future audio needs an approved source; no synthetic music or audio asset generation is implied.

## Home layout

```text
Prime Collapse                         settings

[ Dispatch floor / actual company activity ]

Continue company
Saved company summary, one short line

Holiday Rush
12-minute challenge · best / paused / new
Play / Resume
```

Keep company and challenge visually related but give Continue priority. A featured challenge receives its own restrained seasonal treatment within the same world. With no scheduled event window, call Holiday Rush a free practice challenge; do not show a fabricated countdown or badge promise.

## Shared play surface

The play surface is visually dominant. A compact HUD retains packages, money and workforce health; the challenge adds its timer and objective to the same positions. Put the production comparison near the objective when needed, with a clear disclosure for full forecasting. Keep explanatory paragraphs outside the primary play area.

Shipping remains a simple, thumb-reachable interaction with an accessible named button. Touching the dispatch area can share the action, but gestures must not become the only way to play. Direct response includes a parcel movement and a restrained haptic, with reduced-motion behavior.

Investments open a compact tray organized into Workers, Process and Automation. The selected investment shows price, current→after output and relevant ethics/morale changes. Income payback and the detailed forecast are secondary information. A long passive-income payback is not presented as proof an upgrade is bad: this challenge's goal is package volume. Keep the existing catalog and prices; do not silently curate a single winning strategy.

Decisions become clear paused moments in the dispatch floor: one situation, three legible tradeoffs, and immediate acknowledgement of the consequence. Preserve the current decision timing and explicit affordability feedback. An upcoming paid-option reserve belongs in context near the decision countdown, rather than repeating a paragraph beside every action.

Results summarize the outcome first, then unmet requirements and one useful direction for retry. Detailed stats remain available. The existing 778-package run should say workforce goals met / 722 packages short, without pretending to know the one cause of that shortfall.

## Architecture and invariants

- Add a root mode coordinator for home, company and challenge. Keep company and Holiday Rush state/save slots distinct.
- Extract shared shipping-stage, HUD, investment-tray and decision presentation components. Different mode objectives are configuration, not separate visual products.
- Exactly one gameplay loop may advance. Home pauses both; switching mode saves/pauses the previous mode. Return/resume, backgrounding, terminal-company handling and deep links need explicit regression coverage.
- Preserve `primecollapse://events/holiday-rush`: it selects the challenge and shows briefing, paused run or result; it never silently starts or resets.
- Reuse the tested automatic-rate, upgrade-preview and result-feedback calculations. Do not carry forward the long-form layout merely because its calculations pass tests.
- No goal, timer, upgrade effect or price changes in the presentation pass. No fabricated events, leaderboards, currencies or monetization surfaces.

## First implementation slice and acceptance

Build the main game home and the shared shipping stage for company + Holiday Rush first. Then add the investment tray and decision/result presentation. Review actual simulator screens before expanding the design system. This is a coherent presentation refactor, not a new game engine.

Success criteria:

1. Company and Holiday Rush can each be reached directly from home and share recognizable controls and visual hierarchy.
2. A normal play screen fits without browsing a vertical shop to take the main action or read the objective.
3. Selecting an investment reveals its useful numbers without filling the whole game with per-card accounting text.
4. Actions visibly affect the shipping operation; optional motion pauses when inactive and respects reduced motion.
5. Save isolation, explicit resume, terminal outcomes, deep links and background timing retain their verified behavior.
6. Phone and iPad layouts, larger text and screen-reader navigation remain usable. Physical touch/haptic quality is checked separately from simulator evidence.
7. No TestFlight upload or public event publication is claimed from a local visual prototype.

## Research and limits

- Apple's [Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games) recommends teaching in the game's context, quick access to play, legible layouts and device-appropriate controls. Its [Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) guidance supports direct interaction and reducing unnecessary control overlays. These principles inform the shared-stage proposal; Apple does not prescribe this particular home layout.
- Dinosaur Polo Club's [Mini Motorways concepting retrospective](https://dinopoloclub.com/2023/07/23/behind-the-scenes-concepting-mini-motorways/) documents iterations toward a recognizable visual language, including road, parking and terrain details. It supports iterating the game's own visual vocabulary; it is not evidence that copying their style will improve Prime Collapse.

This is an expert design proposal grounded in current code/UI observation and primary references. Premium perception, preference and retention require review of the actual revised game and player testing. No claim of revenue or retention improvement is supported yet.
