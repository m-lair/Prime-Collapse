# Holiday Rush release and pilot checklist

## Local package
- Verify the final goal, time and decisions against event copy and artwork.
- Run ending, persistence, challenge and routing tests.
- Validate landscape card and portrait detail dimensions and composition.
- Verify cold/warm deep links, onboarding handoff, main save preservation, pause/resume, result/retry and share/export on simulator and physical device.

## Event configuration before submission
- Select exact start/end dates, storefronts and time zone with the Account Holder/app owner. No dates have been selected by this package.
- Configure the identical participation window in the app resource and App Store Connect; at most 31 days. A dated completion badge requires completion within that window. Outside it, the challenge remains available as practice.
- Choose event promotion start, at most 14 days before the start.
- Recheck Paid Apps Agreement and other release blockers; Account Holder accepts any new agreement personally.
- Create the Challenge event record, add the checked-in metadata and artwork, and test its deep link using the actual candidate build.
- Upload/distribute the candidate through the existing signing/release process. Confirm build processing and TestFlight distribution independently.
- Submit event and app update for review when approved for release. Confirm event approval and public availability separately.
- Replace the placeholder public launch link with the App Store event detail URL. Publish posts only after the release is confirmed.

## Player pilot
- Recruit a small group of new and returning players; record the environment/build and counts, not just percentages.
- Observe first comprehension, first decision, completion/failure and voluntary retry.
- Ask for a diagnostic export only with each tester's consent. Exports contain local gameplay records, not identifiers or account data; inspect actual payload before distribution.
- Ask whether they want more challenges and why. This is interest feedback, not willingness-to-pay evidence.
- Review aggregated results manually. Local logs and App Store event discovery metrics do not supply aggregate in-game completion for public players.
- Separately decide on aggregate analytics before claiming a public-scale demand test or adding a third-party analytics service.

## Official references
Checked October 27, 2026:
- https://developer.apple.com/app-store/in-app-events/
- https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications

Card: opaque PNG/JPEG, 16:9, 1920×1080 to 3840×2160.
Detail: opaque PNG/JPEG, 9:16, 1080×1920 to 2160×3840.
Event name <=30, short description <=50, long description <=120 characters.
