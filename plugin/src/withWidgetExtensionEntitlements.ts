import { ConfigPlugin, withInfoPlist } from '@expo/config-plugins'
import plist from '@expo/plist'
import * as fs from 'fs'
import * as path from 'path'

import { getWidgetExtensionEntitlements } from "./lib/getWidgetExtensionEntitlements";

export const withWidgetExtensionEntitlements: ConfigPlugin<{
  targetName: string
  appGroupIdentifier?: string
}> = (config, { targetName, appGroupIdentifier }) => {
  return withInfoPlist(config, (config) => {
    const targetPath = path.join(config.modRequest.platformProjectRoot, targetName)
    const filePath = path.join(targetPath, `${targetName}.entitlements`)

    const extensionEntitlements = getWidgetExtensionEntitlements(config.ios, {
      groupIdentifier: appGroupIdentifier
    });

    fs.mkdirSync(path.dirname(filePath), { recursive: true })
    fs.writeFileSync(filePath, plist.build(extensionEntitlements))
    return config
  })
}
