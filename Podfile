# Uncomment the next line to define a global platform for your project
# platform :ios, '13.6'

target 'VideoPlayerAndRenderDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'SnapKit', '~> 5.6.0'
  pod 'Toast-Swift', '~> 5.1.1'
end


post_install do |installer|
  #解决第三方框架deployment target版本过低的问题
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.6'
      end
    end
  end
end