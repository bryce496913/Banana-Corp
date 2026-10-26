# Browser and Email UI modernization

Authorized by the creator on2026-10-26; bible1.13 section14 records the control contract.

Browser now has an editable address/search bar, Go, Back, Home and Refresh. Exact authored local paths open only from the shared store’s currently available authorized web items. Other input filters currently available titles, subtitles, source labels and paths. Protected-access panels keep the same Browser chrome while retaining their existing authorized resource controls; no address enumerates hidden resources or bypasses puzzles. The root Back control is explicitly disabled. Page links and source reads retain their existing actions.

Email uses a sender avatar/subject/metadata inbox layout, working search, unread filtering and Refresh. Message details retain sender/recipient headers, authored body and attachments, Preserve Evidence and existing read IDs. Inbox returns through centralized AppState. It retains the established deliberate inbox reconciliation boundary.

Refresh re-queries the local view state and reports local refresh, with no network request or story action. In details the engaged version is retained and availability is rechecked. Search/filter/refresh do not mark content read. No delete/archive/compose/send controls imply unsupported mail actions.

AppState owns guarded current-app root requests; OSNavigationState tracks only a transient content-root revision. ContentView recreates that app’s local NavigationStack without an OS route transition. Back uses the existing dismissal path. Cross-app links retain their current app container and the Home label identifies that container. Home screen gestures, route IDs, evidence/saves and all story definitions remain unchanged.

Validation: all ten applicable model checks passed, including navigation wrong-route and inactive guards. Final real Debug and Release Apple SDK builds and actual bundle/resource checks passed with deployment target18.0. Products are unsigned generic iOS builds; no new simulator/physical UI or campaign pass is claimed. The earlier shared-header/Home candidate tests are not acceptance for this UI revision. Campaign playthroughs are paused at the creator’s request.
