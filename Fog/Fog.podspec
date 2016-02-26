
Pod::Spec.new do |s|
s.name             = "Fog"
s.version          = "2.0.0"
s.summary          = "iOS Framework for FogMachine"
s.description      = <<-DESC
iOS framework for FogMachine, assist with:
* FogMachine Multipeer Connectivity
DESC
s.homepage         = "https://www.nga.mil"
s.license          = 'DOD'
s.author           = { "NGA" => "cwasko@caci.com" }
#s.source           = { :git => "https://github.com/ngageoint/", :tag => s.version.to_s }

s.platform         = :ios, '8.0'
s.ios.deployment_target = '8.0'
s.requires_arc = true

s.source_files = 'Fog/**/*.swift'
#s.prefix_header_file = 'Fog/fog-Prefix.pch'

#s.ios.exclude_files = 'Classes/osx'
#s.osx.exclude_files = 'Classes/ios'
# s.public_header_files = 'Classes/**/*.h'
#s.resource_bundle = { 'Fog' => ['Fog/**/*.plist'] }
#s.resources = ['Fog/**/*.xcdatamodeld']
s.frameworks = 'Foundation'
end