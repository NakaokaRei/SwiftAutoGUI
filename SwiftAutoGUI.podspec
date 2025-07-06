#
#  Be sure to run `pod spec lint SwiftAutoGUI.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "SwiftAutoGUI"
  spec.version      = "0.4.0"
  spec.summary      = "Used to programmatically control the mouse & keyboard."
  spec.homepage     = "https://github.com/NakaokaRei/SwiftAutoGUI"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "NakaokaRei" => "reideeplearning@gmail.com" }
  spec.social_media_url   = "https://twitter.com/rei_nakaoka"
  spec.source       = { :git => "https://github.com/NakaokaRei/SwiftAutoGUI.git", :tag => "#{spec.version}" }

  spec.source_files  = "Sources/**/*.{swift}"

  spec.platform     = :osx, "12.0"
  spec.swift_version = "5.5"

end
