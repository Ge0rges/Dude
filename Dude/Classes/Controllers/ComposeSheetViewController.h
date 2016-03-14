//
//  ComposeSheetViewController.h
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>

// Models
#import "DMessage.h"

@interface ComposeSheetViewController : UIViewController

@property (strong, nonatomic) DMessage * _Nonnull selectedMessage;
@property (strong, nonatomic) NSSet * _Nonnull selectedUsers;

@end
