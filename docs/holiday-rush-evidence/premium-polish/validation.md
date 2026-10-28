> Superseded by ../original-restored/validation.md. The actual pre-redesign visual baseline is 71fa982.

> Superseded: the user rejected this visual direction. See ../restraint-correction/validation.md for the restored baseline and small polish changes.

# Dispatch-floor polish — October 28, 2026

Based on the approved premium game direction and commit `7fd8046` on `codex/holiday-rush`. The working tree was clean before this pass.

## What changed

The baseline was built and run before edits. Its repeated package counters, large empty space above the floor, competing orange actions, flat conveyor, dense challenge briefing, and accounting-heavy investment panel made the experience feel unfinished.

- A dimensional, entirely code-drawn loading dock now anchors home and both play modes: parcels, outbound bay, conveyor rails, pallet stock, and operators representing up to six workers. Existing real workforce/production state drives activity.
- Manual shipping has its own parcel dispatch and light sensory feedback; automatic production moves the belt. Reduced Motion stops conveyor travel and replaces manual travel with fading. Home and paused challenges remain still.
- The shared HUD prioritizes balance, production, ethics/morale, and the challenge objective. Package totals live on the floor rather than appearing twice. A single orange dispatch action contrasts with the quieter investment control.
- Investments use readable category controls, a selected upgrade with production before/after and actual ethics/morale previews, explicit locked/unaffordable states, and purchase acknowledgement. Detailed income/payback stays behind disclosure. Selecting a row scrolls its details into view.
- Challenge briefing, paused floor, decisions, and replay use the same type, palette, and controls. The next decision is a relative countdown; paid-option cash is visible. A decision acknowledgement clears after five seconds using the existing update loop.
- Large text uses a single-column HUD and stacked floor heading, with scrollable controls. Tablet content is bounded and the scene preserves its aspect ratio.

No generated imagery, new dependencies, catalog/price changes, progression rules, save schema changes, or coordinator changes. The preview additions use the existing copied-state purchase simulation; no live game mutation is introduced.

## Verification

- 110 tests passed, 0 failed, 0 skipped on iPhone 17 Pro Max / iOS 26.5. The existing preview-versus-purchase test now also checks the displayed ethics and morale values. Tests cover save round trips, challenge isolation, explicit resume, deep links, decision boundaries, upgrades, endings and production.
- Final test result: `/Users/marcus/Library/Developer/XcodeBuildMCP/workspaces/improve-prime-collapse-s-ui-so-66b68c5fd557/result-bundles/test_sim_2026-10-28T15-11-58-542Z_pid64688_d56bbbbe.xcresult`.
- Native walkthrough on iPhone 17 Pro Max / iOS 27.0: home, company dispatch, challenge start, manual shipping, worker purchase, training preview, timed decision, home/re-entry, saved challenge relaunch, deep link, background/foreground, maximum accessibility text, and Reduce Motion.
- Worker purchase changed challenge production from 0.310 to 0.413 packages/sec and the next preview to 0.517. Basic Training showed 0.413 → 0.491 and morale 80% → 90%.
- At 10:00 remaining, Seasonal staffing dismissed the investment tray and paused at 49 packages. Paid training charged $35, set morale to 90%, and resumed production. Returning home left company and challenge totals independent.
- Relaunch and `primecollapse://events/holiday-rush` restored the paused checkpoint rather than starting/resetting. Backgrounding also required explicit Resume.
- At the largest accessibility text size (AX5), the goal, counters and action labels wrapped; scrolling reached Resume. Text size restored to Large. Reduced Motion verified with working manual shipping and static conveyor; setting restored off.
- iPad Pro 13-inch / iPadOS 27.0: home and company inspected in portrait; company shipping inspected in landscape with both actions visible.
- Palette checks: label on floor 8.71:1; teal on ink 5.91:1; ink on orange 6.08:1. Small floor status text uses label color because teal on floor was only 3.63:1.

## Issues found and fixed during walkthrough

- Applied button shadow to the background shape, removing unwanted text shadows.
- Kept disabled purchase labels light and retained an explicit cash shortfall instead of dimming them into illegibility.
- Stacked the floor status/title at accessibility sizes, avoiding mid-word wrapping. Removed decorative shipping icons at accessibility sizes and stacked the company team footer; confirmed the full Ship package label at AX5.
- A separate optional-ID SwiftUI task for acknowledgement expiry coincided with the active challenge loop stopping after Resume. Removed that extra task and folded acknowledgement expiry into the existing clock loop. Native re-entry then advanced from 9:40 to 8:52 with automatic production, and background/foreground Resume advanced from 8:38 to 8:37. This UI lifecycle issue was not detected by the model-only unit suite.

- Second native decision: The delivery backlog arrived at 7:00 / 136 packages. Paid overtime charged $65 and raised morale to 100%. The acknowledgement disappeared and play continued to 6:31 / 152 packages. Final re-entry advanced again from 6:21 to 6:13.
- Company checkpoint survived reinstall/relaunch at 14 packages / $13 while challenge remained at 158 packages / 6:21. Subsequent company play did not advance the paused challenge.
- Final build after contrast and AX5 icon/footer adjustments passed; those view-only adjustments were verified in the simulator. `git diff --check` passed.

## Captures

`home.png`, `company.png`, `challenge.png`, and `large-text-company.png` show the final phone presentation. `investments.png`, `decision.png`, `challenge-resume.png`, `large-text-resume.png`, `ipad-home.png`, and `ipad-landscape.png` document the walkthrough; the latter captures precede the final floor-status contrast/icon refinements. All are raw simulator PNGs.

## Limits

No physical-device haptic assessment, full VoiceOver traversal, or complete 12-minute manual run. Endings/results remain covered by engine tests rather than a fresh native run to each ending. Legacy company events, settings, detailed dashboard and onboarding were not redesigned in this bounded pass. Existing preview/Game Center warnings remain outside this change. No push, TestFlight upload or publication.

Screenshots in this folder are actual simulator captures, not mockups.
