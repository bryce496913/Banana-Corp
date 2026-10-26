# Shared app title clipping repair

The actual physical default accessibility audit in qa-home-validation-20261025 completed Home and failed on the Email title. Its exported affected-element image identifies Email; the finding is text clipping at larger Dynamic Type. That run failed in23.135 seconds.

AppScreenHeader renders OSStoryText with the shared screen-title font inside PhoneShellView’s vertical stack. The candidate preserves the title’s intrinsic vertical size while retaining flexible width. It leaves subtitles, text, display-name overrides, corruption rendering, header traits, navigation, scale, AppState, content IDs and saves unchanged. It uses existing SwiftUI APIs compatible with the iOS18 deployment target.

The current header revision passed actual Debug and Release generic iOS SDK builds with Xcode26.5, plus actual built-bundle executable/compiled-assets/exact-resource checks. Both products retain MinimumOSVersion18.0. Sources remained identical to the recorded inventory throughout. These generic products are unsigned: they establish compilation and packaging, not installation or gameplay. Evidence is retained in validation/header-generic-20261025, including both build logs, product-check logs, source inventory and results.json.

The dedicated physical build attempt qa-header-validation-20261025 exited70 before Swift compilation because the selected phone destination was unavailable. Earlier qa-home-editing-b-20261025 passed signed Debug product checks and installation but timed out before any test case started. Both attempts are retained and must not be reused. The creator has been asked to reconnect USB/unlock.

The unchanged default audit across all registered applications and the corrected Home editing/relaunch test remain unexecuted on this header revision. This is not yet a verified accessibility repair. Require fresh signed products, exact built-target mapping, fresh QA identity and actual audit/navigation/editing results before merging.
