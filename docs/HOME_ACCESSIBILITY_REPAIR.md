# Home accessibility repair — validation record

The physical default accessibility audit reported clipped text in the Home welcome title. `HomeScreenView` constrained its header to 44 points while the title uses Dynamic Type. The candidate uses a 44-point minimum and preserves the title's wrapped vertical height. Catalogue copy, Explore navigation, progression, evidence, IDs and gestures are unchanged.

## Executed checks

- Xcode 26.5 Debug builds and product/signature/resource checks passed for the candidate on isolated QA identities.
- The real Release SDK build and product checks passed in `validation/physical-campaign-qa-20261021/qa-home-release-20261024/`; this is not a Release gameplay or accessibility pass.
- The existing physical 15-app navigation smoke test passed 1/0/0 in 79.644 seconds in `validation/physical-campaign-qa-20261021/qa-home-smoke-20261024/` on 2026-10-25.
- Required Foundation checks for restricted access, Act Two, first anomaly, Act One, evidence, content, progression, Home layout, navigation and presentation passed. Restricted macro/cache failures were retained and rerun using the normal host toolchain and a writable cache. Static project and portable mocked runner checks passed; neither replaces native UI validation.

## Open accessibility finding

The initial physical default audit failed 0/1/0 in 16.322 seconds with Text clipped; the associated element image identifies the welcome title. After the two-line candidate, the default audit reported a different Home issue, Element has no description (0/1/0 in 16.111 seconds). The clipped-title finding was not reported in that run, but the full audit did not pass.

A proposed label on the scroll container did not resolve the unnamed-element finding (0/1/0, 15.048 seconds). That change was removed. An isolated diagnostic using public issue metadata, always returning false to retain normal failure reporting, identified an empty leaf Other with no label/identifier at (20,179,353,488), separate from the scroll container and individual app controls. This diagnostic failed 0/1/0 in 17.447 seconds, as expected; it is not acceptance coverage.

A single-factor scratch experiment removes only the whole-grid viewport drop destination. AppState already rejects Home drops outside editing; the target remains registered in normal mode. This is a hypothesis, not an established cause. Icon/dock targets, background taps and production sources remain unchanged by the experiment. Its result must identify whether the leaf disappears before changing production drop registration.

## Required completion

Keep the repair draft until focused clipping verification, the remaining Home semantics issue, and appropriate native regressions are resolved. Preserve unsuppressed audit reporting. If edit-mode target registration changes, verify real edit/Done, drag/drop, outside-tap exit, persisted arrangement and normal app navigation. Full default audit, simulator input reliability, iOS 18 runtime coverage and progressed-story accessibility remain separate gates.

The eight physical campaign passes and presentation-control pass predate this layout-only candidate and remain source-qualified. No complete-game or human playtest readiness claim is made.
