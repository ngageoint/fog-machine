# Uncomment this line to define a global platform for your project
platform :ios, '11.4'
use_frameworks!

workspace 'FogMachine'
project 'FogMachine/FogMachine.xcodeproj'
project 'Demo/FogViewshed/FogViewshed.xcodeproj'
project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'

target 'FogMachine' do
    platform :ios, '11.4'
    project 'FogMachine/FogMachine.xcodeproj'
    pod 'SwiftEventBus', :tag => '3.0.0', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
end

target 'FogStringSearch' do
    platform :ios, '11.4'
    project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
    pod 'FogMachine', :path => '.'
end

target 'FogStringSearchTests' do
    platform :ios, '11.4'
    project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
end

target 'FogViewshed' do
    platform :ios, '11.4'
    project 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'FogMachine', :path => '.'
    pod 'SSZipArchive', '~> 2.1.4'
    pod 'Toast-Swift', '~> 4.0.0'
end

target 'FogViewshedTests' do
    platform :ios, '11.4'
    project 'Demo/FogViewshed/FogViewshed.xcodeproj'
end
