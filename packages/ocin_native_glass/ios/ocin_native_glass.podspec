Pod::Spec.new do |s|
  s.name = 'ocin_native_glass'
  s.version = '0.1.0'
  s.summary = 'OCIN native SwiftUI Glass background proof of concept'
  s.description = 'Uses Apple SwiftUI glassEffect on iOS 26+ only.'
  s.homepage = 'https://github.com/'
  s.license = { :type => 'MIT' }
  s.author = { 'OCIN' => 'personal-use' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
end
