//
//  SignUpViewController.m
//  Dude
//
//  Created by Georges Kanaan on 6/5/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "SignUpViewController.h"

// Classes
#import "AppDelegate.h"

// Utils
#import "Constants.h"


@interface SignUpViewController () <UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
  PFFile *selectedImageFile;
  DUser *user;
  
  __block NSString *logInEmail;
  __block NSString *logInPassword;
}

@property (nonatomic) BOOL logIn;

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) IBOutlet UIButton *deniedButton;
@property (strong, nonatomic) IBOutlet UIButton *acceptedButton;
@property (strong, nonatomic) IBOutlet UIButton *confirmButton;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Alloc & Init the temp user
  user = [DUser object];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
}

#pragma mark - IBActions
- (IBAction)deniedAccess:(UIButton*)sender {
  // Show a funny alert
  NSString *message = @"Your name is so people can recognize you. Email so we can identify you and people can find you, it is kept private. Profile Picture so we can share your smile.";
  UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"We keep it private!" message:message preferredStyle:UIAlertControllerStyleAlert];
  
  [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
  
  [self presentViewController:ac animated:YES completion:NULL];
}

- (IBAction)acceptedAccess:(UIButton*)sender {
  // Show textField and confirm button and hide the YES and NO
  [UIView animateWithDuration:0.3 animations:^{
    [self.acceptedButton setAlpha:0.0];
    [self.deniedButton setAlpha:0.0];
    
    [self.textField setAlpha:1.0];
    
    self.confirmButton.tag++;
    
    [self.statusLabel setText:@"OK, first type in your full name."];
    
    [self.confirmButton setTitle:@"Next" forState:UIControlStateNormal];
    
  } completion:^(BOOL finished) {
    [self.textField becomeFirstResponder];
    
    [self.acceptedButton setHidden:YES];
    [self.deniedButton setHidden:YES];
  }];
}

- (IBAction)confirmed:(UIButton*)sender {
  if ((([self.textField.text isEqualToString:@""] || [self.textField.text isEqualToString:@" "] || self.textField.text == nil) && self.confirmButton.tag != -1) && self.confirmButton.tag < 4) return;
  
  switch (self.confirmButton.tag) {
    case -1: {
      self.logIn = YES;
      
      [UIView animateWithDuration:0.3 animations:^{
        [self.acceptedButton setAlpha:0.0];
        [self.deniedButton setAlpha:0.0];
        
        [self.confirmButton setTitle:@"Next" forState:UIControlStateNormal];
        
        [self.textField setAlpha:1.0];
        
        [self.statusLabel setText:@"OK, first type in your email."];
        
      } completion:^(BOOL finished) {
        [self.textField becomeFirstResponder];
        
        [self.acceptedButton setHidden:YES];
        [self.deniedButton setHidden:YES];
      }];
      
      [self.statusLabel setText:@"First, enter your email."];
      [self.textField setPlaceholder:@"thedude@getdudeapp.com"];
      
      [self.textField resignFirstResponder];
      [self.textField setKeyboardType:UIKeyboardTypeEmailAddress];
      [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
      [self.textField becomeFirstResponder];
      
      break;
    }
      
    case 0: {
      if (self.logIn) {
        if ([self validateEmailWithAlert:YES]) {
          logInEmail = [self.textField.text.lowercaseString copy];
          
          [self.textField setPlaceholder:@"Password"];
          [self.statusLabel setText:@"Pick super secret password (>6 characters)."];
          
          [self.textField resignFirstResponder];
          [self.textField setKeyboardType:UIKeyboardTypeDefault];
          [self.textField setSecureTextEntry:YES];
          [self.textField becomeFirstResponder];
          
        } else {
          self.textField.text = @"";
          
          return;// We are still on the same step
        }
        
      } else {
        [user setFullName:self.textField.text];
        
        [self.statusLabel setText:@"Next, enter your email."];
        [self.textField setPlaceholder:@"thedude@getdudeapp.com"];
        
        [self.textField resignFirstResponder];
        [self.textField setKeyboardType:UIKeyboardTypeEmailAddress];
        [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [self.textField becomeFirstResponder];
      }
      
      break;
    }
      
    case 1: {
      if (self.logIn) {
        if (self.textField.text.length >= 6) {
          logInPassword = [self.textField.text copy];
          
          [self.statusLabel setText:@"Which social accounts do you use?"];
          [self.textField setPlaceholder:@"Twitter or Facebook? Both!"];
          
          [self.textField resignFirstResponder];
          
          [user selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
            [user selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
              [self.statusLabel setText:@"We're done! Saving your data..."];
              [self.textField setPlaceholder:@"FINALLY!"];
              
              [DUser logInWithUsernameInBackground:logInEmail password:logInPassword block:^(PFUser *__nullable __strong loggedInUser, NSError *__nullable __strong error) {
                if (error) {
                  UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Could not Log In" message:@"Dude, the password or email you entered is incorrect or non associated with an account." preferredStyle:UIAlertControllerStyleAlert];
                  [ac addAction:[UIAlertAction actionWithTitle:@"OK"style:UIAlertActionStyleDefault handler:NULL]];
                  
                  [self presentViewController:ac animated:YES completion:NULL];
                  
                  // Reset the log in process
                  self.confirmButton.tag = -1;
                  [self confirmed:self.confirmButton];
                  
                } else if (loggedInUser) {
                  [self dismissViewControllerAnimated:YES completion:NULL];
                }
              }];
            }];
          }];
          
        } else {
          UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Password too short" message:@"Your password must consist of at least 6 letters, numbers or special characters." preferredStyle:UIAlertControllerStyleAlert];
          
          [ac addAction:[UIAlertAction actionWithTitle:@"OK"style:UIAlertActionStyleDefault handler:NULL]];
          
          [self presentViewController:ac animated:YES completion:NULL];
          
          self.textField.text = @"";
          
          return;// We are still on the same step
        }
        
      } else {
        if ([self validateEmailWithAlert:YES]) {
          [user setUsername:self.textField.text.lowercaseString];
          [user setEmail:self.textField.text.lowercaseString];
          
          [self.textField setPlaceholder:@"Password"];
          [self.statusLabel setText:@"Pick a 6 characters long super secret password."];
          
          [self.textField resignFirstResponder];
          [self.textField setKeyboardType:UIKeyboardTypeDefault];
          [self.textField setSecureTextEntry:YES];
          [self.textField becomeFirstResponder];
          
        } else {
          self.textField.text = @"";
          
          return;// We are still on the same step
        }
      }
      
      break;
    }
      
    case 2: {
      if (self.textField.text.length >= 6) {
        [self.textField resignFirstResponder];
        
        [user setPassword:self.textField.text.lowercaseString];
        [self.textField setPlaceholder:@"Picture Time!"];
        [self.statusLabel setText:@"Now, choose a profile picture from"];
        
        [self.confirmButton setHidden:YES];
        
        [self selectPicture];
        // We simulate the confirm button when the user selects an image
        
      } else {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Password too short" message:@"Your password must consist of at least 6 letters, numbers or special characters." preferredStyle:UIAlertControllerStyleAlert];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"OK"style:UIAlertActionStyleDefault handler:NULL]];
        
        [self presentViewController:ac animated:YES completion:NULL];
        
        self.textField.text = @"";
        
        return;// We are still on the same step
      }
      
      break;
    }
      
    case 3: {
      [self.statusLabel setText:@"Which social accounts do you use?"];
      [self.textField setPlaceholder:@"Twitter or Facebook? Both!"];
      
      [user selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
        [user selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
          [self.statusLabel setText:@"We're done! Saving your data..."];
          [self.textField setPlaceholder:@"FINALLY!"];
          
          [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
            if (succeeded && !error) {
              [self dismissViewControllerAnimated:YES completion:NULL];
              
            } else {
              NSLog(@"couldnt sign up with error: %@", error);
              [self dismissViewControllerAnimated:NO completion:^{
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Could not Sign Up" message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
                
                [ac addAction:[UIAlertAction actionWithTitle:@"OK"style:UIAlertActionStyleDefault handler:NULL]];
                
                [self presentViewController:ac animated:YES completion:NULL];
              }];
            }
          }];
          
        }];
      }];
      
      break;
    }
      
    default: {
      break;
    }
  }
  
  [self.textField setText:nil];
  self.confirmButton.tag += 1;
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  UIImagePickerController *picker = [UIImagePickerController new];
  picker.delegate = self;
  picker.allowsEditing = YES;
  
  switch (buttonIndex) {
    case 0:
      picker.sourceType = UIImagePickerControllerSourceTypeCamera;
      [self presentViewController:picker animated:YES completion:NULL];
      break;
      
    case 1:
      picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      [self presentViewController:picker animated:YES completion:NULL];
      break;
      
    case 2:
      [self selectPicture];
      break;
      
    default:
      break;
  }
}

