func resolveImage(from string: String) async throws -> String {
  NSLog("[LiveActivity] 🔍 resolveImage called with: '\(string)'")

  if let url = URL(string: string), url.scheme?.hasPrefix("http") == true {
    NSLog("[LiveActivity] 🌐 Detected HTTP URL, downloading image...")
    // Use configurable app group identifier from Info.plist
    guard let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
      NSLog("[LiveActivity] ❌ AppGroupIdentifier not found in Info.plist")
      throw NSError(domain: "LiveActivity", code: 2, userInfo: [NSLocalizedDescriptionKey: "AppGroupIdentifier not found in Info.plist"])
    }

    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: groupIdentifier
    ) else {
      NSLog("[LiveActivity] ❌ Cannot access app group '\(groupIdentifier)'")
      throw NSError(domain: "LiveActivity", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access app group '\(groupIdentifier)'"])
    }
    let data = try await Data.download(from: url)
    let filename = UUID().uuidString + ".png"
    let fileURL = container.appendingPathComponent(filename)
    try data.write(to: fileURL)
    NSLog("[LiveActivity] ✅ Downloaded image to: \(fileURL.lastPathComponent)")
    return fileURL.lastPathComponent
  } else {
    NSLog("[LiveActivity] 📦 Not a URL, treating as asset name: '\(string)'")
    return string
  }
}
