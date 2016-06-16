# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
use_frameworks!

workspace 'FogMachine'
xcodeproj 'FogMachine/FogMachine.xcodeproj'
xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
xcodeproj 'Demo/FogStringSearch/FogStringSearch.xcodeproj'

target 'FogMachine' do
    platform :ios, '9.0'
    xcodeproj 'FogMachine/FogMachine.xcodeproj'
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
    pod 'SwiftEventBus', '~> 1.1.0'
    # pod 'PeerKit', :path => '../PeerKit'
end

target 'FogStringSearch' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
    pod 'FogMachine', :path => '.'
    # Even though FogMachine depends on peerkit already, we must add peerkit here again.  This is because the dependency directive in the podspec only supports the name of the dependency and any optional version requirement. The :git option is not supported.
    # pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
end

target 'FogViewshed' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'FogMachine', :path => '.'
    # Even though FogMachine depends on peerkit already, we must add peerkit here again.  This is because the dependency directive in the podspec only supports the name of the dependency and any optional version requirement. The :git option is not supported.
    # pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
    pod 'SSZipArchive', '~> 1.1'
    pod 'Buckets', :git => 'https://github.com/mauriciosantos/Buckets-Swift.git', :tag => '1.2.1'
end

target 'FogViewshedTests' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
end
