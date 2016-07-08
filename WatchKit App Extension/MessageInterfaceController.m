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
#import "DMessage.h"

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
  
  selectedUser = context[WatchContactsKey];
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    session = [WCSession defaultSession];
    session.delegate = self;
    [session activateSession];
  });
  
  // Set the messages
  messages = context[WatchMessagesKey];
  
  // Check that we have message
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
}


#pragma mark - Table Rows
- (void)configureTableWithMessages {
  [self.table setNumberOfRows:messages.count withRowType:@"rowController"];
  
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];
    DMessage *message = messages[i];

    // Text
    [row.textLabel setText:message.message];
    
    // Images
    if (i <= 6) {// Default messages handle image differently
      NSString *imageName = [message.imageURL.absoluteString stringByReplacingOccurrencesOfString:@"_" withString:@" "];
      imageName = [imageName stringByReplacingOccurrencesOfString:@"http://" withString:@""];
      imageName = [imageName stringByReplacingOccurrencesOfString:@".com" withString:@""];
      imageName = [imageName stringByAppendingString:@" Watch"];
      
      [row.imageView setImageNamed:imageName];
    
    } else {
// TODO: implement new DMessage method for UIImage storage
    }
  }
}

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSDictionary *payload =  @{WatchRequestTypeKey: WatchRequestSendMessageValue,
                             WatchMessagesKey: messages[rowIndex],
                             WatchContactsKey: selectedUser.recordIDData
                             };
  
  if (session.reachable) {
    [session sendMessage:payload replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
      [self popToRootController];
    
    } errorHandler:^(NSError * _Nonnull error) {
      [WKAlertAction actionWithTitle:@"Dude, I couldn't send your message! Try again." style:WKAlertActionStyleDefault handler:^{
        [self popToRootController];
      }];
    }];
  
  } else {
    [WKAlertAction actionWithTitle:@"Dude, I couldn't send your message! Make sure your connected to your phone." style:WKAlertActionStyleDefault handler:^{
      [self popToRootController];
    }];
  }
}

@end