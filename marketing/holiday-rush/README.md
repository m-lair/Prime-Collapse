# Holiday Rush event package

Local drafts for Prime Collapse 1.3. No App Store Connect event has been created or submitted by this work.

## Files

- `event-metadata.json`: checked-length event name, descriptions, badge, audience and deep link. Dates and storefronts deliberately remain unselected.
- `event-card.png`: 2752 × 1548, exact 16:9 landscape.
- `event-detail.png`: 1449 × 2576, exact 9:16 portrait.
- `social-capture.png`: 2064 × 2064 square.
- `launch-copy.md`: event copy, social drafts, pilot invitation and review notes.
- `release-checklist.md`: event scheduling, app release and player pilot steps.
- `capture-provenance.json`: actual source screenshot and deterministic crop details.

All media comes from real simulator captures of the implemented challenge decisions. No generated illustrations, invented gameplay or upscaling. These are preview assets: once event dates are chosen, configure `HolidayRushWindow.json` and recapture the active event experience before submission. Inspect App Store Connect's media overlays/crops as part of the final upload review. The media shows the free challenge, without promising a dated badge before an event window is configured.

Recreate native exports on macOS with Xcode installed:

```sh
python3 marketing/holiday-rush/export-captures.py \
  --landscape marketing/holiday-rush/captures/staffing-ipad-landscape.png \
  --portrait marketing/holiday-rush/captures/priority-ipad-portrait.png \
  --portrait-top 176
```

The landscape card uses the seasonal-staffing decision in landscape; the portrait and social assets use the priority-shipment decision in portrait. CoreGraphics performs cropping; `sips` verifies pixel dimensions. No package installation or external image service is used.

Official media requirements checked October 27, 2026: https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications
