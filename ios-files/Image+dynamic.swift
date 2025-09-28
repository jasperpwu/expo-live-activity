import SwiftUI

extension Image {
  static func dynamic(assetNameOrPath: String) -> Self {
    NSLog("[LiveActivity] Attempting to load image: \(assetNameOrPath)")

    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.expoLiveActivity.sharedData"
    ) {
      let contentsOfFile = container.appendingPathComponent(assetNameOrPath).path
      NSLog("[LiveActivity] Checking shared container path: \(contentsOfFile)")

      if let uiImage = UIImage(contentsOfFile: contentsOfFile) {
        NSLog("[LiveActivity] ✅ Loaded image from shared container: \(assetNameOrPath)")
        return Image(uiImage: uiImage)
      } else {
        NSLog("[LiveActivity] ❌ Image not found in shared container: \(assetNameOrPath)")
      }
    } else {
      NSLog("[LiveActivity] ❌ Failed to access shared container for image: \(assetNameOrPath)")
    }

    NSLog("[LiveActivity] 🔄 Falling back to bundle asset: \(assetNameOrPath)")
    return Image(assetNameOrPath)
  }
}
