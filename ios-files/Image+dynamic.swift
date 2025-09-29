import SwiftUI

extension Image {
  static func dynamic(assetNameOrPath: String) -> Self {
    NSLog("[LiveActivity] 🖼️ Attempting to load image: '\(assetNameOrPath)'")

    // Use configurable app group identifier from Info.plist
    guard let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
      NSLog("[LiveActivity] ❌ AppGroupIdentifier not found in Info.plist")
      NSLog("[LiveActivity] 🔄 Falling back to bundle asset: '\(assetNameOrPath)'")

      // Try to load from Asset Catalog first
      if let uiImage = UIImage(named: assetNameOrPath) {
        NSLog("[LiveActivity] ✅ Successfully loaded from Asset Catalog: '\(assetNameOrPath)' - Size: \(uiImage.size)")
        return Image(uiImage: uiImage)
          .renderingMode(.original) // Ensure image renders correctly
      } else {
        NSLog("[LiveActivity] ❌ Failed to load '\(assetNameOrPath)' from Asset Catalog")
      }

      // Fallback to SwiftUI Image initializer
      NSLog("[LiveActivity] 💡 Using SwiftUI Image initializer for: '\(assetNameOrPath)'")
      return Image(assetNameOrPath)
    }
    NSLog("[LiveActivity] Attempting to access app group: \(groupIdentifier)")

    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: groupIdentifier
    ) {
      let contentsOfFile = container.appendingPathComponent(assetNameOrPath).path
      NSLog("[LiveActivity] ✅ App group accessible. Checking path: \(contentsOfFile)")

      if FileManager.default.fileExists(atPath: contentsOfFile) {
        NSLog("[LiveActivity] ✅ File exists at path: \(contentsOfFile)")
        if let uiImage = UIImage(contentsOfFile: contentsOfFile) {
          NSLog("[LiveActivity] ✅ Successfully loaded image from shared container: \(assetNameOrPath)")
          return Image(uiImage: uiImage)
        } else {
          NSLog("[LiveActivity] ❌ File exists but failed to create UIImage from: \(contentsOfFile)")
        }
      } else {
        NSLog("[LiveActivity] ❌ File does not exist at path: \(contentsOfFile)")
      }
    } else {
      NSLog("[LiveActivity] ❌ Cannot access app group '\(groupIdentifier)' - check entitlements and app group configuration")
    }

    NSLog("[LiveActivity] 🔄 Falling back to bundle asset: '\(assetNameOrPath)'")

    // Try to load from Asset Catalog first
    if let uiImage = UIImage(named: assetNameOrPath) {
      NSLog("[LiveActivity] ✅ Successfully loaded from Asset Catalog: '\(assetNameOrPath)' - Size: \(uiImage.size)")
      return Image(uiImage: uiImage)
        .renderingMode(.original) // Ensure image renders correctly
    } else {
      NSLog("[LiveActivity] ❌ Failed to load '\(assetNameOrPath)' from Asset Catalog (fallback)")
    }

    // Final fallback: try the default coffee bean image if we haven't already
    if assetNameOrPath != "default-coffee-bean" {
      NSLog("[LiveActivity] 🔄 Ultimate fallback: trying default-coffee-bean image")
      if let uiImage = UIImage(named: "default-coffee-bean") {
        NSLog("[LiveActivity] ✅ Successfully loaded default-coffee-bean as fallback")
        return Image(uiImage: uiImage)
          .renderingMode(.original)
      }
    }

    // Last resort: return a SwiftUI system image
    NSLog("[LiveActivity] ⚠️ All image loading failed, using system photo icon")
    return Image(systemName: "photo")
      .foregroundColor(.gray)
  }
}
