//
//  InterfaceController.m
//  Dude WatchKit Extension
//
//  Created by Georges Kanaan on 2/14/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "InterfaceController.h"

// Frameworks
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <WatchKit/WatchKit.h>

// Models
#import "RowController.h"
#import "DUserWatch.h"

// Constants
#import "Constants.h"

@interface InterfaceController() <RowControllerDelegate, WCSessionDelegate> {
  NSArray *contacts;
  NSArray *messages;
  
  NSMutableArray *contactsLeft;
  NSMutableArray *contactsRight;
  
  NSInteger rowIndex;
  
  WCSession *session;
  
  BOOL completedMessagesFetching;
}

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *notLoggedInLabel;


@end


@implementation InterfaceController

- (void)awakeWithContext:(NSArray*)context {
  [super awakeWithContext:context];
  
  // Configure interface objects here.
  
  // Start a WCSession to get the latest context from the app (contacts)
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    session = [WCSession defaultSession];
    session.delegate = self;
    [session activateSession];
  });
  
  [self reloadContactsFromApplicationContext:[session receivedApplicationContext]];
  [self requestMessages];
}

- (void)didAppear {
  if (contacts.count == 0) {
    [self awakeWithContext:nil];
  }
}

#pragma mark - Table Rows
- (void)configureTableWithContacts {
  // Init the new arrays
  contactsLeft = [NSMutableArray new];
  contactsRight = [NSMutableArray new];
  
  for (NSInteger i=0; i < contacts.count; i++) {
    if (i % 2 == 0) {// If the index/2 has a modulo of 0 (splits contacts into two indexes)
      // Add object to right array
      [contactsLeft addObject:contacts[i]];
      
    } else {
      [contactsRight addObject:contacts[i]];
    }
  }
  
  // Set the number of rows
  [self.table setNumberOfRows:ceil([contacts count]/2.0) withRowType:@"rowController"];
  
  
  // Configure each row left
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];
    DUserWatch *user = contactsLeft[i];
    
    // Get Image
    UIImage *profileImage = user.profileImage;
    
    // Populate the view
    [row.leftImageViewGroup setBackgroundImage:profileImage];
    
    [row setDelegate:self];// Set the delegate for buttons
  }
  
  // Configure each row right
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];

    if (contactsRight.count > i) {
      DUserWatch *user = contactsRight[i];
      
      // Get image
      UIImage *profileImage = user.profileImage;
      
      // Populate the view
      [row.rightImageViewGroup setBackgroundImage:profileImage];
      
    } else {
      // Remove the placeholders
      [row.rightImageViewGroup setBackgroundImage:nil];

    }
  }
}

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)lclRowIndex {
  rowIndex = lclRowIndex;// Set the rowindex
}

- (void)tappedLeftImageViewGroup:(WKInterfaceGroup*)imageView {
  while (!completedMessagesFetching) {sleep(5000);}
  [self pushControllerWithName:@"MessagesController" context:@{WatchMessagesKey: messages, WatchContactsKey: contactsLeft[rowIndex]}];
}

- (void)tappedRightImageViewGroup:(WKInterfaceGroup*)imageView {
  if (contactsRight.count > rowIndex) {// Make sure there's an image
    while (!completedMessagesFetching) {sleep(5000);}
    [self pushControllerWithName:@"MessagesController" context:@{WatchMessagesKey: messages, WatchContactsKey: contactsRight[rowIndex]}];
  }
}

#pragma mark - WCSession Manager
- (void)session:(WCSession *)localSession didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
  [self reloadContactsFromApplicationContext:applicationContext];
}

- (void)reloadContactsFromApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
  NSArray *contactsData = applicationContext[WatchContactsKey];
  
  NSMutableArray *mutableContacts = [NSMutableArray new];
  for (NSData *userData in contactsData) {
    DUserWatch *watchUser = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
    [mutableContacts addObject:watchUser];
  }
  
  contacts = [mutableContacts copy];
  messages = [NSArray new];
  
  if (contacts.count > 0) {
    // Update UI
    [self.table setHidden:NO];
    [self.notLoggedInLabel setHidden:YES];
    
    // Update table
    [self configureTableWithContacts];
    
  } else {
    // Update UI
    if (applicationContext) {
      [self.notLoggedInLabel setText:@"Dude, add your closest friends as favorites on your phone."];
      
    } else {
      [self.notLoggedInLabel setText:@"Woah Dude, make sure your phone is connected to the internet and your watch."];
    }
    
    [self.notLoggedInLabel setHidden:NO];
    [self.table setHidden:YES];
  }
}

- (void)requestMessages {
  // Generate the messages for next interface controller
  if (session.isReachable) {
    [session sendMessage:@{WatchRequestTypeKey: WatchRequestMessagesValue} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
      messages = replyMessage[WatchMessagesKey];
      completedMessagesFetching = YES;
      
    } errorHandler:^(NSError * _Nonnull error) {
      if (error.code == 7012 || error.code == 7014) [self requestMessages];
      NSLog(@"error fetching messages: %@", error);
      completedMessagesFetching = YES;
    }];
    
  } else {
    NSLog(@"error fetching messages: not reachable");
  }
}

@end