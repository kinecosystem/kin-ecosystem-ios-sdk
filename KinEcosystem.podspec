Pod::Spec.new do |s|
  s.name             = 'KinEcosystem'
  s.version          = '0.4.8'
  s.summary          = 'Kin Ecosystem mobile sdk for iOS'
  s.description      = <<-DESC
Kin ecosystem mobile sdk for iOS
                       DESC

  s.homepage         = 'https://kinecosystem.org'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kin' => 'kin@kinfoundation.com' }
  s.source           = { :git => 'https://github.com/kinfoundation/kin-ecosystem-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.1'

  s.source_files = 'KinEcosystem/**/*.{h,m,swift}'
  s.resources = 'KinEcosystem/**/*.{xcassets,xcdatamodeld,storyboard,xib,png,pdf,jpg,json}'
  s.swift_version = '4.1'
  s.dependency 'SimpleCoreDataStack', '0.1.6'
  s.dependency 'KinSDK', '0.7.5'
end
