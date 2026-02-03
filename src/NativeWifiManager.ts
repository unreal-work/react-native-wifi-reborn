import type { TurboModule } from "react-native"
import { TurboModuleRegistry } from "react-native"

/**
 * WiFi network entry from scan results
 */
export interface WifiEntry {
  SSID: string
  BSSID: string
  capabilities: string
  frequency: number
  level: number
  timestamp: number
}

/**
 * Options for connecting to a protected WiFi network
 */
export interface ConnectOptions {
  ssid: string
  password: string | null
  isWEP?: boolean
  isHidden?: boolean
  timeout?: number
}

/**
 * Options for forcing WiFi usage (IoT mode)
 */
export interface ForceWifiOptions {
  noInternet: boolean
}

/**
 * Native WiFi Manager TurboModule Spec
 * Supports both Old and New Architecture
 */
export interface Spec extends TurboModule {
  // === Cross-platform methods ===

  /**
   * Get currently connected WiFi SSID
   */
  getCurrentWifiSSID(): Promise<string>

  /**
   * Connect to a protected WiFi network
   * @param ssid Network name
   * @param password Network password (null for open networks)
   * @param isWEP Whether network uses WEP (iOS only)
   * @param isHidden Whether network is hidden (Android only)
   */
  connectToProtectedSSID(
    ssid: string,
    password: string | null,
    isWEP: boolean,
    isHidden: boolean
  ): Promise<void>

  /**
   * Connect to a protected WiFi network with options
   */
  connectToProtectedWifiSSID(options: ConnectOptions): Promise<void>

  // === iOS only methods ===

  /**
   * Connect to an open WiFi network (iOS)
   */
  connectToSSID(ssid: string): Promise<void>

  /**
   * Connect to a WiFi network by SSID prefix (iOS)
   */
  connectToSSIDPrefix(ssidPrefix: string): Promise<void>

  /**
   * Disconnect from a specific SSID (iOS)
   */
  disconnectFromSSID(ssid: string): Promise<void>

  /**
   * Connect with joinOnce option (iOS)
   */
  connectToProtectedSSIDOnce(
    ssid: string,
    password: string | null,
    isWEP: boolean,
    joinOnce: boolean
  ): Promise<void>

  /**
   * Connect to network by prefix with password (iOS)
   */
  connectToProtectedSSIDPrefix(
    ssidPrefix: string,
    password: string,
    isWEP: boolean
  ): Promise<void>

  /**
   * Connect to network by prefix with joinOnce (iOS)
   */
  connectToProtectedSSIDPrefixOnce(
    ssidPrefix: string,
    password: string | null,
    isWEP: boolean,
    joinOnce: boolean
  ): Promise<void>

  // === Android only methods ===

  /**
   * Load list of nearby WiFi networks (Android)
   */
  loadWifiList(): Promise<WifiEntry[]>

  /**
   * Rescan and load WiFi list (Android)
   */
  reScanAndLoadWifiList(): Promise<WifiEntry[]>

  /**
   * Check if WiFi is enabled (Android)
   */
  isEnabled(): Promise<boolean>

  /**
   * Enable/disable WiFi - opens settings on Android 10+ (Android)
   */
  setEnabled(enabled: boolean): void

  /**
   * Check if currently connected to WiFi (Android)
   */
  connectionStatus(): Promise<boolean>

  /**
   * Disconnect from current WiFi network (Android)
   */
  disconnect(): Promise<boolean>

  /**
   * Get BSSID of current network (Android)
   */
  getBSSID(): Promise<string>

  /**
   * Get signal strength (RSSI) of current network (Android)
   */
  getCurrentSignalStrength(): Promise<number>

  /**
   * Get frequency of current network (Android)
   */
  getFrequency(): Promise<number>

  /**
   * Get IP address (Android)
   */
  getIP(): Promise<string>

  /**
   * Remove saved WiFi network configuration (Android)
   */
  isRemoveWifiNetwork(ssid: string): Promise<boolean>

  /**
   * Force all network traffic through WiFi (Android)
   * Critical for IoT devices without internet access
   *
   * @param useWifi true to bind traffic to WiFi, false to unbind
   * @param options { noInternet: true } for IoT networks without internet
   */
  forceWifiUsageWithOptions(
    useWifi: boolean,
    options: ForceWifiOptions
  ): Promise<void>

  /**
   * @deprecated Use forceWifiUsageWithOptions
   */
  forceWifiUsage(useWifi: boolean): Promise<void>

  /**
   * Suggest WiFi networks (Android 10+)
   */
  suggestWifiNetwork(
    networkConfigs: Array<{
      ssid: string
      password?: string
      isWpa3?: boolean
      isAppInteractionRequired?: boolean
    }>
  ): Promise<string>
}

// Get native module - supports both Old and New Architecture
export default TurboModuleRegistry.getEnforcing<Spec>("WifiManager")
