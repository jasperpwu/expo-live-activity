import SwiftUI

func resizableImage(imageName: String) -> some View {
  // Temporary: Show a colored rectangle to test if the view is working
  Rectangle()
    .fill(Color.green)
    .overlay(
      Text("IMG: \(imageName)")
        .foregroundColor(.white)
        .font(.caption)
    )

  // Original image code - commented out for testing
  /*
  Image.dynamic(assetNameOrPath: imageName)
    .resizable()
    .scaledToFit()
  */
}
