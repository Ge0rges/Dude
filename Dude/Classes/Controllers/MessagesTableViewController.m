//
//  MessagesTableViewController.m
//  Dude
//
//  Created by Georges Kanaan on 6/6/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "MessagesTableViewController.h"

// Classes
#import "AppDelegate.h"
#import "ComposeSheetViewController.h"

// Managers
#import "MessagesManager.h"

// Pods
#import <SDWebImage/UIImageView+WebCache.h>

// Extensions & Categories
#import "UIImageExtensions.h"

// Constants
#import "Constants.h"

@interface MessagesTableViewController () {
  NSArray *messages;
}

@end

@implementation MessagesTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;

  // Generate Messages
  [self reloadData];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  return (section == 0) ? @"CHOOSE AN UPDATE TO SEND" : @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return messages.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
  
  // Get the message
  DMessage *message = (DMessage*)messages[indexPath.section];
  
  // Configure the cell
  [cell.textLabel setText:message.message];
  [cell.imageView sd_setImageWithURL:message.imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    [UIView animateWithDuration:0.15 animations:^{
      [cell.imageView setImage:[image resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
      [cell layoutSubviews];
    }];
  }];
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  DMessage *message = messages[indexPath.row];
  
  [self performSegueWithIdentifier:@"composingSheet" sender:message];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
  if ([cell respondsToSelector:@selector(tintColor)]) {
    CGFloat cornerRadius = 7.f;
    cell.backgroundColor = UIColor.clearColor;
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGRect bounds = CGRectInset(cell.bounds, 10, 0);
    BOOL addLine = NO;
    
    if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
      CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
      
    } else if (indexPath.row == 0) {
      CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
      CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
      CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
      CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
      addLine = YES;
      
    } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
      CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
      CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
      CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
      CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
      
    } else {
      CGPathAddRect(pathRef, nil, bounds);
      addLine = YES;
    }
    
    layer.path = pathRef;
    CFRelease(pathRef);
    layer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
    
    if (addLine == YES) {
      CALayer *lineLayer = [[CALayer alloc] init];
      CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
      lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-10, lineHeight);
      lineLayer.backgroundColor = tableView.separatorColor.CGColor;
      [layer addSublayer:lineLayer];
    }
    
    UIView *testView = [[UIView alloc] initWithFrame:bounds];
    [testView.layer insertSublayer:layer atIndex:0];
    testView.backgroundColor = UIColor.clearColor;
    cell.backgroundView = testView;
  }
}

- (IBAction)reloadData {
  [self.refreshControl performSelectorOnMainThread:@selector(beginRefreshing) withObject:nil waitUntilDone:NO];
  
  [[MessagesManager sharedInstance] setLocationForMessageGenerationWithCompletion:^(NSError *error) {
    if (!error) {
      if (error.code == 500 && [error.domain isEqualToString:@"LocationAuthorization"]) {
        [self reloadData];
      }
      
      MessagesManager *messagesManager = [MessagesManager sharedInstance];

      messages = [messagesManager generateMessages:20];
      
      NSLog(@"messages: %@", messages);
      
      [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
      [self.refreshControl performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    }
  }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  // Pass the selected object to the compose view controller.
  if ([segue.identifier isEqualToString:@"composingSheet"]) {
    ComposeSheetViewController *composeSheetViewController = (ComposeSheetViewController*)[segue destinationViewController];
    composeSheetViewController.selectedMessage = (DMessage*)sender;
  }
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
