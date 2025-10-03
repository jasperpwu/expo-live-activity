import { IOSConfig, withPlugins, createRunOncePlugin } from 'expo/config-plugins'

import type { LiveActivityConfigPlugin } from './types'
import { withConfig } from './withConfig'
import withPlist from './withPlist'
import { withPushNotifications } from './withPushNotifications'
import { withWidgetExtensionEntitlements } from './withWidgetExtensionEntitlements'
import { withXcode } from './withXcode'

const withWidgetsAndLiveActivities: LiveActivityConfigPlugin = (config, props) => {
  if (!props?.appGroupIdentifier) {
    throw new Error('expo-live-activity: appGroupIdentifier is required. Please specify it in your app.json plugins configuration.')
  }

  const deploymentTarget = '16.2'
  const targetName = `${IOSConfig.XcodeUtils.sanitizedName(config.name)}LiveActivity`
  const bundleIdentifier = `${config.ios?.bundleIdentifier}.${targetName}`

  config.ios = {
    ...config.ios,
    infoPlist: {
      ...config.ios?.infoPlist,
      NSSupportsLiveActivities: true,
      NSSupportsLiveActivitiesFrequentUpdates: false,
    },
  }

  config = withPlugins(config, [
    [withPlist, { targetName, appGroupIdentifier: props.appGroupIdentifier }],
    [
      withXcode,
      {
        targetName,
        bundleIdentifier,
        deploymentTarget,
        appGroupIdentifier: props.appGroupIdentifier,
      },
    ],
    [withWidgetExtensionEntitlements, { targetName, appGroupIdentifier: props.appGroupIdentifier }],
    [withConfig, { targetName, bundleIdentifier, groupIdentifier: props.appGroupIdentifier }],
  ])

  if (props?.enablePushNotifications) {
    config = withPushNotifications(config)
  }

  return config
}

export default createRunOncePlugin(
  withWidgetsAndLiveActivities,
  'expo-live-activity',
  '0.2.1'
)