#pragma mark - UIImagePickerController
- (void)selectPicture {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Now, choose a profile picture from"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Camera", @"Library", nil];
  [actionSheet showInView:self.view];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [picker dismissViewControllerAnimated:YES completion:^{
    [self selectPicture];
  }];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
  [picker dismissViewControllerAnimated:YES completion:NULL];
  
  UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
  UIImage *thumbnailImage = [selectedImage imageByScalingAndCroppingForSize:CGSizeMake(200, 200)];
  
  // Set user image file
  selectedImageFile = [PFFile fileWithData:UIImageJPEGRepresentation(thumbnailImage, 1)];
  
  if (selectedImageFile) {
    [user setProfileImage:selectedImageFile];
    [self confirmed:self.confirmButton];
    
  } else {
    [self selectPicture];
  }
}

#pragma mark - UITextField
- (BOOL)textFieldShouldReturn:(UITextField*)textField {
  [self confirmed:self.confirmButton];
  
  return YES;
}

- (BOOL)validateEmailWithAlert:(BOOL)showAlert {
  BOOL validEmail = ([self validateEmailWithRFC:self.textField.text] && [self validateEmailFormat:self.textField.text]);
  
  BOOL taken = NO;
  
  if (validEmail && !self.logIn) {
    PFQuery *userQuery = [DUser query];
    [userQuery whereKey:@"email" equalTo:self.textField.text.lowercaseString];
    
    NSArray *usersWithEmail = [userQuery findObjects];
    
    taken = (!usersWithEmail || usersWithEmail.count == 0) ? NO : YES;
  }
  
  if ((!validEmail || taken) && showAlert) {
    NSString *title = (taken) ? @"Email Taken" : @"Email Invalid";
    NSString *message = (taken) ? @"This email is already associated with an account." : @"This email appears to be invalid, please check for typos.";
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:ac animated:YES completion:NULL];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)validateEmailFormat:(NSString*)candidate {
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  
  return [emailTest evaluateWithObject:candidate];
}

// Complete RFC 2822 verification
- (BOOL)validateEmailWithRFC:(NSString*)candidate {
  NSString *emailRegex =
  @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
  @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
  @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
  @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
  @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
  @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
  @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
  
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
  
  return [emailTest evaluateWithObject:candidate];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end