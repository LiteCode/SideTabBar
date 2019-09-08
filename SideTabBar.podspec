#
# Be sure to run `pod lib lint SideTabBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SideTabBar'
  s.version          = '0.1.0'
  s.summary          = 'Side Tab Bar Controller looks like VSCode tab bar'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SideTabBar a simple library with native api, who replicate VSCode tab bar.
                       DESC

  s.homepage         = 'https://github.com/spectraldragon/SideTabBar'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'spectraldragon' => 'spectraldragonchannel@gmail.com' }
  s.source           = { :git => 'https://github.com/spectraldragon/SideTabBar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mashiply'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.1'

  s.source_files = 'Sources/SideTabBar/**/*'

end
