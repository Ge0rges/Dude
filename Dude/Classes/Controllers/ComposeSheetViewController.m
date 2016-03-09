//
//  ComposeSheetViewController.m
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import "ComposeSheetViewController.h"

// Managers
#import "MessagesManager.h"

// Constants
#import "Constants.h"

@interface ComposeSheetViewController ()

@property (nonatomic) BOOL *selectedFacebook;
@property (nonatomic) BOOL *selectedTwitter;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation ComposeSheetViewController
#warning make composing sheet, make sure any fully public messages are put in lastSeen of currentUser email

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (section == 0) ? 2 : 6;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  
  // Determine which cell we're loading
  if (indexPath.section == 0) {
    switch (indexPath.row) {
      case 0:
        cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", self.selectedMessage.message, self.selectedMessage.city];
        break;
        
      case 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        break;

    }
  
  } else {
    switch (indexPath.row) {
      case 0:
        cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell"];
        break;
      
      case 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell"];
        break;
      
      case 2:
        cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell"];
        break;
      
      case 3:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        break;
      
      case 4:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        break;
      
      case 5:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        break;
    
    }
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
  // Set transparent background so we can see the layer
  cell.backgroundColor = UIColor.clearColor;
  
  // Declare two layers: one for the background and one for the selecetdBackground
  CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
  CAShapeLayer *selectedBackgroundLayer = [[CAShapeLayer alloc] init];
  
  CGRect bounds = CGRectInset(cell.bounds, 0, 0);//Cell bounds feel free to adjust insets.
  
  BOOL addSeparator = NO;// Controls if we should add a seperator
  
  // Determine which corners should be rounded
  if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // This is the only row in its section, round all corners
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else if (indexPath.row == 0) {
    // First row, round the top two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    addSeparator = YES;
    
  } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // Bottom row, round the bottom two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else {
    // Somewhere between the first and last row don't round anything but add a seperator
    backgroundLayer.path = [UIBezierPath bezierPathWithRect:bounds].CGPath;// So we have a background
    addSeparator = YES;
  }
  
  // Copy the same path for the selected background layer
  selectedBackgroundLayer.path = CGPathCreateCopy(backgroundLayer.path);
  
  // Yay colors!
  backgroundLayer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
  selectedBackgroundLayer.fillColor = [UIColor grayColor].CGColor;
  
  // Draw seperator if necessary
  if (addSeparator == YES) {
    CALayer *separatorLayer = [CALayer layer];
    CGFloat separatorHeight = (1.f / [UIScreen mainScreen].scale);
  
    separatorLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-separatorHeight, bounds.size.width-10, separatorHeight);
    separatorLayer.backgroundColor = tableView.separatorColor.CGColor;
    
    [backgroundLayer addSublayer:separatorLayer];
  }
  

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

#pragma - Sending
- (void)send {
  MessagesManager *messagesManager = [MessagesManager sharedInstance];
  
  for (DUser *user in self.selectedUsers) {
    [messagesManager sendMessage:self.selectedMessage toContact:user withCompletion:nil];
  }
  
  if (self.selectedTwitter) {
    [messagesManager tweetMessage:self.selectedMessage withCompletion:nil];
  }
  
  if (self.selectedFacebook) {
    [messagesManager postMessage:self.selectedMessage withCompletion:nil];
  }
  
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
