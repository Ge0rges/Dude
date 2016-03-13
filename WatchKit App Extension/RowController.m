//
//  RowController.m
//  Dude
//
//  Created by Georges Kanaan on 2/22/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "RowController.h"

@implementation RowController

- (IBAction)tappedLeftButton:(WKInterfaceButton*)sender {
    [self.delegate tappedLeftImageViewGroup:self.leftImageViewGroup];
}

- (IBAction)tappedRightButton:(WKInterfaceButton*)sender {
    [self.delegate tappedRightImageViewGroup:self.rightImageViewGroup];
}

@end
