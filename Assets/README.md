# Artwork staging

[The supplied asset registry](../BANANA_CORP_ASSET_REGISTRY.md) records planned image IDs and naming conventions. These folders stage source artwork; creating them does not bundle images or claim any planned asset is produced.

| Folder under `Images/` | Category |
| --- | --- |
| `BC` | Corporate branding |
| `VR` | AR/VR headset |
| `OS` | Fictional phone OS |
| `VID` | Video thumbnails |
| `CHAR` | Character references |
| `PHOTO` | Photo Album |
| `NEWS` | News |
| `SOC` | Social X |
| `WEB` | Browser |
| `AI` | Assistant |
| `VRX` | VR Experience |
| `COM` | Communications |
| `PUZ` | Puzzles and evidence |
| `END` | Endgame |

Use stable registry IDs and descriptive stems, such as `BC-001_primary_logo.png`. Empty folders contain `.gitkeep`. Reuse canonical artwork instead of creating duplicate files across categories.

Approved optimized runtime derivatives belong in the existing [app asset catalog](<../Banana Corp/Banana Corp/Assets.xcassets>), using exact catalog names registered in [AppImageAsset.swift](<../Banana Corp/Banana Corp/AppImageAsset.swift>). Keep source/master artwork outside that compiled catalog. Do not move existing app icons, logo or launch images as part of staging. `OS-005` is a reference/deliverable set; eventual app icons need distinct exported image sets.

The [game bible](../BANANA_CORP_GAME_BIBLE.md) remains authoritative for narrative, reveal order and puzzle facts. This registry does not authorize new story beats, Assistant identities or visual glitches. In particular, `CHAR-010`, `AI-006` and other ECHO-07 identity/avatar wording require review: ECHO-07 names a trial record, not a second AI character. Any associated art must represent that research record without redefining it. `AI-001_bana_avatar` is a planned filename, not an approved rename of Banana Assist. The registry's mood-board approval is supplied-document context; no mood-board reference is present here for independent verification.

Keep timestamps, captions, clue IDs and puzzle text in validated structured data rather than relying on generated image text. No artwork placeholders, runtime references, playable media or story unlocks are created by this folder setup.

## Import and reference workflow

1. Produce/review the artwork under its registry prefix; keep its stable ID and descriptive filename stem.
2. Export an optimized derivative and import it into the **existing** app catalog as an image set named exactly after the stem, without the file extension. For example, the future `BC-001_primary_logo.png` becomes image set `BC-001_primary_logo`. Configure scales or a suitable single-scale/vector asset; preserve alpha where needed.
3. After the image set and referenced files exist, add a lower-camel case to `AppImageAsset`, including its registry ID: future case `bc001PrimaryLogo` would map to the exact raw value `BC-001_primary_logo`. This example is a convention, **not a registered or currently available asset**. Preserve names once story content or saved evidence references them.
4. Use `Image(asset: .caseName)` in SwiftUI. This typed initializer performs the normal image-catalog lookup, with no staging paths or filename extensions. Strings live centrally in the enum; screens use cases. The legacy `.legacyLogoBlack` case remains. Five creator-supplied public derivatives are now also registered; see [the integration inventory](../docs/GENERATED_ASSET_INTEGRATION.md) and [hash/provenance manifest](Images/generated-runtime-assets.json). Runtime consumers use those typed cases only after import.
5. Run the hosted `IOSIntegrationTests.testLaunchArtworkAndGeneratedInfoPlist` with Debug/Release on an Apple platform: it checks every registered enum case through the app bundle. Verify compiled catalog/loading on an iPhone and check for duplicate resource copies. Registry entries remain planned until artwork is approved and integrated.

The Xcode source list includes the naming API. `Assets/Images`, this README and the registry are not added to Copy Bundle Resources; Xcode continues compiling the single existing asset catalog. No planned art, generated placeholders or new screen rendering is introduced.

Validation for this setup: 14 staging folders, 132 unique supplied registry IDs, exact existing catalog/file references, unchanged bundle resources/build settings and documentation links were checked. Project structure and the naming enum's Swift 5 typecheck passed; changed Swift files passed syntax parsing. The hosted image-loading test was extended to cover all registered cases. Apple-SDK builds and actual Debug/Release image-loading tests were not run because Xcode is unavailable in this Linux environment.


2026-10-30 integration: five public logo/background/headset/launch/HQ derivatives are imported into the existing asset catalogue. All31 supplied masters remain unchanged. Unmapped portraits/other planned assets remain unintegrated; the ECHO-07 humanoid is excluded. Current SDK/bundle loading results are tracked in [interactive phone expansion](../docs/INTERACTIVE_PHONE_EXPANSION.md). Historical validation above retains its original environment/scope.
