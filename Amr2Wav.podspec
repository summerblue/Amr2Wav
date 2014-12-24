#
#  Be sure to run `pod spec lint Amr2Wav.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  
  s.name               = "Amr2Wav"
  s.version            = "0.0.6"
  s.summary            = "A library that convert audio file format from amr to wav ."
  s.homepage           = "https://github.com/summerblue/Amr2Wav"
  
  s.license            = "MIT"
  s.author             = { "Charlie Jade" => "summer.alex07@gmail.com" }
  s.social_media_url   = "http://summerblue.me"
  s.platform           = :ios, "5.0"
  
  s.source             = { :git => "https://github.com/summerblue/Amr2Wav.git", :tag => s.version }
  
  s.requires_arc       = true
  s.source_files       = 'amr2wav/**/*.{h,m}'
  s.vendored_libraries = 'amr2wav/lib/libopencore-amrnb.a'

end
