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

@interface MessagesTableViewController ()

@property (strong, nonatomic) NSArray *messages;

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
  
  // Show refreshing UI & Generate messages
  if (self.messages.count == 0) {
    [self reloadData];

    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height)];
    [self.refreshControl beginRefreshing];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (IBAction)reloadData {
  __weak MessagesManager *messagesManager = [MessagesManager sharedInstance];
  
  if (self.messages.count == 0) {
    // Generate quickly default while others load
    [messagesManager setLocationForMessageGenerationWithCompletion:^(NSError *error) {
      if (!error) {
        self.messages = [messagesManager generateMessages:6];
        
        [self.tableView reloadData];
      }
    }];
  }
  
  [messagesManager setLocationForMessageGenerationWithCompletion:^(NSError *error) {
    if (!error) {
      self.messages = [messagesManager generateMessages:20];
      
      [self.tableView reloadData];
      
      // Keeps its from being jerky
      [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [self.refreshControl endRefreshing];
      }];
      
    } else if (error.code == 500 && [error.domain isEqualToString:@"LocationAuthorization"]) {
      [self reloadData];
      
    } else {
      [DUser showSocialServicesAlert];
      
      [self.refreshControl endRefreshing];
    }
  }];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  return (section == 0) ? @"CHOOSE AN UPDATE TO SEND" : @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return self.messages.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
  
  // Get the message
  DMessage *message = (DMessage*)self.messages[indexPath.section];
  
  // Configure the cell
  [cell.textLabel setText:message.message];
  
  if (indexPath.section > 6) {// Non-Default messages
    [cell.imageView sd_setImageWithURL:message.imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
      [cell.imageView setImage:[image resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
      [cell layoutSubviews];
    }];
    
  } else {// Default messages handle image differently
    NSString *imageName = [message.imageURL.absoluteString stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    imageName = [imageName stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    imageName = [imageName stringByReplacingOccurrencesOfString:@".com" withString:@""];
    
    [cell.imageView setImage:[[UIImage imageNamed:imageName] resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
  // Set transparent background so we can see the layer
  cell.backgroundColor = UIColor.clearColor;
  
  // Declare two layers: one for the background and one for the selecetdBackground
  CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
  CAShapeLayer *selectedBackgroundLayer = [[CAShapeLayer alloc] init];
  
  CGRect bounds = CGRectInset(cell.bounds, 10, -5);//Cell bounds feel free to adjust insets.
  
  // Determine which corners should be rounded
  if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // This is the only row in its section, round all corners
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else if (indexPath.row == 0) {
    // First row, round the top two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // Bottom row, round the bottom two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else {
    // Somewhere between the first and last row don't round anything but add a seperator
    backgroundLayer.path = [UIBezierPath bezierPathWithRect:bounds].CGPath;// So we have a background
  }
  
  // Copy the same path for the selected background layer
  selectedBackgroundLayer.path = CGPathCreateCopy(backgroundLayer.path);
  
  // Yay colors!
  backgroundLayer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
  selectedBackgroundLayer.fillColor = [UIColor grayColor].CGColor;
  
  // Create a UIView from these layers and set them to the cell's .backgroundView and .selectedBackgroundView
  UIView *backgroundView = [[UIView alloc] initWithFrame:bounds];
  [backgroundView.layer insertSublayer:backgroundLayer atIndex:0];
  backgroundView.backgroundColor = UIColor.clearColor;
  cell.backgroundView = backgroundView;
  
  UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:bounds];
  [selectedBackgroundView.layer insertSublayer:selectedBackgroundLayer atIndex:0];
  selectedBackgroundView.backgroundColor = UIColor.clearColor;
  cell.selectedBackgroundView = selectedBackgroundView;
}

#pragma mark - Helpers
- (void)showLocationServicesAlert {
    UIAlertController *locationServicesAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"You must enable location services to be able to send your location and generate meaningfull messages." preferredStyle:UIAlertControllerStyleAlert];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
      [locationServicesAlertController addAction:[UIAlertAction actionWithTitle:@"Open Preferences" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
      }]];
    }
    
    [locationServicesAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
      [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    [appDelegate.visibleViewController presentViewController:locationServicesAlertController animated:YES completion:nil];
  });
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  // Pass the selected object to the compose view controller.
  if ([segue.identifier isEqualToString:@"showComposingSheetSegue"]) {
    UITableViewCell *cell = (UITableViewCell*)sender;
    DMessage *message = self.messages[[self.tableView indexPathForCell:cell].section];
    
    ComposeSheetViewController *composeSheetViewController = (ComposeSheetViewController*)[segue destinationViewController];
    composeSheetViewController.selectedMessage = message;
    composeSheetViewController.selectedUsers = [NSSet setWithArray:self.selectedUsers];
  }
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

- (IBAction)dismissViewController:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
