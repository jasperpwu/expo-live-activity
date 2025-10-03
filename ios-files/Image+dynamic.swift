import SwiftUI

extension Image {
  static func dynamic(assetNameOrPath: String) -> Self {
    NSLog("[LiveActivity] 🖼️ Attempting to load image: '\(assetNameOrPath)'")

    // Try to load from Asset Catalog
    if let uiImage = UIImage(named: assetNameOrPath, in: Bundle.main, with: nil) ?? UIImage(named: assetNameOrPath) {
      NSLog("[LiveActivity] ✅ Successfully loaded from Asset Catalog: '\(assetNameOrPath)' - Size: \(uiImage.size)")
      return Image(uiImage: uiImage)
        .renderingMode(.original)
    }

    NSLog("[LiveActivity] ❌ Failed to load '\(assetNameOrPath)' from Asset Catalog")

    // Fallback to default image if available
    if assetNameOrPath != "default-coffee-bean" {
      NSLog("[LiveActivity] 🔄 Trying default-coffee-bean as fallback")
      if let uiImage = UIImage(named: "default-coffee-bean", in: Bundle.main, with: nil) ?? UIImage(named: "default-coffee-bean") {
        NSLog("[LiveActivity] ✅ Successfully loaded default-coffee-bean as fallback")
        return Image(uiImage: uiImage)
          .renderingMode(.original)
      }
    }

    // Last resort: system icon
    NSLog("[LiveActivity] ⚠️ All image loading failed, using system photo icon")
    return Image(systemName: "photo")
  }
}
