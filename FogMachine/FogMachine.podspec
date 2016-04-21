
Pod::Spec.new do |s|
s.name             = "FogMachine"
s.version          = "3.0.0"
s.summary          = "iOS Framework for parallel processing"
s.description      = <<-DESC
iOS framework for FogMachine, assist with:
* FogMachine Multipeer Connectivity
DESC
s.homepage         = "https://www.nga.mil"
s.license          = 'DOD'
s.author           = { "NGA" => "cwasko@caci.com" }
#s.source           = { :git => "https://git.geointapps.org/fogmachine", :tag => s.version.to_s }

s.platform         = :ios, '8.4'
s.ios.deployment_target = '8.4'
s.requires_arc = true

s.source_files = 'FogMachine/**/*.swift'
s.frameworks = 'Foundation'
end
