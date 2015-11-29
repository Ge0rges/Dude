//
//  MessageInterfaceController.m
//  Dude
//
//  Created by Georges Kanaan on 2/22/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "MessageInterfaceController.h"

// Frameworks
#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

// Models
#import "RowController.h"
#import "DUserWatch.h"

// Constants
#import "Constants.h"

@interface MessageInterfaceController() <WCSessionDelegate> {
  DUserWatch *selectedUser;
  
  NSArray *messages;
 
  WCSession *session;
}

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *notLoggedInLabel;

@end


@implementation MessageInterfaceController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  // Configure interface objects here.
  
  selectedUser = context;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if ([WCSession isSupported]) {
      session = [WCSession defaultSession];
      session.delegate = self;
      [session activateSession];
    }
  });
  
  // Set the messages
  messages = session.receivedApplicationContext[@"messages"];
  
  // Check that we have message
  if (!messages) {
    // Update UI
    [self.notLoggedInLabel setHidden:NO];
    [self.table setHidden:YES];
    
    
    // Run a backup query by asking for messages (takes more time)
    [session sendMessage:@{WatchRequestMessages: WatchRequestsKey} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
      messages = replyMessage[@"messages"];
      
      if (!messages) {
        // Update UI
        [self.notLoggedInLabel setHidden:NO];
        [self.table setHidden:YES];
        
      } else {
        // Update UI
        [self.notLoggedInLabel setHidden:YES];
        [self.table setHidden:NO];
        
        // Update table
        [self configureTableWithMessages];
      }
      
    } errorHandler:^(NSError * _Nonnull error) {
      // Update UI
      [self.notLoggedInLabel setHidden:NO];
      [self.table setHidden:YES];
      
      // Start a timer to check again
      [self awakeWithContext:context];
    }];
    
  } else {
    // Update UI
    [self.notLoggedInLabel setHidden:YES];
    [self.table setHidden:NO];
    
    // Update table
    [self configureTableWithMessages];
  }
}


- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user
  [super willActivate];
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session didReceiveMessageData:(nonnull NSData *)messageData {
  
}

#pragma mark - Table Rows
- (void)configureTableWithMessages {
  [self.table setNumberOfRows:messages.count withRowType:@"rowController"];
  
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];
    [row.textLabel setText:messages[i]];
  }
}

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)rowIndex {
  //TO DO: Replace with WCSession updateContext
  NSDictionary *payload =  @{WatchRequestSendMessages: WatchRequestsKey,
                             @"message": messages[rowIndex],
                             @"senderEmail": selectedUser.email
                             };
  
#warning handle errors and replies if necessary
  [session sendMessage:payload replyHandler:nil errorHandler:nil];
  
  [self popToRootController];
}

#pragma mark - Notification handling
- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
  NSString *senderEmail = remoteNotification[@"email"];
  
  PFQuery *senderQuery = [DUserWatch query];
  [senderQuery whereKey:@"email" equalTo:senderEmail];
  
  selectedUser = (DUserWatch*)[senderQuery getFirstObject];
}

@end