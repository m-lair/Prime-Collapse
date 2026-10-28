# Original UI polish — validation

2026-10-28. Based on restored original UI at d9b3482 (visual baseline 71fa982), on codex/holiday-rush.

## Scope

Added a central game home with company progress, Continue Company, and Holiday Rush entry/resume/result state. Kept the original blue gradient, colorful stat panels, circular shipping button, green upgrade ribbon and horizontal upgrades. Consolidated navigation into the company header. Improved spacing, scalable typography, aligned stat panels, purchase contrast and touch targets. Upgrade prices display actual cents instead of truncating them. Decorative shipping effects ignore touches. No artwork, dependencies, model, balance, save-format or coordinator changes.

## Verification

- Final simulator build succeeded on iPhone 17 Pro Max / iOS 27.0. Existing GameCenter, preview and unreachable-catch warnings remain.
- PrimeCollapseTests: 110 passed, zero failures or skips. Test run 2026-10-28T16-57-21; final subsequent changes were text singularization, decorative hit-testing and whitespace; final build and UI walkthrough covered these.
- Company: Continue, manual shipping, return home and retained progress verified.
- Investments: Hire Worker displayed $64.00, purchase increased workers from 1 to 2; next price $81.92. No upgrade calculation changes.
- Decision interruptions: competitor pricing and Market Boom choices presented; choosing an option dismissed the interruption and resumed play.
- Challenge: resumed saved run at 244 packages, continued production, returned to home at 337 packages / 1:00 remaining. Company stayed at 235 packages / $160. Deep link primecollapse://events/holiday-rush reopened the same paused checkpoint.
- Accessibility text size AX5: home scrolls to Continue; company stats stack, shipping label fits; upgrade description, exact price and Buy remain accessible by scrolling. Reduce Motion shipping interaction checked and setting restored.
- iPad Pro 13-inch (M5) / iPadOS 27.0 landscape: home and company inspected; bounded content width, readable stats, shipping and upgrades. Returned both simulators to home.
- git diff --check passed after whitespace cleanup.

## Evidence

Actual simulator screenshots: home.png, company.png, challenge.png, decision.png, home-large-text.png, company-large-text.png, upgrades-large-text.png, ipad-home.png, ipad-company.png. Screenshots represent different moments in the walkthrough, so counters differ.

## Limits

No physical-device or full VoiceOver walkthrough. Endings were covered by existing tests rather than a new full native playthrough. Holiday Rush retains its existing challenge screen styling; this pass focuses on the restored company UI and shared home/navigation. No push, TestFlight upload or publishing performed.
