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

// Managers
#import "MessagesManager.h"

// Pods
#import <SDWebImage/UIImageView+WebCache.h>

@interface MessagesTableViewController () {
  NSArray *messages;
}

@end

#warning redo, make sure any fully public messages are put in lastSeen under currentUser email

@implementation MessagesTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.navigationItem.backBarButtonItem setTitle:@"Contacts"];
  [self.navigationItem setTitle:@"Select a Message"];
    
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;

  // Generate Messages
  [self reloadData];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return messages.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
  
  // Get the message
  DMessage *message = (DMessage*)messages[indexPath.row];
  
  // Configure the cell
  [cell.textLabel setText:message.message];
  [cell.imageView sd_setImageWithURL:message.imageURL];
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
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

      [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
      [self.refreshControl performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    }
  }];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
