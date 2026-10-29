# Shared UI accessibility repair

## Native evidence

On 2026-10-29, a fresh isolated QA installation on the connected iPhone 14 Pro (iOS 27.0.1) reached Home and all fifteen registered app screens using normal controls. The diagnostic inventory retained every public accessibility finding; it failed with 25 findings and confirmed QA app termination. This is an issue inventory, not acceptance or a campaign playthrough.

The findings covered Mail/Settings text contrast, Browser address and News title clipping, Preserve Evidence/Settings/Assistant button targets, primary button contrast, and Pong text-size caps. Mail search and the covered Home welcome label were not reported in this inventory; their absence does not establish full audit acceptance.

Evidence remains locally in `validation/home-natural-geometry-20261029/`, including the exact tested source, signed products, result bundle and issue attachments.

## Candidate

- Keep the retained Home at natural scale once an app is active; retain transition scaling.
- Let Browser address input and News row titles grow vertically. Retain the Browser Go action and exact accessibility identifier; native tests accept its TextField or TextView role.
- Give the identified action labels actual 44-point minimum height and rectangular hit regions.
- Strengthen Mail subtitle and Settings empty-state text contrast and darken purple primary-button fills.
- Remove Pong's two Dynamic Type caps, explicitly approved by the creator on 2026-10-29. No physics, controls, scoring or story gate changes.

No catalogue versions, saved evidence, progression contracts, puzzle values or ending requirements change. The normal all-types public audit remains unsuppressed. A separate opt-in diagnostic inventory records failures and cannot substitute for acceptance.

## Validation status

Reviewed candidate signed Debug/Release Apple SDK app and XCTest builds passed. Live strict signatures, existing profile, resource bytes, deployment target and native-test mapping checks passed. The QA-only update preserved its exact saved state. The default physical audit is pending device unlock; no acceptance result yet. Preserve failed-run evidence while issues remain unresolved. A full story playthrough and spoken VoiceOver/gesture review remain separate checks.
