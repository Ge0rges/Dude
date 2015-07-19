source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

link_with 'Dude', 'Dude WatchKit Extension'

def shared_pods
  pod 'Parse'
end

target :'Dude WatchKit Extension' do
  shared_pods
end

target :'Dude' do
  shared_pods
  pod 'Reachability'
  pod 'SOMotionDetector'
  pod 'JFMinimalNotifications'
  pod 'SDWebImage'
  pod 'SWTableViewCell'
  pod 'APAddressBook'
end