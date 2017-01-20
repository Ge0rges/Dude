source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

def shared_pods
  pod 'Parse'
end

target :'Watch Extension' do
  platform :watchos, '2.0'
  shared_pods
end

target :'Dude' do
  platform :ios, '9.0'
  pod 'SDWebImage'
  pod 'JCNotificationBannerPresenter'
  pod 'SOMotionDetector'
  shared_pods
end
