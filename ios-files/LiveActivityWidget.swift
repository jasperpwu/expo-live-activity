import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String?
    var timerEndDateInMilliseconds: Double?
    var progress: Double?
    var imageName: String?
    var dynamicIslandImageName: String?
    var dynamicIslandText: String?
  }

  var name: String
  var backgroundColor: String?
  var titleColor: String?
  var subtitleColor: String?
  var progressViewTint: String?
  var progressViewLabelColor: String?
  var deepLinkUrl: String?
  var timerType: DynamicIslandTimerType?

  enum DynamicIslandTimerType: String, Codable {
    case circular
    case digital
  }
}

struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      if context.isStale {
        // Timer expired while app was in background — show completion state
        VStack(alignment: .leading) {
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Session Complete")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: context.attributes.titleColor ?? "#8B4513"))
              Text("Tap to open app")
                .font(.title3)
                .foregroundStyle(Color(hex: context.attributes.subtitleColor ?? "#8B4513").opacity(0.7))
            }
            Spacer()
            resizableImage(imageName: context.state.imageName ?? "default-coffee-bean")
              .frame(maxHeight: 64)
          }
        }
        .padding(24)
        .activityBackgroundTint(
          context.attributes.backgroundColor.map { Color(hex: $0) }
        )
        .activitySystemActionForegroundColor(Color.black)
        .applyWidgetURL(from: context.attributes.deepLinkUrl)
      } else {
        LiveActivityView(contentState: context.state, attributes: context.attributes)
          .activityBackgroundTint(
            context.attributes.backgroundColor.map { Color(hex: $0) }
          )
          .activitySystemActionForegroundColor(Color.black)
          .applyWidgetURL(from: context.attributes.deepLinkUrl)
      }
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading, priority: 1) {
          dynamicIslandExpandedLeading(title: context.state.title, subtitle: context.state.subtitle)
            .dynamicIsland(verticalPlacement: .belowIfTooWide)
            .padding(.leading, 5)
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
        DynamicIslandExpandedRegion(.trailing) {
          dynamicIslandExpandedTrailing(imageName: {
            let imageName = context.state.imageName ?? "default-coffee-bean"
            if context.state.imageName == nil {
              NSLog("[LiveActivity] Using default coffee bean image for Dynamic Island expanded")
            } else {
              NSLog("[LiveActivity] Using custom image for Dynamic Island expanded: \(context.state.imageName!)")
            }
            return imageName
          }())
            .padding(.trailing, 5)
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
        DynamicIslandExpandedRegion(.bottom) {
          if let date = context.state.timerEndDateInMilliseconds {
            dynamicIslandExpandedBottom(
              endDate: date, progressViewTint: context.attributes.progressViewTint
            )
            .padding(.horizontal, 5)
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
          }
        }
      } compactLeading: {
        HStack(spacing: 4) {
          resizableImage(imageName: {
            let imageName = context.state.dynamicIslandImageName ?? "default-coffee-bean"
            if context.state.dynamicIslandImageName == nil {
              NSLog("[LiveActivity] Using default coffee bean image for Dynamic Island compact")
            } else {
              NSLog("[LiveActivity] Using custom image for Dynamic Island compact: \(context.state.dynamicIslandImageName!)")
            }
            return imageName
          }())
            .frame(maxWidth: 23, maxHeight: 23)

          if let dynamicIslandText = context.state.dynamicIslandText {
            Text(dynamicIslandText)
              .font(.system(size: 15))
              .minimumScaleFactor(0.8)
              .fontWeight(.semibold)
              .lineLimit(1)
          }
        }
        .applyWidgetURL(from: context.attributes.deepLinkUrl)
      } compactTrailing: {
        if context.isStale {
          Text("Done")
            .font(.system(size: 14))
            .fontWeight(.semibold)
        } else if let date = context.state.timerEndDateInMilliseconds {
          compactTimer(
            endDate: date,
            timerType: context.attributes.timerType ?? .circular,
            progressViewTint: context.attributes.progressViewTint
          ).applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
      } minimal: {
        if context.isStale {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 14))
        } else if let date = context.state.timerEndDateInMilliseconds {
          compactTimer(
            endDate: date,
            timerType: context.attributes.timerType ?? .circular,
            progressViewTint: context.attributes.progressViewTint
          ).applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
      }
    }
  }

  @ViewBuilder
  private func compactTimer(
    endDate: Double,
    timerType: LiveActivityAttributes.DynamicIslandTimerType,
    progressViewTint: String?
  ) -> some View {
    if timerType == .digital {
      Text(timerInterval: Date.toTimerInterval(miliseconds: endDate))
        .font(.system(size: 15))
        .minimumScaleFactor(0.8)
        .fontWeight(.semibold)
        .frame(maxWidth: 60)
        .multilineTextAlignment(.trailing)
    } else {
      circularTimer(endDate: endDate)
        .tint(progressViewTint.map { Color(hex: $0) })
    }
  }

  private func dynamicIslandExpandedLeading(title: String, subtitle: String?) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      Text(title)
        .font(.title2)
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      if let subtitle {
        Text(subtitle)
          .font(.title3)
          .minimumScaleFactor(0.8)
          .foregroundStyle(.white.opacity(0.75))
      }
      Spacer()
    }
  }

  private func dynamicIslandExpandedTrailing(imageName: String) -> some View {
    VStack {
      Spacer()
      resizableImage(imageName: imageName)
        .frame(maxHeight: 64)
      Spacer()
    }
  }

  private func dynamicIslandExpandedBottom(endDate: Double, progressViewTint: String?) -> some View {
    ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
      .foregroundStyle(.white)
      .tint(progressViewTint.map { Color(hex: $0) })
      .padding(.top, 5)
  }

  private func circularTimer(endDate: Double) -> some View {
    ProgressView(
      timerInterval: Date.toTimerInterval(miliseconds: endDate),
      countsDown: false,
      label: { EmptyView() },
      currentValueLabel: {
        EmptyView()
      }
    )
    .progressViewStyle(.circular)
  }
}
