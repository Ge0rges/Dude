//
//  ComposeSheetViewController.m
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import "ComposeSheetViewController.h"

// Frameworks
#import <MessageUI/MessageUI.h>

// Managers
#import "MessagesManager.h"
#import "ContactsManager.h"

// Extensions & Categories
#import "UIImageExtensions.h"

// Controllers
#import "UsersSelectionTableViewController.h"

// Constants
#import "Constants.h"

@interface ComposeSheetViewController () <MFMessageComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) UISwitch *shareLocationSwitch;
@property (strong, nonatomic) UISwitch *shareDudeSwitch;
@property (strong, nonatomic) UISwitch *shareTwitterSwitch;
@property (strong, nonatomic) UISwitch *shareFacebookSwitch;
@property (strong, nonatomic) UISwitch *shareByMessageSwitch;

@end

@implementation ComposeSheetViewController

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
        cell.imageView.image = [[UIImage imageNamed:@"Location"] scaleImageToSize:CGSizeMake(50, 50)];
        break;
        
      case 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        cell.textLabel.text = (self.selectedMessage.type == DMessageTypeLocation) ? @"Your Location will be Shared": @"Share exact location?";
        
        self.shareLocationSwitch = [cell viewWithTag:3];
        
        self.shareLocationSwitch.on = (self.selectedMessage.type == DMessageTypeLocation);
        self.shareLocationSwitch.enabled = !(self.selectedMessage.type == DMessageTypeLocation);
        
        break;

    }
  
  } else {
    switch (indexPath.row) {
      case 0:
        cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell"];
        break;
      
      case 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell"];
        cell.textLabel.text = @"Send to Dudes";
        cell.imageView.image = [[UIImage imageNamed:@"Tab Person"] scaleImageToSize:CGSizeMake(50, 50)];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i %@", (int)self.selectedUsers.count, (self.selectedUsers.count != 1) ? @"Friends" : @"Friend"];

        break;
        
      case 2:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        
        cell.textLabel.text = @"Send via Messages";
        cell.imageView.image = [[UIImage imageNamed:@"Messages Bubble"] scaleImageToSize:CGSizeMake(50, 50)];
        cell.detailTextLabel.text = @"";
        
        self.shareByMessageSwitch = [cell viewWithTag:3];
        self.shareByMessageSwitch.enabled = !(self.selectedMessage.type == DMessageTypeLocation);

        break;
      
      case 3:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        cell.textLabel.text = @"Share on Dude";
        cell.imageView.image = [[UIImage imageNamed:@"Pin"] scaleImageToSize:CGSizeMake(50, 50)];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.shareDudeSwitch = [cell viewWithTag:3];

        break;
      
      case 4:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        cell.textLabel.text = @"Tweet to Twitter";
        cell.imageView.image = [[UIImage imageNamed:@"Twitter"] scaleImageToSize:CGSizeMake(50, 50)];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.shareTwitterSwitch = [cell viewWithTag:3];
        self.shareTwitterSwitch.enabled = (BOOL)([[NSUserDefaults standardUserDefaults] stringForKey:@"twitterAccountID"]);
        
        break;
      
      case 5:
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        cell.textLabel.text = @"Post to Facebook";
        cell.imageView.image = [[UIImage imageNamed:@"Facebook"] scaleImageToSize:CGSizeMake(50, 50)];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.shareFacebookSwitch = [cell viewWithTag:3];
        self.shareFacebookSwitch.enabled = (BOOL)([[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccountID"]);

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
  
    if ([cell.reuseIdentifier isEqualToString:@"titleCell"]) {
      separatorLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-separatorHeight, bounds.size.width-20, separatorHeight);
      
    } else {
      separatorLayer.frame = CGRectMake(CGRectGetMinX(bounds)+50, bounds.size.height-separatorHeight, bounds.size.width-70, separatorHeight);
    }
    
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions
- (IBAction)send {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    // Set the messages send date
    self.selectedMessage.sendDate = [NSDate date];
    
    // Send the message where needed
    MessagesManager *messagesManager = [MessagesManager sharedInstance];
    
    self.selectedMessage.includeLocation = self.shareLocationSwitch.on;// Set wether the message should attach user's coordinates
    
    // Public sharing
    if (self.shareDudeSwitch.on) {
      self.selectedUsers = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:NO favourites:NO];
      
      // Update the our lastSeen in our own user.
      NSMutableArray *mutableReceiverLastSeens = [[NSMutableArray alloc] initWithArray:[DUser currentUser].lastSeens];
      
      [[DUser currentUser].lastSeens enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *lastSeen = (NSDictionary*)obj;
        
        if (lastSeen[[DUser currentUser].email]) {
          stop = (BOOL *)YES;// Wtf apple
          lastSeen = @{[DUser currentUser].email: [NSKeyedArchiver archivedDataWithRootObject:self.selectedMessage]};
          
          [mutableReceiverLastSeens removeObjectAtIndex:idx];
          [mutableReceiverLastSeens insertObject:lastSeen atIndex:0];
          
          [DUser currentUser].lastSeens = mutableReceiverLastSeens;
          [[DUser currentUser] saveEventually];
        }
      }];
      
    }
    
    // Send message to selected recipients
    for (DUser *user in self.selectedUsers) {
      [messagesManager sendMessage:self.selectedMessage toContact:user withCompletion:nil];
    }
    
    // Share on twitter
    if (self.shareTwitterSwitch.on) {
      [messagesManager tweetMessage:self.selectedMessage withCompletion:nil];
    }
    
    // Share on Facebook
    if (self.shareFacebookSwitch.on && (!self.selectedMessage.includeLocation && self.selectedMessage.type != DMessageTypeLocation)) {
      [messagesManager postMessage:self.selectedMessage withCompletion:nil];
    }
    
    // Share via iMessage
    if (self.shareByMessageSwitch.on) {
      [self sendViaMessages];
      
    }
  });
  

  if (!self.shareByMessageSwitch.on) {
    [self dismissViewControllerAnimated:YES completion:nil];// Only dismiss if user didn't select the message sheet
  }
}

- (void)sendViaMessages {
  MFMessageComposeViewController *composeVC = [[MFMessageComposeViewController alloc] init];
  composeVC.messageComposeDelegate = self;
  
  // Configure the fields of the interface.
  composeVC.body = self.selectedMessage.message;
  
  // Present the view controller modally.
  [self presentViewController:composeVC animated:YES completion:nil];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"selectFriendsSegue"]) {
    UsersSelectionTableViewController *usersSelectionTableVC = [segue destinationViewController];
    usersSelectionTableVC.composeSheetViewController = self;
  }
}

-(IBAction)unwindToComposeSheetViewController:(UIStoryboardSegue *)segue {
  // Reload the friend selection row
  [self.tableView beginUpdates];
  [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
  [self.tableView endUpdates];
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
  // Dismiss the message compose view controller.
  [controller.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
