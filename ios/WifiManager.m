#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(WifiManager, NSObject)

// Get current SSID
RCT_EXTERN_METHOD(getCurrentWifiSSID:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to open network
RCT_EXTERN_METHOD(connectToSSID:(NSString *)ssid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect by SSID prefix (iOS 13+)
RCT_EXTERN_METHOD(connectToSSIDPrefix:(NSString *)ssidPrefix
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to protected network by prefix
RCT_EXTERN_METHOD(connectToProtectedSSIDPrefix:(NSString *)ssidPrefix
                  withPassphrase:(NSString *)passphrase
                  isWEP:(BOOL)isWEP
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to protected network by prefix with joinOnce
RCT_EXTERN_METHOD(connectToProtectedSSIDPrefixOnce:(NSString *)ssidPrefix
                  withPassphrase:(NSString *)passphrase
                  isWEP:(BOOL)isWEP
                  joinOnce:(BOOL)joinOnce
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to protected network
RCT_EXTERN_METHOD(connectToProtectedSSID:(NSString *)ssid
                  withPassphrase:(NSString *)passphrase
                  isWEP:(BOOL)isWEP
                  isHidden:(BOOL)isHidden
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to protected network with options object
RCT_EXTERN_METHOD(connectToProtectedWifiSSID:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Connect to protected network with joinOnce
RCT_EXTERN_METHOD(connectToProtectedSSIDOnce:(NSString *)ssid
                  withPassphrase:(NSString *)passphrase
                  isWEP:(BOOL)isWEP
                  joinOnce:(BOOL)joinOnce
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Disconnect from SSID
RCT_EXTERN_METHOD(disconnectFromSSID:(NSString *)ssid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
