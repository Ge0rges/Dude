//
//  RowController.h
//  Dude
//
//  Created by Georges Kanaan on 2/22/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@protocol RowControllerDelegate <NSObject>

@required
- (void)tappedLeftImageViewGroup:(WKInterfaceGroup*)imageViewGroup;
- (void)tappedRightImageViewGroup:(WKInterfaceGroup*)imageViewGroup;
@end


@interface RowController : NSObject

@property (strong, nonatomic) id<RowControllerDelegate> delegate;

// Messages
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *imageView;

// Contacts
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *leftImageViewGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *rightImageViewGroup;

@end
