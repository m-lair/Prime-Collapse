> Superseded by ../original-restored/validation.md. The actual pre-redesign visual baseline is 71fa982.

# Restrained polish correction — 2026-10-28

Supersedes the visual direction in premium-polish after user rejection of the illustrated warehouse redesign.

Restored home, challenge presentation, flat dispatch floor and investment structure from 7fd8046. Removed DispatchFloorDrawing, DispatchParcel and GameActionStyle. No changes to balance, coordinator, saves, catalog, decisions or endings.

Small retained improvements: shipping press feedback and light haptics; manual parcel animation keyed only to manual taps; full accessibility text in the floor; removal of decorative parcel overlap at accessibility sizes; stacked challenge goal/timer and ethics at accessibility sizes; readable investment button and preview contrast; morale change shown in the existing investment details; company content bounded to 740 points on iPad.

## Verification

- Final iPhone 17 Pro Max / iOS 27 build and launch succeeded (15:53:45 build log). Only existing preview-layout warnings in this incremental build.
- Company manual shipping 100 → 102 across two taps, automatic production continued afterward.
- Investments opened with existing catalog and pricing.
- Holiday Rush retained 182 packages / 5:38 on entry; explicit Resume advanced to 215 / 4:38. Company and challenge checkpoints remained independent.
- AX5 inspected on device: fixed parcel/text overlap, confirmed full Ship package label and scrollable content. Text size restored to Large.
- iPad Pro 13-inch / iPadOS 27 landscape inspected: company width bounded and both actions visible.
- git diff --check passed. No new gameplay changes; prior 110-test pass applies to unchanged model code. Tests were not rerun for this presentation correction.

## Limits

No new complete challenge run, physical-device haptic assessment or full VoiceOver traversal. Screenshots are actual simulator captures. No push, upload or publication.
