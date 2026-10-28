# Premium home and shared play validation — October 28, 2026

Implemented the user's selected game home with Continue Company and featured challenges. Both modes share a code-rendered dispatch floor, production HUD and selected-investment tray. No generated artwork was used.

## Automated evidence

110 tests passed, 0 failed, 0 skipped on isolated iPhone 17 Pro Max / iOS 26.5 after the final code changes.

Result: `/Users/marcus/Library/Developer/XcodeBuildMCP/workspaces/Game-9fab573dd6a9/result-bundles/test_sim_2026-10-28T14-43-34-307Z_pid60834_10af978f.xcresult`

Coverage includes production/value agreement, preview immutability, money-dependent rebate preview refresh, result explanations, mode isolation, deep links, pause persistence, terminal state, and no in-session company catch-up after leaving its play surface.

Read-only review found one accessibility scrolling issue; addressed with an accessible scrolling layout, single-column metrics, and wrapping shipping label. No further lifecycle/isolation issues reported.

## Native observations

- Normal launch opens the home with current company totals and a paused Holiday Rush summary.
- Continue Company opens the shared floor. Manual dispatch works. Buying a worker updates workforce, money, price, and automatic rate.
- Home -> Holiday Rush preserves the existing challenge and requires explicit Resume.
- Challenge purchase changed four-worker output to 0.413 packages/sec; next preview was 0.517. Optional payback details reflect remaining active time.
- While shopping, the first decision arrived at exactly 10:00 remaining. The tray dismissed and the challenge paused at Seasonal staffing. Paid training charged $35 and changed morale to 90%; production resumed.
- Returning home preserved main company at 3,804 packages / $3,550 while the challenge had its own 48 packages and 9:46 remaining. Re-entry retained the challenge checkpoint.
- At accessibility-extra-large text, company metrics use one column; scrolling reaches the full wrapped Ship package label and investment control. Text size restored to Large afterward.
- iPad portrait home inspected: centered content, Continue Company and featured Holiday Rush entry readable without overlap.
- Captures are actual simulator output: home.png, challenge.png, large-text-company.png. Earlier feedback-update/result.png records legacy result migration, before the shared-floor visual update.

## Limits

This iteration was verified locally. It has not been uploaded to TestFlight or published. No new full 12-minute human-speed run was completed after this visual refactor; the earlier native run and existing engine outcome tests remain separate evidence. Physical-device testing, full VoiceOver traversal, and iPad landscape are unverified.
