# Uncomment this line to define a global platform for your project
platform :ios, '8.4'
use_frameworks!

workspace 'FogMachine'
xcodeproj 'FogMachine/FogMachine.xcodeproj'
xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'

target 'FogViewshed' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'SSZipArchive', '~> 1.1'
    #pod 'GEOSwift'
    pod 'SwiftEventBus', :git => 'https://github.com/cesarferreira/SwiftEventBus.git', :tag => '1.1.0'
    pod 'Buckets', :git => 'https://github.com/mauriciosantos/Buckets-Swift.git', :tag => '1.2.1'
    pod 'FogMachine', :path => 'FogMachine/'
    # Even though FogMachine depends on peerkit already, we must add peerkit here again.  This is because the dependency directive in the podspec only supports the name of the dependency and any optional version requirement. The :git option is not supported.
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
end

target 'FogViewshedTests' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
end

target 'FogMachine' do
    platform :ios, '8.4'
    xcodeproj 'FogMachine/FogMachine.xcodeproj'
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
    #pod 'PeerKit', :path => '../PeerKit'
end
