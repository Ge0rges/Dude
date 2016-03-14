//
//  MessagesTableViewController.h
//  Dude
//
//  Created by Georges Kanaan on 6/6/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>

@interface MessagesTableViewController : UITableViewController

@property (strong, nonatomic) NSArray * _Nullable selectedUsers;// Public so that notifications can set it

@end
