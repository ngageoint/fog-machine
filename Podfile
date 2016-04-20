# Uncomment this line to define a global platform for your project
platform :ios, '8.4'
use_frameworks!

workspace 'FogMachine'
xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
xcodeproj 'Demo/FogSearch/FogSearch.xcodeproj'
xcodeproj 'Fog/Fog.xcodeproj'

target 'FogViewshed' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'SSZipArchive', '~> 1.1'
    #pod 'GEOSwift'
    pod 'SwiftEventBus', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
    pod 'Fog', :path => 'Fog/'
end

target 'FogViewshedTests' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
end

target 'FogSearch' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogSearch/FogSearch.xcodeproj'
    pod 'Fog', :path => 'Fog/'
end

target 'Fog' do
    platform :ios, '8.4'
    xcodeproj 'Fog/Fog.xcodeproj'
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.1'
    #pod 'PeerKit', :path => '../PeerKit'
end
