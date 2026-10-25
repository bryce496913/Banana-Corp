# Shared app title clipping repair

The actual physical default accessibility audit in qa-home-validation-20261025 completed Home and failed on the Email title. Its exported affected-element image identifies Email; the finding is text clipping at larger Dynamic Type. That run failed in23.135 seconds.

AppScreenHeader renders OSStoryText with the shared screen-title font inside PhoneShellView’s vertical stack. The candidate preserves the title’s intrinsic vertical size while retaining flexible width. It leaves subtitles, text, display-name overrides, corruption rendering, header traits, navigation, scale, AppState, content IDs and saves unchanged. It uses existing SwiftUI APIs compatible with the iOS18 deployment target.

This is a sizing candidate, not a verified accessibility repair. Native Debug/Release builds and the unchanged public audit across all registered applications are pending. Existing Home candidate builds passed before this separate shared-header edit; they do not establish compilation or audit results for this revision. The Home editing test’s corrected guard also still requires actual execution.
