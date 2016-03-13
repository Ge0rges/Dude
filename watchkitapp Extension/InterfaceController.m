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
  NSSet *contacts;
  
  NSMutableArray *contactsLeft;
  NSMutableArray *contactsRight;
  
  NSInteger rowIndex;
  
  WCSession *session;
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
  
  NSDictionary *applicationContext = [session receivedApplicationContext];
  
  NSArray *contactsData = [(NSSet*)applicationContext[WatchContextContactsKey] allObjects];
  
  NSMutableArray *mutableContacts = [NSMutableArray new];
  for (NSData *userData in contactsData) {
    DUserWatch *watchUser = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
    [mutableContacts addObject:watchUser];
  }
  
  contacts = [mutableContacts copy];
  
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
      [contactsLeft addObject:[[contacts allObjects] objectAtIndex:i]];
    else
      [contactsRight addObject:[[contacts allObjects] objectAtIndex:i]];
  }
  
  // Set the number of rows
  [self.table setNumberOfRows:ceil([contacts count]/2.0) withRowType:@"rowController"];
  
  
  // Configure each row left
  for (NSInteger i = 0; i < self.table.numberOfRows; i++) {
    RowController *row = [self.table rowControllerAtIndex:i];
    DUserWatch *user = [contactsLeft objectAtIndex:i];
    
    // Get Image
    UIImage *profileImage = user.profileImage;
    
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
      UIImage *profileImage = user.profileImage;
      
      // Populate the view
      [row.rightImageViewGroup setBackgroundImage:profileImage];
    
    }
  }
}

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)lclRowIndex {
  rowIndex = lclRowIndex;// Set the rowindex
}

- (void)tappedLeftImageViewGroup:(WKInterfaceGroup*)imageView {
  [self pushControllerWithName:@"MessagesController" context:contactsLeft[rowIndex]];
}

- (void)tappedRightImageViewGroup:(WKInterfaceGroup*)imageView {
  if (contactsRight.count > rowIndex) {// Make sure there's an image
    [self pushControllerWithName:@"MessagesController" context:contactsRight[rowIndex]];
  }
}

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {  
  NSArray *contactsData = [(NSSet*)applicationContext[WatchContextContactsKey] allObjects];
  
  NSMutableArray *mutableContacts = [NSMutableArray new];
  for (NSData *userData in contactsData) {
    DUserWatch *watchUser = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
    [mutableContacts addObject:watchUser];
  }
  
  contacts = [mutableContacts copy];
  
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

@end