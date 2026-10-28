# Holiday Rush event package

Local drafts for Prime Collapse 1.3. No App Store Connect event has been created or submitted by this work.

## Files

- `event-metadata.json`: checked-length event name, descriptions, badge, audience and deep link. Dates and storefronts deliberately remain unselected.
- `event-card.png`: 2064 × 1161, exact 16:9 landscape.
- `event-detail.png`: 1548 × 2752, exact 9:16 portrait.
- `social-capture.png`: 2064 × 2064 square.
- `launch-copy.md`: event copy, social drafts, pilot invitation and review notes.
- `release-checklist.md`: event scheduling, app release and player pilot steps.
- `capture-provenance.json`: actual source screenshot and deterministic crop details.

All media comes from a real simulator capture of the implemented briefing. No generated illustrations, invented gameplay or upscaling. These are preview assets: once event dates are chosen, configure `HolidayRushWindow.json` and recapture the active event experience before submission. Inspect App Store Connect's media overlays/crops as part of the final upload review. The current practice screen accurately reflects the unconfigured event window.

Recreate native exports on macOS with Xcode installed:

```sh
python3 marketing/holiday-rush/export-captures.py \
  --landscape marketing/holiday-rush/captures/briefing-ipad-portrait.png \
  --portrait marketing/holiday-rush/captures/briefing-ipad-portrait.png
```

The supplied landscape asset is a wide crop of the native portrait capture. A landscape gameplay capture can replace it after the remaining native walkthrough. CoreGraphics performs cropping; `sips` verifies pixel dimensions. No package installation or external image service is used.

Official media requirements checked October 27, 2026: https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications
