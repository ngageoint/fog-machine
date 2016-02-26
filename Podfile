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
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.0'
end

target 'FogViewshedTests' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
end

target 'FogSearch' do
    platform :ios, '8.4'
    xcodeproj 'Demo/FogSearch/FogSearch.xcodeproj'
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.0'
end

target 'Fog' do
    platform :ios, '8.4'
    xcodeproj 'Fog/Fog.xcodeproj'
    pod 'PeerKit', :git => 'https://github.com/cwas/PeerKit.git', :tag => '2.0.0'
end
