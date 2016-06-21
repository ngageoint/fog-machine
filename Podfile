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
    pod 'SwiftEventBus', '~> 1.1.0'
end

target 'FogStringSearch' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
    pod 'FogMachine', :path => '.'
end

target 'FogStringSearchTests' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
end

target 'FogViewshed' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'FogMachine', :path => '.'
    pod 'SSZipArchive', '~> 1.1'
    pod 'Buckets', :git => 'https://github.com/mauriciosantos/Buckets-Swift.git', :tag => '1.2.1'
end

target 'FogViewshedTests' do
    platform :ios, '9.0'
    xcodeproj 'Demo/FogViewshed/FogViewshed.xcodeproj'
end
