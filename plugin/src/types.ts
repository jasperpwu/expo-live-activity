import { ConfigPlugin } from '@expo/config-plugins'

interface ConfigPluginProps {
  enablePushNotifications?: boolean
  appGroupIdentifier: string
}

export type LiveActivityConfigPlugin = ConfigPlugin<ConfigPluginProps | undefined>
