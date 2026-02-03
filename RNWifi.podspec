require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = "RNWifi"
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { :git => package['repository']['url'], :tag => "v#{s.version}" }

  s.requires_arc   = true
  s.swift_version  = '5.0'
  s.platform       = :ios, '13.0'

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json'

  # Swift source files
  s.source_files   = 'ios/**/*.{swift,m,h}'

  # Exclude old Objective-C implementation
  s.exclude_files  = 'ios/RNWifi.m', 'ios/RNWifi.h', 'ios/ConnectError.m', 'ios/ConnectError.h'

  s.dependency "React-Core"

  # Pod target xcconfig for module
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_OBJC_BRIDGING_HEADER' => '$(PODS_TARGET_SRCROOT)/ios/RNWifi-Bridging-Header.h'
  }
end
