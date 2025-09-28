import SwiftUI

func resizableImage(imageName: String) -> some View {
  Image.dynamic(assetNameOrPath: imageName)
    .resizable()
    .scaledToFit()
    .background(Color.red.opacity(0.3)) // Debug: red background to see if image area exists
    .overlay(
      Rectangle()
        .stroke(Color.blue, lineWidth: 2) // Debug: blue border to see exact bounds
    )
}
