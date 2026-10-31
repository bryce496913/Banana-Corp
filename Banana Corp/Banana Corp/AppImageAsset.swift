/// Exact Xcode image-set names for imported, usable artwork only.
/// Future registry cases use lower-camel ID/stem names and the full registry stem as rawValue.
/// Add the image set before registering a case; never register planned/missing artwork.
enum AppImageAsset: String, CaseIterable {
    /// Existing artwork retains its legacy catalog name; it is not yet registry asset BC-001.
    case legacyLogoBlack = "Logo-Black"

    // Creator-supplied public marketing illustrations; no story unlocks or clue data.
    case bc001PrimaryLogo = "BC-001_primary_logo"
    case bc004CorporateBackground = "BC-004_corporate_background"
    case vr001HeadsetHero = "VR-001_headset_hero"
    case vr006HeadsetLaunchDisplay = "VR-006_headset_launch_display"
    case photo001HQExterior = "PHOTO-001_hq_exterior"
}

#if canImport(SwiftUI)
import SwiftUI

extension Image {
    /// Typed catalog lookup, not a path into source-art staging folders.
    init(asset: AppImageAsset) {
        self.init(asset.rawValue)
    }
}
#endif
