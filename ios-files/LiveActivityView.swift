import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  struct ConditionalForegroundViewModifier: ViewModifier {
    let color: String?

    func body(content: Content) -> some View {
      if let color = color {
        content.foregroundStyle(Color(hex: color))
      } else {
        content
      }
    }
  }

  struct LiveActivityView: View {
    let contentState: LiveActivityAttributes.ContentState
    let attributes: LiveActivityAttributes

    var progressViewTint: Color? {
      attributes.progressViewTint.map { Color(hex: $0) }
    }

    var body: some View {
      VStack(alignment: .leading) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(contentState.title)
              .font(.title2)
              .fontWeight(.semibold)
              .modifier(ConditionalForegroundViewModifier(color: attributes.titleColor))

            if let subtitle = contentState.subtitle {
              Text(subtitle)
                .font(.title3)
                .modifier(ConditionalForegroundViewModifier(color: attributes.subtitleColor))
            }
          }

          Spacer()

          resizableImage(imageName: {
            let imageName = contentState.imageName ?? "default-coffee-bean"
            if contentState.imageName == nil {
              NSLog("[LiveActivity] Using default coffee bean image for banner")
            } else {
              NSLog("[LiveActivity] Using custom image for banner: \(contentState.imageName!)")
            }
            return imageName
          }())
            .frame(maxHeight: 64)
        }

        if let date = contentState.timerEndDateInMilliseconds {
          Text(timerInterval: Date.toTimerInterval(miliseconds: date))
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.leading)
            .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
        } else if let progress = contentState.progress {
          ProgressView(value: progress)
            .tint(progressViewTint)
            .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
        }
      }
      .padding(24)
    }
  }

#endif
