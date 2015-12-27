//
//  ExtensionDelegate.m
//  watchkitapp Extension
//
//  Created by Georges Kanaan on 13/11/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import "ExtensionDelegate.h"

// Pods
#import <Parse/Parse.h>

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
  // Perform any final initialization of your application.
  
  // Enable data sharing in app extensions for localDatastore
  //[Parse enableDataSharingWithApplicationGroupIdentifier:@"group.com.ge0rges.Dude"];
  
  // Setup Parse
  [Parse setApplicationId:@"Lwdk0Qnb9755omfrz9Jt1462lzCyzBSTU4lSs37S" clientKey:@"bqhjVGFBHTtfjyoRG8WlYBrjqkulOjcilhtQursd"];
}

- (void)applicationDidBecomeActive {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
#warning implement reply to notification
}

@end
