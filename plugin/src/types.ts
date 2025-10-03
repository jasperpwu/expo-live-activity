import { ConfigPlugin } from '@expo/config-plugins'

export interface ConfigPluginProps {
  enablePushNotifications?: boolean
  appGroupIdentifier: string
  appleTeamId?: string
}

export type LiveActivityConfigPlugin = ConfigPlugin<ConfigPluginProps | undefined>
