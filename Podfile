platform :ios, '9.0'

use_frameworks!
inhibit_all_warnings!

workspace 'KinEcosystem'

target 'KinEcosystem' do
  project 'KinEcosystem/KinEcosystem'
  pod 'SimpleCoreDataStack'
  pod 'KinMigrationModule'
  pod 'KinAppreciationModuleOptionsMenu', '0.0.3'
end

target 'KinEcosystemTests' do 
  project 'KinEcosystem/KinEcosystem'
end

target 'EcosystemSampleApp' do
  project 'KinEcosystemSampleApp/EcosystemSampleApp'

  pod 'KinEcosystem', :path => './'
  pod 'JWT', '3.0.0-beta.11', :modular_headers => true
  pod 'HockeySDK', :modular_headers => true
end
