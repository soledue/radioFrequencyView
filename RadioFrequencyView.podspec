Pod::Spec.new do |s|
  s.name             = 'RadioFrequencyView'
  s.version          = '1.0.12'
  s.summary          = 'The RadioFrequencyView is Simple AM/FM Slider View'
  s.homepage         = 'https://github.com/soledue/radioFrequencyView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kanev' => 'soledue@gmail.com' }
  s.source           = { :git => 'https://github.com/soledue/radioFrequencyView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'
  s.source_files = 'Source/**/*'
end
