- Do not look at example/ as I tell you to, because it is not part of source code
- When adding a new field to Live Activity state in expo-live-activity:
  1. Add to TypeScript types in src/index.ts (LiveActivityState and NativeLiveActivityState)
  2. Add to native Record struct in ios/ExpoLiveActivityModule.swift (LiveActivityState)
  3. Add to shared ContentState in ios/LiveActivityAttributes.swift (LiveActivityAttributes.ContentState)
  4. Add to Widget ContentState in ios-files/LiveActivityWidget.swift (LiveActivityAttributes.ContentState)
  5. Update all 3 places where ContentState is instantiated: startActivity, stopActivity, and updateActivity functions
  6. Update the UI rendering code in ios-files/LiveActivityWidget.swift