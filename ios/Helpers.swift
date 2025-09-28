func resolveImage(from string: String) async throws -> String {
  if let url = URL(string: string), url.scheme?.hasPrefix("http") == true {
    // Use configurable app group identifier from Info.plist
    let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String ?? "group.expoLiveActivity.sharedData"

    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: groupIdentifier
    ) else {
      throw NSError(domain: "LiveActivity", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access app group '\(groupIdentifier)'"])
    }
    let data = try await Data.download(from: url)
    let filename = UUID().uuidString + ".png"
    let fileURL = container.appendingPathComponent(filename)
    try data.write(to: fileURL)
    return fileURL.lastPathComponent
  } else {
    return string
  }
}
