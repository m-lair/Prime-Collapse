# Original UI restored

Visual baseline: 71fa982, the parent of 7fd8046. The previous attempts incorrectly treated 7fd8046 (which introduced the dispatch-floor redesign) as the original.

Restored the blue gradient, original GameStatsView, circular ShipPackageButton, horizontal UpgradeListView, company settings/dashboard controls and original Holiday Rush screens. Removed the unused GameShell replacement. Company is the entry screen again; Holiday Rush opens from its original entry card and returns to company.

Retained current GameState, HolidayRushSession, save models, coordinator timing/isolation, deep-link handler, terminal guards and lifecycle handling. No model, price, balance, ending or save-schema changes in this correction.

Verification: build/run succeeded on iPhone 17 Pro Max / iOS 27.0. All 110 tests passed with zero failures or skips after removing the unused shell. Test result: test_sim_2026-10-28T16-27-23-604Z_pid64688_c5a35719.xcresult. Simulator verified original controls, manual shipping, challenge entry at 215 packages / 4:38, resumed production, final decision at 4:00, continued production after Keep the agreed pace, and return to company at 205 packages / $194.75. Screenshot is an actual simulator capture.

This correction restores the original presentation; it does not claim a new visual polish pass. Large-text/iPad/physical-device/full VoiceOver checks were not repeated for this restoration. Existing compiler warnings remain. No push, upload or publication.
