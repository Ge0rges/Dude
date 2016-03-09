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
  
  NSMutableArray *contactsLeft;
  NSMutableArray *contactsRight;
  
  NSInteger rowIndex;
}

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *notLoggedInLabel;


@end


@implementation InterfaceController

- (void)awakeWithContext:(NSArray*)context {
  [super awakeWithContext:context];
  
  // Configure interface objects here.
  PFQuery *contactsQuery = [DUserWatch query];
  [contactsQuery fromPinWithName:WatchRequestContacts];
  
  [contactsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    contacts = [objects copy];
    
    if (error || !contacts || contacts.count == 0) {
      // Update UI
      if (!error && contacts.count == 0) {
        [self.notLoggedInLabel setText:@"Dude, use your phone to add your closest friends to show up here."];
      
      } else {
        [self.notLoggedInLabel setText:@"Woah Dude, make sure your phone is connected to the internet and your watch."];
      }
      
      [self.notLoggedInLabel setHidden:NO];
      [self.table setHidden:YES];
      
      // Start a timer to check again
      [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(awakeWithContext:) userInfo:nil repeats:NO];
      
    } else {
      // Update UI
      [self.table setHidden:NO];
      [self.notLoggedInLabel setHidden:YES];
      
      // Update table
      [self configureTableWithContacts];
    }
  }];
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
    if (i % 2 == 0)// If the index/2 has a modulo of 0
      // Add object to right array
      [contactsLeft addObject:[contacts objectAtIndex:i]];
    else
      [contactsRight addObject:[contacts objectAtIndex:i]];
  }
  
  // Set the number of rows
  [self.table setNumberOfRows:ceil([contacts count]/2.0) withRowType:@"rowController"];
  
  
  // Configure each row left
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];
    DUserWatch *user = [contactsLeft objectAtIndex:i];
    
    // Get Image
    UIImage *profileImage = [UIImage imageWithData:[user.profileImage getData]];
    
    // Populate the view
    [row.leftImageViewGroup setBackgroundImage:profileImage];
    
    [row setDelegate:self];// Set the delegate for buttons
  }
  
  // Configure each row right
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    if (contactsRight.count > i) {
      RowController *row = [self.table rowControllerAtIndex:i];
      DUserWatch *user = [contactsRight objectAtIndex:i];
      
      // Get image
      UIImage *profileImage = [UIImage imageWithData:[user.profileImage getData]];
      
      // Populate the view
      [row.rightImageViewGroup setBackgroundImage:profileImage];
    
    }
  }
}

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)lclRowIndex {
  rowIndex = lclRowIndex;
}

- (void)tappedLeftImageViewGroup:(WKInterfaceGroup*)imageView {
  [self pushControllerWithName:@"MessagesController" context:contactsLeft[rowIndex]];
}

- (void)tappedRightImageViewGroup:(WKInterfaceGroup*)imageView {
  if (contactsRight.count > rowIndex) {
    [self pushControllerWithName:@"MessagesController" context:contactsRight[rowIndex]];
  }
}

#pragma mark - Notification Hadnling
- (void)handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)remoteNotification {
  NSString *senderEmail = remoteNotification[@"email"];
  
  PFQuery *senderQuery = [DUserWatch query];
  [senderQuery whereKey:@"email" equalTo:senderEmail];
  
  [self pushControllerWithName:@"MessagesController" context:[senderQuery getFirstObject]];
}

@end