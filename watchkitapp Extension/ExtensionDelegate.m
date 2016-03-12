//
//  ExtensionDelegate.m
//  watchkitapp Extension
//
//  Created by Georges Kanaan on 13/11/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import "ExtensionDelegate.h"

// Frameworks
#import <WatchConnectivity/WatchConnectivity.h>

// Models
#import "DUserWatch.h"

// Constants
#import "Constants.h"

// Pods
#import <Parse/Parse.h>

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
  // Perform any final initialization of your application.
    
  // Parse setup
  [DUserWatch registerSubclass];
  [Parse setApplicationId:@"Lwdk0Qnb9755omfrz9Jt1462lzCyzBSTU4lSs37S" clientKey:@"bqhjVGFBHTtfjyoRG8WlYBrjqkulOjcilhtQursd"];
}

- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
  if ([identifier isEqualToString:@"REPLY_ACTION"]) {// If it's a reply action
    WCSession *session = [WCSession defaultSession];
    session.delegate = self;
    [session activateSession];

    NSDictionary *applicationContext = [session receivedApplicationContext];
    
    NSSet *contacts = applicationContext[WatchContextContactsKey];
    
    DUserWatch *sendUser;
    
    for (DUserWatch *user in contacts) {
      if ([user.email isEqualToString:remoteNotification[@"email"]]) {
        sendUser = user;
        
        break;
      }
    }
    
    [[WKExtension sharedExtension].rootInterfaceController pushControllerWithName:@"MessagesController" context:sendUser];
  }
}

@end
