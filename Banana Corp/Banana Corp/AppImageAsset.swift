/// Exact Xcode image-set names for imported, usable artwork only.
/// Future registry cases use lower-camel ID/stem names and the full registry stem as rawValue.
/// Add the image set before registering a case; never register planned/missing artwork.
enum AppImageAsset: String, CaseIterable {
    /// Existing artwork retains its legacy catalog name; it is not yet registry asset BC-001.
    case legacyLogoBlack = "Logo-Black"
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
