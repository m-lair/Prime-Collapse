# Holiday Rush TestFlight — October 28, 2026

- Source pushed: `codex/holiday-rush`, commit `aa5e230607fb7a77ca14895db735da88e99dbe49`.
- Xcode Cloud Default workflow: added a manual start condition restricted to `codex/holiday-rush`, preserving the existing `main` push condition. Added internal TestFlight delivery to Holiday Rush Playtest.
- Cloud build 4 archived successfully with Xcode 27.1. Cloud build: https://appstoreconnect.apple.com/teams/adf57748-d2e8-4dec-9e34-06dc8e2d6d70/xcode-cloud/products/A6F21E6F-0308-4054-A4E4-40723F2343B9/builds/bce64bb1-77c7-4500-8a86-bb594d14c85c/summary
- Version **1.3 (4)** processed in TestFlight. Apple uses cloud build number 4 rather than the local project build number 1.
- Completed the build encryption question with “None of the algorithms mentioned above.” Source imports only Apple frameworks and contains no custom encryption implementation. Missing Compliance cleared.
- Saved English (U.S.) What to Test instructions covering Holiday Rush, pause/resume, decisions, replay and preservation of company progress.
- Created internal group **Holiday Rush Playtest**, automatic distribution disabled, with only the account holder as tester. Explicitly assigned 1.3 (4). Group build status verified **Testing**, expires in 90 days; tester status **Invited**.
- Group: https://appstoreconnect.apple.com/teams/adf57748-d2e8-4dec-9e34-06dc8e2d6d70/apps/6744699777/testflight/groups/84b59caa-be5d-427f-8d27-611dbb4ff6ce/builds
- Installation/acceptance on the tester's physical device has not been observed. No App Store release or in-app event publication performed. Event dates remain unconfigured; free practice is available.

Install Prime Collapse 1.3 (4) through the TestFlight invitation, then open Holiday Rush from the main company and tap Start Challenge.
