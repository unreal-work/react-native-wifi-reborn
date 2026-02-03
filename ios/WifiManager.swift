import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import UIKit

/// Error codes for WiFi connection failures
enum WifiError: String {
    case unavailableForOSVersion = "unavailableForOSVersion"
    case invalid = "invalid"
    case invalidSSID = "invalidSSID"
    case invalidSSIDPrefix = "invalidSSIDPrefix"
    case invalidPassphrase = "invalidPassphrase"
    case userDenied = "userDenied"
    case unableToConnect = "unableToConnect"
    case locationPermissionDenied = "locationPermissionDenied"
    case locationPermissionRestricted = "locationPermissionRestricted"
    case didNotFindNetwork = "didNotFindNetwork"
    case couldNotDetectSSID = "couldNotDetectSSID"
    case timeout = "timeoutOccurred"
}

@objc(WifiManager)
class WifiManager: NSObject {

    private var locationManager: CLLocationManager?
    private var pendingResolve: RCTPromiseResolveBlock?
    private var pendingReject: RCTPromiseRejectBlock?
    private var isWaitingForPermission = false

    override init() {
        super.init()
        print("[WifiManager] Initializing...")

        if #available(iOS 13, *) {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc func constantsToExport() -> [String: Any] {
        return ["settingsURL": UIApplication.openSettingsURLString]
    }

    // MARK: - Get Current SSID

