//
//  ComposeSheetViewController.h
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import <UIKit/UIKit.h>

// Models
#import "DMessage.h"

@interface ComposeSheetViewController : UIViewController

@property (strong, nonatomic) DMessage *selectedMessage;

@end
