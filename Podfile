source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
link_with 'Dude', 'Watch Extension'

def shared_pods
  pod 'Parse'
end

target :'Watch Extension' do
  platform :watchos, '2.0'
  shared_pods
end

target :'Dude' do
  platform :ios, '9.0'
  shared_pods
  pod 'SDWebImage'
  pod 'Reachability'
  pod 'SOMotionDetector'
end