Pod::Spec.new do |s|
	s.name             = 'FogMachine'
	s.version          = '4.0.0'
	s.summary          = 'iOS Framework for parallel processing'
	s.homepage         = 'https://github.com/ngageoint/fog-machine'
	s.license          = {:type => 'MIT', :file => 'LICENSE' }
	s.authors          = { 'NGA' => '', 'BIT Systems' => '', 'Scott Wiedemann' => 'lemmingapex@gmail.com', 'Chris Wasko' => 'cwasko@caci.com' }
	s.social_media_url = 'https://twitter.com/NGA_GEOINT'
	s.source           = { :git => 'https://github.com/ngageoint/fog-machine', :tag => s.version }
	s.requires_arc = true

	s.platform         = :ios, '8.4'
	s.ios.deployment_target = '8.4'

	s.source_files = 'FogMachine/**/*.swift'

	s.resource_bundle = { 'FogMachine' => ['FogMachine/**/*.plist'] }
	s.frameworks = 'Foundation'

	s.dependency 'SwiftEventBus', '~> 1.1.0'
end
