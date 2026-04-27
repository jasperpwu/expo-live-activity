import ActivityKit
import ExpoModulesCore

public class ExpoLiveActivityModule: Module {
  struct LiveActivityState: Record {
    @Field
    var title: String

    @Field
    var subtitle: String?

    @Field
    var progressBar: ProgressBar?

    struct ProgressBar: Record {
      @Field
      var date: Double?

      @Field
      var progress: Double?
    }

    @Field
    var imageName: String?

    @Field
    var dynamicIslandImageName: String?

    @Field
    var dynamicIslandText: String?
  }

  struct LiveActivityConfig: Record {
    @Field
    var backgroundColor: String?

    @Field
    var titleColor: String?

    @Field
    var subtitleColor: String?

    @Field
    var progressViewTint: String?

    @Field
    var progressViewLabelColor: String?

    @Field
    var deepLinkUrl: String?

    @Field
    var timerType: DynamicIslandTimerType?
  }

  enum DynamicIslandTimerType: String, Enumerable {
    case circular
    case digital
  }

  @available(iOS 16.1, *)
  private func sendPushToken(activity: Activity<LiveActivityAttributes>, activityPushToken: String) {
    sendEvent(
      "onTokenReceived",
      [
        "activityID": activity.id,
        "activityName": activity.attributes.name,
        "activityPushToken": activityPushToken,
      ]
    )
  }

  private func sendPushToStartToken(activityPushToStartToken: String) {
    sendEvent(
      "onPushToStartTokenReceived",
      [
        "activityPushToStartToken": activityPushToStartToken,
      ]
    )
  }

  @available(iOS 16.1, *)
  private func sendStateChange(
    activity: Activity<LiveActivityAttributes>, activityState: ActivityState
  ) {
    sendEvent(
      "onStateChange",
      [
        "activityID": activity.id,
        "activityName": activity.attributes.name,
        "activityState": String(describing: activityState),
      ]
    )
  }

  private func updateImages(
    state: LiveActivityState, newState: inout LiveActivityAttributes.ContentState
  ) async throws {
    NSLog("[LiveActivity] 📸 updateImages called")

    if let name = state.imageName {
      NSLog("[LiveActivity] 🖼️ Processing imageName: '\(name)'")
      newState.imageName = try await resolveImage(from: name)
      NSLog("[LiveActivity] ✅ Set newState.imageName to: '\(newState.imageName ?? "nil")'")
    } else {
      NSLog("[LiveActivity] ⚠️ No imageName provided in state")
    }

    if let name = state.dynamicIslandImageName {
      NSLog("[LiveActivity] 🏝️ Processing dynamicIslandImageName: '\(name)'")
      newState.dynamicIslandImageName = try await resolveImage(from: name)
      NSLog("[LiveActivity] ✅ Set newState.dynamicIslandImageName to: '\(newState.dynamicIslandImageName ?? "nil")'")
    } else {
      NSLog("[LiveActivity] ⚠️ No dynamicIslandImageName provided in state")
    }
  }

  private func observePushToStartToken() {
    guard #available(iOS 17.2, *), ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    print("Observing push to start token updates...")
    Task {
      for await data in Activity<LiveActivityAttributes>.pushToStartTokenUpdates {
        let token = data.reduce("") { $0 + String(format: "%02x", $1) }
        sendPushToStartToken(activityPushToStartToken: token)
      }
    }
  }

