# Home accessibility fixes — validation in progress

The physical default audit found clipped welcome text, an unnamed leaf over the Home grid, and clipped Explore text. The candidate makes three focused changes in HomeScreenView:

- Let the welcome header grow above 44 points and preserve its wrapped title height.
- Register the transparent background tap area only while editing, when it can exit editing.
- Give Explore an explicit vertically expanding label with its 44-point minimum inside the button.

All four drop targets, wording, navigation actions, centralized AppState ownership, story content, evidence and saved IDs remain unchanged. A new guarded XCTest uses real long presses and drag/drop to verify grid reordering, Done, persistence across process relaunch, a verified blank-area tap to exit editing, and subsequent normal navigation. It does not inject state, change saves directly or use app launch flags.

## Actual evidence

| Check | Result and scope |
| --- | --- |
| Original physical default audit | Failed on clipped welcome text, 0/1/0,16.322s. |
| Two-line wrapping candidate | Debug and Release SDK builds/product checks passed; existing 15-app physical navigation test passed 1/0/0,79.644s. Full audit next reported an unnamed leaf. |
| Public issue-node diagnostic | Captured an empty leaf Other at (20,179,353,488), separate from the scroll container and app buttons. Findings remained failures. |
| Isolated viewport drop removal | Failed with the same unnamed leaf, 0/1/0,20.385s. This hypothesis was rejected; production drop targets were retained. |
| Isolated edit-only background | Home audit completed and advanced to Email. Full diagnostic then failed on Explore text, 0/1/0,26.817s. This supports the background registration repair, not a full audit pass. |
| Current combined candidate | Actual Debug SDK build, signatures/resources, exact target mapping, fresh identity and separate installation passed. Exact three-test run is pending device unlock. |
| Current Release build | Prepared; not yet executed. Earlier Release success covers the wrapping-only revision. |

The Explore finding resolves in the inactive 0.99-scale Home layer while Email is open. This establishes audit/XCTest query reachability despite the existing hiding guard, not ordinary VoiceOver exposure or a navigation/scale defect. Navigation and scale behavior were not changed.

Required model checks passed for the wrapping revision; Home layout, navigation and presentation checks passed again during this repair. Static project and mocked runner checks passed. These do not replace native UI validation.

A no-build focused clipping attempt failed before auditing with CoreDevice error10004 (launch process ID unavailable). Exact source/product integrity passed; it supplies no clipping result. An earlier asset compiler stall was interrupted, its owned children alone terminated, and logs/samples retained; a fresh diagnostic build subsequently succeeded.

## Completion gate

The fresh combined run must report exactly three passes, no failures/skips, correct identities and intended order: default public audit, 15-app navigation, then the fresh-layout editing test. Audit findings are not suppressed. Run the current Release SDK/product checks and inspect edit-mode behavior before merging.

Eight physical campaign paths and presentation controls previously passed on source-qualified QA builds; those passes predate this Home candidate. Simulator reliability, iOS18 runtime coverage, progressed-story accessibility, full Act4/Act5/endings and human playtest readiness remain separate open work.
