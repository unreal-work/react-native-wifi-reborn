import { Platform } from "react-native"
import NativeWifiManager from "./NativeWifiManager"
import type {
  WifiEntry,
  ConnectOptions,
  ForceWifiOptions,
} from "./NativeWifiManager"

// Re-export types
export type { WifiEntry, ConnectOptions, ForceWifiOptions }

// === Error Codes ===

export const GET_CURRENT_WIFI_SSID_ERRORS = {
  CouldNotDetectSSID: "CouldNotDetectSSID",
} as const

export const CONNECT_ERRORS = {
  unavailableForOSVersion: "unavailableForOSVersion",
  invalid: "invalid",
  invalidSSID: "invalidSSID",
  invalidSSIDPrefix: "invalidSSIDPrefix",
  invalidPassphrase: "invalidPassphrase",
  userDenied: "userDenied",
  locationPermissionDenied: "locationPermissionDenied",
  unableToConnect: "unableToConnect",
  locationPermissionRestricted: "locationPermissionRestricted",
  locationPermissionMissing: "locationPermissionMissing",
  locationServicesOff: "locationServicesOff",
  couldNotEnableWifi: "couldNotEnableWifi",
  couldNotScan: "couldNotScan",
  couldNotDetectSSID: "couldNotDetectSSID",
  didNotFindNetwork: "didNotFindNetwork",
  authenticationErrorOccurred: "authenticationErrorOccurred",
  android10ImmediatelyDroppedConnection: "android10ImmediatelyDroppedConnection",
  timeoutOccurred: "timeoutOccurred",
} as const

export const DISCONNECT_ERRORS = {
  couldNotGetWifiManager: "couldNotGetWifiManager",
  couldNotGetConnectivityManager: "couldNotGetConnectivityManager",
} as const

export const IS_REMOVE_WIFI_NETWORK_ERRORS = {
  locationPermissionMissing: "locationPermissionMissing",
  couldNotGetWifiManager: "couldNotGetWifiManager",
  couldNotGetConnectivityManager: "couldNotGetConnectivityManager",
} as const

export const FORCE_WIFI_USAGE_ERRORS = {
  couldNotGetConnectivityManager: "couldNotGetConnectivityManager",
} as const

export const LOAD_WIFI_LIST_ERRORS = {
  locationPermissionMissing: "locationPermissionMissing",
  locationServicesOff: "locationServicesOff",
  jsonParsingException: "jsonParsingException",
  illegalViewOperationException: "illegalViewOperationException",
} as const

// Legacy export name (typo in original)
export const GET_CURRENT_WIFI_SSID_ERRRORS = GET_CURRENT_WIFI_SSID_ERRORS

// === IoT Helper State ===

let isIoTNetworkBound = false

// === WifiManager Wrapper with IoT Support ===

/**
 * Enhanced WiFi Manager with IoT device support
 */