  private func observeLiveActivityUpdates() {
    guard #available(iOS 16.2, *) else { return }

    Task {
      for await activityUpdate in Activity<LiveActivityAttributes>.activityUpdates {
        let activityId = activityUpdate.id
        let activityState = activityUpdate.activityState

        print("Received activity update: \(activityId), \(activityState)")

        guard
          let activity = Activity<LiveActivityAttributes>.activities.first(where: {
            $0.id == activityId
          })
        else { return print("Didn't find activity with ID \(activityId)") }

        if case .active = activityState {
          Task {
            for await state in activity.activityStateUpdates {
              sendStateChange(activity: activity, activityState: state)
            }
          }

          if pushNotificationsEnabled {
            print("Adding push token observer for activity \(activity.id)")
            Task {
              for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }

                sendPushToken(activity: activity, activityPushToken: pushTokenString)
              }
            }
          }
        }
      }
    }
  }

  private var pushNotificationsEnabled: Bool {
    Bundle.main.object(forInfoDictionaryKey: "ExpoLiveActivity_EnablePushNotifications") as? Bool
      ?? false
  }

  public func definition() -> ModuleDefinition {
    Name("ExpoLiveActivity")

    OnCreate {
      if pushNotificationsEnabled {
        observePushToStartToken()
      }
      observeLiveActivityUpdates()
    }

    Events("onTokenReceived", "onPushToStartTokenReceived", "onStateChange")

    Function("startActivity") {
      (state: LiveActivityState, maybeConfig: LiveActivityConfig?) -> String in
      guard #available(iOS 16.2, *) else { throw UnsupportedOSException("16.2") }

      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        throw LiveActivitiesNotEnabledException()
      }

      do {
        let config = maybeConfig ?? LiveActivityConfig()
        let attributes = LiveActivityAttributes(
          name: "ExpoLiveActivity",
          backgroundColor: config.backgroundColor,
          titleColor: config.titleColor,
          subtitleColor: config.subtitleColor,
          progressViewTint: config.progressViewTint,
          progressViewLabelColor: config.progressViewLabelColor,
          deepLinkUrl: config.deepLinkUrl,
          timerType: config.timerType == .digital ? .digital : .circular
        )
        let initialState = LiveActivityAttributes.ContentState(
          title: state.title,
          subtitle: state.subtitle,
          timerEndDateInMilliseconds: state.progressBar?.date,
          progress: state.progressBar?.progress,
          imageName: state.imageName,
          dynamicIslandImageName: state.dynamicIslandImageName,
          dynamicIslandText: state.dynamicIslandText
        )

        // Set staleDate to the timer end time so the widget knows when
        // content is outdated (e.g. timer reached 0:00 while app was in background).
        let timerEndDate: Date? = state.progressBar?.date.map {
          Date(timeIntervalSince1970: $0 / 1000)
        }

        let activity = try Activity.request(
          attributes: attributes,
          content: .init(state: initialState, staleDate: timerEndDate),
          pushType: pushNotificationsEnabled ? .token : nil
        )

        Task {
          var newState = activity.content.state
          try await updateImages(state: state, newState: &newState)
          await activity.update(ActivityContent(state: newState, staleDate: timerEndDate))
        }

        // Schedule auto-end: sleep until the timer expires, then dismiss.
        // Task.sleep is suspended when the app is in background, but resumes
        // when the app returns to foreground — so this acts as a reliable
        // cleanup that doesn't depend on JS state.
        if let endDate = timerEndDate {
          Task {
            let delay = endDate.timeIntervalSinceNow + 1 // 1s buffer
            if delay > 0 {
              try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            let finalState = LiveActivityAttributes.ContentState(
              title: "Session Complete",
              subtitle: nil,
              timerEndDateInMilliseconds: state.progressBar?.date,
              progress: nil,
              imageName: nil,
              dynamicIslandImageName: nil,
              dynamicIslandText: nil
            )
            await activity.end(
              ActivityContent(state: finalState, staleDate: nil),
              dismissalPolicy: .immediate
            )
            print("🧹 Auto-ended live activity: \(activity.id)")
          }
        }

        return activity.id
      } catch {
        throw UnexpectedErrorException(error)
      }
    }

    Function("stopActivity") { (activityId: String, state: LiveActivityState) in
      guard #available(iOS 16.2, *) else { throw UnsupportedOSException("16.2") }

      guard
        let activity = Activity<LiveActivityAttributes>.activities.first(where: {
          $0.id == activityId
        })
      else { throw ActivityNotFoundException(activityId) }

      Task {
        print("Stopping activity with id: \(activityId)")
        var newState = LiveActivityAttributes.ContentState(
          title: state.title,
          subtitle: state.subtitle,
          timerEndDateInMilliseconds: state.progressBar?.date,
          progress: state.progressBar?.progress,
          imageName: nil,
          dynamicIslandImageName: nil,
          dynamicIslandText: state.dynamicIslandText
        )
        try await updateImages(state: state, newState: &newState)
        await activity.end(
          ActivityContent(state: newState, staleDate: nil),
          dismissalPolicy: .immediate
        )
      }
    }

    Function("updateActivity") { (activityId: String, state: LiveActivityState) in
      guard #available(iOS 16.2, *) else {
        throw UnsupportedOSException("16.2")
      }

      guard
        let activity = Activity<LiveActivityAttributes>.activities.first(where: {
          $0.id == activityId
        })
      else { throw ActivityNotFoundException(activityId) }

      Task {
        print("Updating activity with id: \(activityId)")
        var newState = LiveActivityAttributes.ContentState(
          title: state.title,
          subtitle: state.subtitle,
          timerEndDateInMilliseconds: state.progressBar?.date,
          progress: state.progressBar?.progress,
          imageName: nil,
          dynamicIslandImageName: nil,
          dynamicIslandText: state.dynamicIslandText
        )
        try await updateImages(state: state, newState: &newState)
        await activity.update(ActivityContent(state: newState, staleDate: nil))
      }
    }
  }
}
