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

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
  // Perform any final initialization of your application.
}

- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
  if ([identifier isEqualToString:@"REPLY_ACTION"]) {// If it's a reply action
    
    WCSession *session = [WCSession defaultSession];
    session.delegate = self;
    [session activateSession];

    NSDictionary *applicationContext = [session receivedApplicationContext];
    
    NSArray *contacts = applicationContext[WatchContactsKey];
    
    DUserWatch *sendUser;
    
    if (!remoteNotification[@"recordID"]) {
      NSLog(@"%@", remoteNotification);
    }
    
    for (DUserWatch *user in contacts) {
      if ([user.recordIDData isEqualToData:[NSKeyedArchiver archivedDataWithRootObject:remoteNotification[@"recordID"]]]) {
        sendUser = user;
        
        break;
      }
    }
    
    [[WKExtension sharedExtension].rootInterfaceController pushControllerWithName:@"MessagesController" context:sendUser];
  }
}

@end
