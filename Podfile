platform :ios, '9.0'

#use_frameworks!
inhibit_all_warnings!

workspace 'KinEcosystem'

target 'KinEcosystem' do
    project 'KinEcosystem/KinEcosystem'
    pod 'SimpleCoreDataStack' , :git => 'https://github.com/kinecosystem/CoreDataStack.git', :tag => '0.1.8'
    pod 'KinMigrationModule'
    pod 'KinAppreciationModuleOptionsMenu', '0.0.4'
end

target 'KinEcosystemTests' do
    project 'KinEcosystem/KinEcosystem'
end

target 'EcosystemSampleApp' do
    project 'KinEcosystemSampleApp/EcosystemSampleApp'
    pod 'SimpleCoreDataStack' , :git => 'https://github.com/kinecosystem/kin-ecosystem-ios-sdk.git', :branch => 'ECO-1554'
    #pod 'KinEcosystem', :path => './'
    pod 'JWT', '3.0.0-beta.11', :modular_headers => true
    pod 'HockeySDK', :modular_headers => true
end
