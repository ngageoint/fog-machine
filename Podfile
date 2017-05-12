# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
use_frameworks!

workspace 'FogMachine'
project 'FogMachine/FogMachine.xcodeproj'
project 'Demo/FogViewshed/FogViewshed.xcodeproj'
project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'

target 'FogMachine' do
    platform :ios, '9.0'
    project 'FogMachine/FogMachine.xcodeproj'
    pod 'SwiftEventBus', '~> 2.1'
end

target 'FogStringSearch' do
    platform :ios, '9.0'
    project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
    pod 'FogMachine', :path => '.'
end

target 'FogStringSearchTests' do
    platform :ios, '9.0'
    project 'Demo/FogStringSearch/FogStringSearch.xcodeproj'
end

target 'FogViewshed' do
    platform :ios, '9.0'
    project 'Demo/FogViewshed/FogViewshed.xcodeproj'
    pod 'FogMachine', :path => '.'
    pod 'SSZipArchive', '~> 1.1'
#pod 'Buckets', '~> 2.0'
#Buckets version 2.0.1 isn't in Cocoapods, so pull from github
    pod 'Buckets', :git => 'https://github.com/mauriciosantos/Buckets-Swift.git'
    pod 'Toast-Swift', '~> 2.0.0'
    pod 'EZLoadingActivity', '~> 1.0'
end

target 'FogViewshedTests' do
    platform :ios, '9.0'
    project 'Demo/FogViewshed/FogViewshed.xcodeproj'
end

