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

// Models
#import "RowController.h"

// Constants
#import "Constants.h"

@interface MessageInterfaceController() {
  DUser *selectedUser;
  NSArray *messages;
}

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *notLoggedInLabel;

@end


@implementation MessageInterfaceController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  // Configure interface objects here.
  
  selectedUser = context;
}

- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user
  [super willActivate];
  
  // Ask for messages
  [WKInterfaceController openParentApplication:@{WatchRequestMessages: WatchRequestsKey} reply:^(NSDictionary *replyInfo, NSError *error) {
    // Set the messages
    messages = replyInfo[@"messages"];
    
    // Check that we have message
    if (error || !messages) {
      // Update UI
      [self.notLoggedInLabel setHidden:NO];
      [self.table setHidden:YES];
      
      // Start a timer to check again
      [self willActivate];
      
    } else {
      // Update UI
      [self.notLoggedInLabel setHidden:YES];
      [self.table setHidden:NO];
      
      // Update table
      [self configureTableWithMessages];
    }
  }];
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
  [WKInterfaceController openParentApplication:@{WatchRequestSendMessages: WatchRequestsKey,
                                                 @"message": messages[rowIndex],
                                                 @"senderEmail": selectedUser.email}
                                         reply:NULL];
  
  [self popToRootController];
}

#pragma mark - Notification handling
- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
  NSString *senderEmail = remoteNotification[@"email"];
  
  PFQuery *senderQuery = [DUser query];
  [senderQuery whereKey:@"email" equalTo:senderEmail];
  
  selectedUser = (DUser*)[senderQuery getFirstObject];
}

@end