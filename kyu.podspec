#
#  Be sure to run `pod spec lint kyu.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "Kyu"
  s.version      = "0.9.0"
  s.summary      = "Kyu is persitant queue system written in Swift. Inspired by Sidekiq."
  s.homepage     = "http://red.to"

  s.license      = "MIT"
  s.author             = { "Red Davis" => "me@red.to" }
  s.social_media_url   = "http://twitter.com/reddavis"

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"

  s.source       = { :git => "http://github.com/reddavis/kyu.git", :tag => "#{s.version}" }

  s.subspec 'Core' do |core|
    core.source_files = ['Kyu']
  end

  s.subspec 'iOS' do |ios|
    ios.source_files = ['Kyu iOS', 'Kyu']
  end
end
