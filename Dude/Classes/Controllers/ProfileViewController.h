//
//  ProfileViewController.h
//  Dude
//
//  Created by Georges Kanaan on 6/2/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>

// Constants
#import "Constants.h"

// Models
#import "DUser.h"

@interface ProfileViewController : UIViewController

@property (strong, nonatomic) DUser *profileUser;

@end