    private func fetchCurrentSSID(completion: @escaping (String?) -> Void) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                completion(network?.ssid)
            }
        } else {
            // Legacy method for iOS 13 and below
            guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
                completion(nil)
                return
            }

            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                   let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                    completion(ssid)
                    return
                }
            }
            completion(nil)
        }
    }

    @objc func getCurrentWifiSSID(_ resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {

        if #available(iOS 13, *) {
            let status = CLLocationManager.authorizationStatus()

            if status == .denied {
                print("[WifiManager] Location permission denied")
                reject(WifiError.locationPermissionDenied.rawValue,
                       "Cannot detect SSID - location permission denied", nil)
                return
            }

            if status == .restricted {
                print("[WifiManager] Location permission restricted")
                reject(WifiError.locationPermissionRestricted.rawValue,
                       "Cannot detect SSID - location permission restricted", nil)
                return
            }

            let hasPermission = status == .authorizedWhenInUse || status == .authorizedAlways

            if !hasPermission {
                // Request permission and wait
                pendingResolve = resolve
                pendingReject = reject
                isWaitingForPermission = true
                locationManager?.requestWhenInUseAuthorization()
                return
            }
        }

        // We have permission, fetch SSID
        fetchCurrentSSID { ssid in
            if let ssid = ssid {
                resolve(ssid)
            } else {
                print("[WifiManager] Could not detect SSID")
                reject(WifiError.couldNotDetectSSID.rawValue, "Cannot detect SSID", nil)
            }
        }
    }

    // MARK: - Connect Methods

    @objc func connectToSSID(_ ssid: String,
                              resolver resolve: @escaping RCTPromiseResolveBlock,
                              rejecter reject: @escaping RCTPromiseRejectBlock) {
        connectToProtectedSSID(ssid, withPassphrase: "", isWEP: false, isHidden: false,
                               resolver: resolve, rejecter: reject)
    }

    @objc func connectToSSIDPrefix(_ ssidPrefix: String,
                                    resolver resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard #available(iOS 13.0, *) else {
            reject(WifiError.unavailableForOSVersion.rawValue, "Requires iOS 13+", nil)
            return
        }

        let config = NEHotspotConfiguration(ssidPrefix: ssidPrefix)
        config.joinOnce = false

        applyConfiguration(config, expectedSSID: nil, isPrefix: true, ssidPrefix: ssidPrefix,
                          resolve: resolve, reject: reject)
    }

    @objc func connectToProtectedSSIDPrefix(_ ssidPrefix: String,
                                             withPassphrase passphrase: String,
                                             isWEP: Bool,
                                             resolver resolve: @escaping RCTPromiseResolveBlock,
                                             rejecter reject: @escaping RCTPromiseRejectBlock) {
        connectToProtectedSSIDPrefixOnce(ssidPrefix, withPassphrase: passphrase, isWEP: isWEP,
                                         joinOnce: false, resolver: resolve, rejecter: reject)
    }

    @objc func connectToProtectedSSIDPrefixOnce(_ ssidPrefix: String,
                                                 withPassphrase passphrase: String,
                                                 isWEP: Bool,
                                                 joinOnce: Bool,
                                                 resolver resolve: @escaping RCTPromiseResolveBlock,
                                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard #available(iOS 13.0, *) else {
            reject(WifiError.unavailableForOSVersion.rawValue, "Requires iOS 13+", nil)
            return
        }

        let config: NEHotspotConfiguration
        if passphrase.isEmpty {
            // Open network (no password)
            config = NEHotspotConfiguration(ssidPrefix: ssidPrefix)
        } else {
            // Protected network
            config = NEHotspotConfiguration(ssidPrefix: ssidPrefix, passphrase: passphrase, isWEP: isWEP)
        }
        config.joinOnce = joinOnce

        applyConfiguration(config, expectedSSID: nil, isPrefix: true, ssidPrefix: ssidPrefix,
                          resolve: resolve, reject: reject)
    }

    @objc func connectToProtectedSSID(_ ssid: String,
                                       withPassphrase passphrase: String,
                                       isWEP: Bool,
                                       isHidden: Bool,
                                       resolver resolve: @escaping RCTPromiseResolveBlock,
                                       rejecter reject: @escaping RCTPromiseRejectBlock) {
        connectToProtectedSSIDOnce(ssid, withPassphrase: passphrase, isWEP: isWEP,
                                   joinOnce: false, resolver: resolve, rejecter: reject)
    }

    @objc func connectToProtectedWifiSSID(_ params: [String: Any],
                                           resolver resolve: @escaping RCTPromiseResolveBlock,
                                           rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard let ssid = params["ssid"] as? String else {
            reject(WifiError.invalidSSID.rawValue, "SSID is required", nil)
            return
        }

        let password = params["password"] as? String ?? ""
        let isWEP = params["isWEP"] as? Bool ?? false

        connectToProtectedSSIDOnce(ssid, withPassphrase: password, isWEP: isWEP,
                                   joinOnce: false, resolver: resolve, rejecter: reject)
    }

    @objc func connectToProtectedSSIDOnce(_ ssid: String,
                                           withPassphrase passphrase: String,
                                           isWEP: Bool,
                                           joinOnce: Bool,
                                           resolver resolve: @escaping RCTPromiseResolveBlock,
                                           rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard #available(iOS 11.0, *) else {
            reject(WifiError.unavailableForOSVersion.rawValue, "Requires iOS 11+", nil)
            return
        }

        // Check if already connected to this network
        fetchCurrentSSID { [weak self] currentSSID in
            guard let self = self else { return }

            if currentSSID == ssid {
                print("[WifiManager] Already connected to \(ssid)")
                resolve(nil)
                return
            }

            let config: NEHotspotConfiguration
            if passphrase.isEmpty {
                config = NEHotspotConfiguration(ssid: ssid)
            } else {
                config = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: isWEP)
            }
            config.joinOnce = joinOnce

            self.applyConfiguration(config, expectedSSID: ssid, isPrefix: false, ssidPrefix: nil,
                                    resolve: resolve, reject: reject)
        }
    }

    @objc func disconnectFromSSID(_ ssid: String,
                                   resolver resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard #available(iOS 11.0, *) else {
            reject(WifiError.unavailableForOSVersion.rawValue, "Requires iOS 11+", nil)
            return
        }

        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        resolve(nil)
    }

    // MARK: - Private Helpers

    @available(iOS 11.0, *)
    private func applyConfiguration(_ config: NEHotspotConfiguration,
                                    expectedSSID: String?,
                                    isPrefix: Bool,
                                    ssidPrefix: String?,
                                    resolve: @escaping RCTPromiseResolveBlock,
                                    reject: @escaping RCTPromiseRejectBlock) {

        print("[WifiManager] Applying configuration for: \(expectedSSID ?? ssidPrefix ?? "unknown")")

        NEHotspotConfigurationManager.shared.apply(config) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                let errorCode = self.parseError(error)

                // AlreadyAssociated is actually success
                if (error as NSError).code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                    print("[WifiManager] Already associated with network")
                    resolve(nil)
                    return
                }

                print("[WifiManager] Configuration error: \(error.localizedDescription)")
                reject(errorCode, error.localizedDescription, error)
                return
            }

            // Verify connection with retries
            self.verifyConnection(expectedSSID: expectedSSID, isPrefix: isPrefix, ssidPrefix: ssidPrefix,
                                  maxRetries: 20, interval: 0.5, resolve: resolve, reject: reject)
        }
    }

    private func verifyConnection(expectedSSID: String?,
                                  isPrefix: Bool,
                                  ssidPrefix: String?,
                                  maxRetries: Int,
                                  interval: TimeInterval,
                                  resolve: @escaping RCTPromiseResolveBlock,
                                  reject: @escaping RCTPromiseRejectBlock,
                                  currentRetry: Int = 0) {

        fetchCurrentSSID { [weak self] currentSSID in
            guard let self = self else { return }

            let isConnected: Bool
            if isPrefix, let prefix = ssidPrefix {
                isConnected = currentSSID?.lowercased().hasPrefix(prefix.lowercased()) ?? false
            } else if let expected = expectedSSID {
                isConnected = currentSSID == expected
            } else {
                isConnected = currentSSID != nil
            }

            if isConnected {
                print("[WifiManager] Successfully connected to: \(currentSSID ?? "unknown")")
                resolve(nil)
                return
            }

            if currentRetry >= maxRetries {
                print("[WifiManager] Connection verification timed out")
                let target = expectedSSID ?? ssidPrefix ?? "network"
                reject(WifiError.unableToConnect.rawValue,
                       "Unable to connect to \(target)", nil)
                return
            }

            // Retry after interval
            DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                self.verifyConnection(expectedSSID: expectedSSID, isPrefix: isPrefix, ssidPrefix: ssidPrefix,
                                      maxRetries: maxRetries, interval: interval,
                                      resolve: resolve, reject: reject, currentRetry: currentRetry + 1)
            }
        }
    }

    @available(iOS 11.0, *)
    private func parseError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case NEHotspotConfigurationError.invalid.rawValue:
            return WifiError.invalid.rawValue
        case NEHotspotConfigurationError.invalidSSID.rawValue:
            return WifiError.invalidSSID.rawValue
        case NEHotspotConfigurationError.invalidSSIDPrefix.rawValue:
            return WifiError.invalidSSIDPrefix.rawValue
        case NEHotspotConfigurationError.invalidWPAPassphrase.rawValue,
             NEHotspotConfigurationError.invalidWEPPassphrase.rawValue:
            return WifiError.invalidPassphrase.rawValue
        case NEHotspotConfigurationError.userDenied.rawValue:
            return WifiError.userDenied.rawValue
        default:
            return WifiError.unableToConnect.rawValue
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WifiManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("[WifiManager] Location authorization changed: \(status.rawValue)")

        guard isWaitingForPermission,
              let resolve = pendingResolve,
              let reject = pendingReject else {
            return
        }

        isWaitingForPermission = false
        pendingResolve = nil
        pendingReject = nil

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            fetchCurrentSSID { ssid in
                if let ssid = ssid {
                    resolve(ssid)
                } else {
                    reject(WifiError.couldNotDetectSSID.rawValue, "Cannot detect SSID", nil)
                }
            }
        } else {
            reject(WifiError.locationPermissionDenied.rawValue, "Location permission not granted", nil)
        }
    }
}
