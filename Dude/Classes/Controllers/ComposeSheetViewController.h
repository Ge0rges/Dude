//
//  ComposeSheetViewController.h
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

// Frmeworks
#import <UIKit/UIKit.h>

// Models
#import "DMessage.h"

@interface ComposeSheetViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) DMessage *selectedMessage;
@property (strong, nonatomic) NSSet *selectedUsers;

@end
