//
//  ComposeSheetViewController.m
//  Dude
//
//  Created by Georges Kanaan on 27/12/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import "ComposeSheetViewController.h"

@interface ComposeSheetViewController ()

@end

@implementation ComposeSheetViewController
#warning make composing sheet, make sure any fully public messages are put in lastSeen under currentUser email

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

/*- (void)send {
 [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
 MessagesManager *messagesManager = [MessagesManager sharedInstance];
 
 UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
 
 MessageCompletionBlock block = ^(BOOL success, NSError *error) {
 [cell.textLabel setText:(success) ? @"Sent" : @"Error"];
 };
 
 for (DUser *user in self.selectedUsers) {
 [messagesManager sendMessage:messages[indexPath.row] toContact:user withCompletion:block];
 }
 
 if (self.selectedTwitter) {
 [messagesManager tweetMessage:messages[indexPath.row] withCompletion:block];
 }
 
 if (self.selectedFacebook) {
 [messagesManager postMessage:messages[indexPath.row] withCompletion:block];
 }
 
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [cell.textLabel setText:messages[indexPath.row]];
 });
 }*/

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
