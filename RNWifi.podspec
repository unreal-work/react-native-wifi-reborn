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

  s.source_files   = 'ios/**/*.{h,m,swift}'

  s.dependency "React"
end
