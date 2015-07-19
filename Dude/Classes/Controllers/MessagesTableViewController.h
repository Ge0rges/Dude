//
//  MessagesTableViewController.h
//  Dude
//
//  Created by Georges Kanaan on 6/6/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>

// Constants
#import "Constants.h"

@interface MessagesTableViewController : UITableViewController

@property (strong, nonatomic) NSArray *selectedUsers;
@property (nonatomic) BOOL selectedTwitter;
@property (nonatomic) BOOL selectedFacebook;

@end