const WifiManager = {
  // === Original API (pass-through to native) ===

  getCurrentWifiSSID: () => NativeWifiManager.getCurrentWifiSSID(),

  connectToProtectedSSID: (
    ssid: string,
    password: string | null,
    isWEP: boolean,
    isHidden: boolean
  ) => NativeWifiManager.connectToProtectedSSID(ssid, password, isWEP, isHidden),

  connectToProtectedWifiSSID: (options: ConnectOptions) =>
    NativeWifiManager.connectToProtectedWifiSSID(options),

  // iOS only
  connectToSSID: (ssid: string) => NativeWifiManager.connectToSSID(ssid),

  connectToSSIDPrefix: (ssidPrefix: string) =>
    NativeWifiManager.connectToSSIDPrefix(ssidPrefix),

  disconnectFromSSID: (ssid: string) =>
    NativeWifiManager.disconnectFromSSID(ssid),

  connectToProtectedSSIDOnce: (
    ssid: string,
    password: string | null,
    isWEP: boolean,
    joinOnce: boolean
  ) =>
    NativeWifiManager.connectToProtectedSSIDOnce(ssid, password, isWEP, joinOnce),

  connectToProtectedSSIDPrefix: (
    ssidPrefix: string,
    password: string,
    isWEP: boolean
  ) =>
    NativeWifiManager.connectToProtectedSSIDPrefix(ssidPrefix, password, isWEP),

  connectToProtectedSSIDPrefixOnce: (
    ssidPrefix: string,
    password: string | null,
    isWEP: boolean,
    joinOnce: boolean
  ) =>
    NativeWifiManager.connectToProtectedSSIDPrefixOnce(
      ssidPrefix,
      password,
      isWEP,
      joinOnce
    ),

  // Android only
  loadWifiList: () => NativeWifiManager.loadWifiList(),

  reScanAndLoadWifiList: () => NativeWifiManager.reScanAndLoadWifiList(),

  isEnabled: () => NativeWifiManager.isEnabled(),

  setEnabled: (enabled: boolean) => NativeWifiManager.setEnabled(enabled),

  connectionStatus: () => NativeWifiManager.connectionStatus(),

  disconnect: () => NativeWifiManager.disconnect(),

  getBSSID: () => NativeWifiManager.getBSSID(),

  getCurrentSignalStrength: () => NativeWifiManager.getCurrentSignalStrength(),

  getFrequency: () => NativeWifiManager.getFrequency(),

  getIP: () => NativeWifiManager.getIP(),

  isRemoveWifiNetwork: (ssid: string) =>
    NativeWifiManager.isRemoveWifiNetwork(ssid),

  forceWifiUsage: (useWifi: boolean) =>
    NativeWifiManager.forceWifiUsage(useWifi),

  forceWifiUsageWithOptions: (useWifi: boolean, options: ForceWifiOptions) =>
    NativeWifiManager.forceWifiUsageWithOptions(useWifi, options),

  suggestWifiNetwork: (
    networkConfigs: Array<{
      ssid: string
      password?: string
      isWpa3?: boolean
      isAppInteractionRequired?: boolean
    }>
  ) => NativeWifiManager.suggestWifiNetwork(networkConfigs),

  // === IoT-Specific Methods ===

  /**
   * Connect to an IoT device's WiFi Access Point
   *
   * This method:
   * 1. Connects to the specified network (with joinOnce on iOS)
   * 2. Binds all app traffic to this network (Android)
   * 3. Prevents system from switching away due to lack of internet
   *
   * Use `disconnectFromIoTNetwork()` when done - system will auto-reconnect
   * to the previous network on both platforms.
   *
   * @param ssid IoT device's access point name
   * @param password Password (empty string for open networks)
   * @param options Additional options
   */
  connectToIoTNetwork: async (
    ssid: string,
    password: string = "",
    options: {
      /** Use prefix matching for SSID (iOS) */
      usePrefix?: boolean
      /** Timeout in seconds (Android) */
      timeout?: number
    } = {}
  ): Promise<void> => {
    const { usePrefix = false, timeout = 30 } = options

    console.log(`[WifiManager] Connecting to IoT network: ${ssid}, usePrefix: ${usePrefix}, timeout: ${timeout}`)

    // Connect to the network
    if (Platform.OS === "android") {
      const connectOptions = {
        ssid,
        password: password || null,
        isHidden: false,
        timeout,
        usePrefix,
      }
      console.log(`[WifiManager] Android connectOptions:`, JSON.stringify(connectOptions))
      await NativeWifiManager.connectToProtectedWifiSSID(connectOptions)
    } else {
      // iOS: use joinOnce=true so system returns to previous network on disconnect
      if (usePrefix) {
        await NativeWifiManager.connectToProtectedSSIDPrefixOnce(
          ssid,
          password || null,
          false, // isWEP
          true   // joinOnce - critical for auto-return
        )
      } else {
        await NativeWifiManager.connectToProtectedSSIDOnce(
          ssid,
          password || null,
          false, // isWEP
          true   // joinOnce - critical for auto-return
        )
      }
    }

    // Bind traffic to this network (Android only)
    // This is critical for IoT - prevents system from routing through mobile data
    if (Platform.OS === "android") {
      try {
        console.log("[WifiManager] Binding traffic to IoT network (noInternet: true)")
        await NativeWifiManager.forceWifiUsageWithOptions(true, {
          noInternet: true,
        })
        isIoTNetworkBound = true
        console.log("[WifiManager] Traffic bound successfully")
      } catch (error) {
        console.warn("[WifiManager] Failed to bind traffic:", error)
        // Continue anyway - connection might still work on some devices
      }
    } else {
      isIoTNetworkBound = true
    }

    // Verify connection
    const currentSSID = await NativeWifiManager.getCurrentWifiSSID()
    const connected = usePrefix
      ? currentSSID?.toLowerCase().includes(ssid.toLowerCase())
      : currentSSID === ssid

    if (!connected) {
      // Cleanup on failure
      if (Platform.OS === "android" && isIoTNetworkBound) {
        try {
          await NativeWifiManager.forceWifiUsageWithOptions(false, {
            noInternet: false,
          })
          isIoTNetworkBound = false
        } catch (e) {
          // Ignore
        }
      }
      isIoTNetworkBound = false
      throw new Error(
        `Failed to connect to IoT network. Expected: ${ssid}, Got: ${currentSSID}`
      )
    }

    console.log(`[WifiManager] Connected to IoT network: ${currentSSID}`)
  },

  /**
   * Disconnect from IoT network and restore normal networking
   *
   * This method:
   * 1. Unbinds app traffic from WiFi (Android)
   * 2. Removes the network configuration
   * 3. System auto-reconnects to previous network (both platforms)
   */
  disconnectFromIoTNetwork: async (): Promise<void> => {
    console.log("[WifiManager] Disconnecting from IoT network")

    if (Platform.OS === "android") {
      // Unbind traffic first
      if (isIoTNetworkBound) {
        try {
          console.log("[WifiManager] Unbinding traffic")
          await NativeWifiManager.forceWifiUsageWithOptions(false, {
            noInternet: false,
          })
        } catch (error) {
          console.warn("[WifiManager] Failed to unbind traffic:", error)
        }
      }

      // Disconnect - Android will auto-reconnect to preferred network
      try {
        await NativeWifiManager.disconnect()
      } catch (error) {
        console.warn("[WifiManager] Disconnect error:", error)
      }
    } else {
      // iOS: Remove the configuration - iOS will auto-return to previous network
      // because we used joinOnce=true when connecting
      try {
        const currentSSID = await NativeWifiManager.getCurrentWifiSSID()
        if (currentSSID) {
          console.log(`[WifiManager] Removing iOS configuration for: ${currentSSID}`)
          await NativeWifiManager.disconnectFromSSID(currentSSID)
        }
      } catch (error) {
        console.warn("[WifiManager] iOS disconnect error:", error)
      }
    }

    isIoTNetworkBound = false
    console.log("[WifiManager] Disconnected - system will auto-reconnect to previous network")
  },

  /**
   * Check if currently bound to an IoT network
   */
  isIoTNetworkBound: (): boolean => {
    return isIoTNetworkBound
  },
}

export default WifiManager
