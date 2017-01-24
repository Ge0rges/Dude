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

// Frameworks
#import <Accounts/Accounts.h>

// Pods
#import <Parse/Parse.h>

// Models
#import "DUser.h"

// Extensions & Categories
#import "UIImageExtensions.h"

// Utils
#import "Constants.h"


@interface SignUpViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
  
  PFQuery *emailTakenQuery;
  
  PFFile *selectedImageFile;
  
  DUser *user;
  
  UIImageView *retakeImageView;
  
  BOOL loggingIn;
}

@property (strong, nonatomic) IBOutlet UILabel *stepLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleStepLabel;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) IBOutlet UIImageView *stepImageView;

@property (strong, nonatomic) IBOutlet UIButton *confirmButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Alloc & Init the temp user
  user = [DUser object];
  
  // Start a timer to check if the button should be enabled
  [self.textField addTarget:self action:@selector(checkConfirmButton) forControlEvents:UIControlEventEditingChanged];

  // Simulate a first press for initial setup
  [self confirmed:self.confirmButton];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
}

#pragma mark - Steps
- (IBAction)confirmed:(UIButton*)sender {
  if (self.logIn) {
    switch (self.confirmButton.tag) {
      case 0: {
        [self proceedToEmail];
        break;
      }
        
      case 1: {
        user.email = self.textField.text.lowercaseString;
        user.username = self.textField.text.lowercaseString;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToPassword];
        
        break;
      }
        
      case 2: {
        user.password = self.textField.text;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToSocial];
        
        break;
      }
      
      case 3: {
        loggingIn = YES;
        self.confirmButton.enabled = NO;
        
        [DUser logInWithUsernameInBackground:user.username password:user.password block:^(PFUser * _Nullable loggedInUser, NSError * _Nullable error) {
          if (!loggedInUser || error) {
            UIAlertController *incorrectCredentialsAlertController = [UIAlertController alertControllerWithTitle:@"Dude, who are you!?" message:@"Your credentials don't match anyone we know! Check for typos and try again." preferredStyle:UIAlertControllerStyleAlert];
            [incorrectCredentialsAlertController addAction:[UIAlertAction actionWithTitle:@"Will do!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
              
              // Back 2 steps
              [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
              [self proceedToEmail];
              
              self.confirmButton.tag -=3;
              
            }]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
              [self presentViewController:incorrectCredentialsAlertController animated:YES completion:nil];
              self.confirmButton.enabled = YES;
              loggingIn = NO;
            });
            
          } else if (loggedInUser.isAuthenticated && loggedInUser.sessionToken) {
            // Update this installation's user
            [[PFInstallation currentInstallation] setObject:[DUser currentUser] forKey:@"user"];
            [[PFInstallation currentInstallation] save];
            
            // Go back to the redirection controller
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            });
          }
        }];
        
        break;
      }
    }
    
  } else {
    switch (self.confirmButton.tag) {
      case 0: {
        [self proceedToName];
        break;
      }
        
      case 1: {
        user.fullName = self.textField.text;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToEmail];
        break;
      }
        
      case 2: {        
        user.email = self.textField.text.lowercaseString;
        user.username = self.textField.text.lowercaseString;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToPassword];
        break;
      }
        
      case 3: {
        user.password = self.textField.text;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToPhoto];
        break;
      }
        
      case 4: {
        // Remove retake X image
        [retakeImageView removeFromSuperview];
        retakeImageView = nil;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToSocial];
        break;
      }
        
      case 5: {
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
          if (!succeeded) {
            UIAlertController *incorrectCredentialsAlertController = [UIAlertController alertControllerWithTitle:@"Dude, we couldn't sign you up" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [incorrectCredentialsAlertController addAction:[UIAlertAction actionWithTitle:@"I'll try again :(" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
              // Go back to the beginning
              [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
              [self proceedToName];
              
              self.confirmButton.tag -=5;
            }]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
              [self presentViewController:incorrectCredentialsAlertController animated:YES completion:nil];
            });

            
          } else {
            // Tell the user to confirm his email
            UIAlertController *confirmEmailAlertController = [UIAlertController alertControllerWithTitle:@"Dude, confirm your email" message:@"We've sent you an email to verify your you. Confirm it to log in." preferredStyle:UIAlertControllerStyleAlert];
            
            [confirmEmailAlertController addAction:[UIAlertAction actionWithTitle:@"Will do!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
              // Go back to the redirection controller
              [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
              [self presentViewController:confirmEmailAlertController animated:YES completion:nil];
            });
            
            [user selectFacebookAccountWithCompletion:nil];
            [user selectTwitterAccountWithCompletion:nil];
            
            // Update this installation's user
            [[PFInstallation currentInstallation] setObject:[DUser currentUser] forKey:@"user"];
            [[PFInstallation currentInstallation] save];
          }
          
        }];
      }
    }
  }
  
  // Initial check for next step
  [self checkConfirmButton];
}

- (void)proceedToName {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Name Tag"]];
  [self.stepLabel setText:@"Your name will be shown to others along with your profile photo"];
  [self.titleStepLabel setText:@"Your Name"];
  
  [self.textField setPlaceholder:@"The Duderino"];
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField resignFirstResponder];
  [self.textField setKeyboardType:UIKeyboardTypeDefault];
  [self.textField setSecureTextEntry:NO];
  [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Back" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  if (self.stepImageView.gestureRecognizers.count > 0) {
    [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  }
  
  [self.textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];//.15 seconds after animation
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
}

- (void)proceedToPassword {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Password"]];
  [self.titleStepLabel setText:@"Password"];
  
  if (self.logIn) {
    [self.stepLabel setText:@"Enter your super secret password. (Make sure nobody's looking!)"];
    [self.textField setPlaceholder:@"Yay! Security!"];

  } else {
    [self.stepLabel setText:@"Choose a super secret password. (Pssst, don't share it)"];
    [self.textField setPlaceholder:@"Min. 6 characters, security!"];
  }
  
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField resignFirstResponder];
  [self.textField setKeyboardType:UIKeyboardTypeDefault];
  [self.textField setSecureTextEntry:YES];
  [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];

  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Email" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];//.15 seconds after animation
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
}

- (void)proceedToSocial {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Coumpound Social"]];
  [self.stepLabel setText:@"We only use your Twitter and Facebook account when you use them to post messages."];
  [self.titleStepLabel setText:@"Accounts"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"ASK ME" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Photo" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField resignFirstResponder];
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
}

- (void)proceedToEmail {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Mail"]];
  [self.titleStepLabel setText:@"Email Address"];
  
  if (self.logIn) {
    [self.stepLabel setText:@"Enter the email you used to sign up."];
    [self.textField setPlaceholder:@"thedude@is.awesome"];
    
  } else {
    [self.stepLabel setText:@"Your email is private! We'll only contact you about your account."];
    [self.textField setPlaceholder:@"thedude@is.awesome"];
  }
  
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField resignFirstResponder];
  [self.textField setKeyboardType:UIKeyboardTypeEmailAddress];
  [self.textField setSecureTextEntry:NO];
  [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];

  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Name" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];//.15 seconds after animation
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
}

- (void)proceedToPhoto {
  // Prepare for animation
  [self screenshot];
  
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Add Photo"]];
  [self.stepLabel setText:@"Your profile photo will be visible to other users. Smile!"];
  [self.titleStepLabel setText:@"Profile Photo"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Password" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPicture)];
  [self.stepImageView addGestureRecognizer:tapGestureRecognizer];
  
  [self.textField resignFirstResponder];
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
  
  selectedImageFile = nil;
}

#pragma mark - Animation
- (UIImage*)screenshot {
  CGSize imageSize = CGSizeZero;
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    imageSize = [UIScreen mainScreen].bounds.size;
    
  } else {
    imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
  }
  
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, window.center.x, window.center.y);
    CGContextConcatCTM(context, window.transform);
    CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
  
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
      CGContextRotateCTM(context, M_PI_2);
      CGContextTranslateCTM(context, 0, -imageSize.width);
    
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
      CGContextRotateCTM(context, -M_PI_2);
      CGContextTranslateCTM(context, -imageSize.height, 0);
    
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
      CGContextRotateCTM(context, M_PI);
      CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
    }
    
    if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
      [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
    
    } else {
      [window.layer renderInContext:context];
    }
    
    CGContextRestoreGState(context);
  }
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

- (void)animateToStepWithInitialScreenshot:(UIImage*)screenshot fromRight:(BOOL)fromRight {
  if (fromRight) {
    __block UIImageView *sourceImageView = [[UIImageView alloc] initWithImage:screenshot];
    __block UIView *destinationView = self.view;
    
    // Prepare the views locations
    [self.view.superview addSubview:sourceImageView];
    [self.view.superview bringSubviewToFront:sourceImageView];
    
    sourceImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    destinationView.transform = CGAffineTransformMakeTranslation(sourceImageView.frame.size.width, 0);

    // Prepare the source controller
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
      destinationView.transform = CGAffineTransformMakeTranslation(0, 0);
      sourceImageView.transform = CGAffineTransformMakeTranslation(-sourceImageView.frame.size.width, 0);
      
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      sourceImageView = nil;
    }];
    
  } else {
    __block UIImageView *sourceImageView = [[UIImageView alloc] initWithImage:screenshot];
    __block UIView *destinationView = self.view;
    
    // Prepare the views locations
    [self.view.superview addSubview:sourceImageView];
    [self.view.superview bringSubviewToFront:sourceImageView];
    
    sourceImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    destinationView.transform = CGAffineTransformMakeTranslation(-sourceImageView.frame.size.width, 0);
    
    // Prepare the source controller
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
      destinationView.transform = CGAffineTransformMakeTranslation(0, 0);
      sourceImageView.transform = CGAffineTransformMakeTranslation(sourceImageView.frame.size.width, 0);
      
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      sourceImageView = nil;
    }];
  }
}

#pragma mark - Other
- (BOOL)textFieldShouldReturn:(UITextField*)textField {
  if (self.confirmButton.enabled) {
    [self confirmed:self.confirmButton];
  }
  
  return self.confirmButton.enabled;
}


- (void)checkConfirmButton {
  switch (self.confirmButton.tag) {
    case 1: {
      self.confirmButton.enabled = (self.logIn) ? [self isValidEmailWithAlert:NO] : (self.textField.text.length > 0);
      break;
    }
      
    case 2: {
      if (self.logIn) {
        self.confirmButton.enabled = (self.textField.text.length > 5);
      
      } else {
        NSBlockOperation *validateEmailOperation = [NSBlockOperation blockOperationWithBlock:^{
          BOOL isValid = [self isValidEmailWithAlert:YES];
          dispatch_async(dispatch_get_main_queue(), ^{
            self.confirmButton.enabled = isValid;
          });
        }];
        
        validateEmailOperation.qualityOfService = NSOperationQualityOfServiceUserInteractive;
        validateEmailOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        
        validateEmailOperation.completionBlock = ^{
          dispatch_async(dispatch_get_main_queue(), ^{
            self.confirmButton.backgroundColor = (self.confirmButton.enabled) ? self.confirmButton.tintColor : [UIColor lightGrayColor];
          });
        };
        
        [[[NSThread alloc] initWithTarget:validateEmailOperation selector:@selector(start) object:nil] start];
        
      }
      
      break;
    }
      
    case 3: {
      self.confirmButton.enabled = (self.logIn) ? !loggingIn : (self.textField.text.length > 5);
      break;
    }
      
    case 4: {
      self.confirmButton.enabled = (selectedImageFile) ? YES : NO;
      
      break;
    }
      
    case 5: {
      self.confirmButton.enabled = YES;
      break;
    }
  }
  
  if (!self.logIn && self.confirmButton.tag == 2) {// Check if we are on the email step for sign up
    // If so disable the button. real results are being generated asyncly and will be set later
    self.confirmButton.enabled = NO;
    self.confirmButton.backgroundColor = [UIColor lightGrayColor];
  
  } else {
    // Otherwise usual color setting according to enabled state.
    self.confirmButton.backgroundColor = (self.confirmButton.enabled) ? self.confirmButton.tintColor : [UIColor lightGrayColor];
  }
}

- (IBAction)back {
  switch (self.confirmButton.tag) {
    case 1: {
      [self.textField resignFirstResponder];
      [self performSegueWithIdentifier:@"unwindToWelcomeViewController" sender:self];
      
      break;
    }
      
    case 2: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      if (self.logIn) {
        [self proceedToEmail];
     
      } else {
        [self proceedToName];
      }
      
      break;
    }
      
    case 3: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      if (self.logIn) {
        [self proceedToPassword];
        
      } else {
        [self proceedToEmail];
      }
      
      break;
    }
      
    case 4: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToPassword];
      
      break;
    }
      
    case 5: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToPhoto];
      
      break;
    }
      
    case 6: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToSocial];
      
      break;
    }
  }
  
  self.confirmButton.tag -= 2;// One to compensate for the ++ the proceed command does and one to actually go back
}

#pragma mark - UIImagePickerController
- (void)selectPicture {
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Now, choose a profile picture from" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
    
  }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
    
  }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  
  [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [picker dismissViewControllerAnimated:YES completion:^{
    [self checkConfirmButton];
  }];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
  [picker dismissViewControllerAnimated:YES completion:nil];
  
  UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
  UIImage *thumbnailImage = [selectedImage imageByScalingAndCroppingForSize:CGSizeMake(200, 200)];
  
  // Set user image file
  selectedImageFile = [PFFile fileWithData:UIImageJPEGRepresentation(thumbnailImage, 1)];
  
  if (selectedImageFile) {
    user.profileImage = selectedImageFile;
    [self.stepImageView setImage:thumbnailImage];
    
    // Add retake X
    retakeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Photo Retake"]];
    retakeImageView.frame = CGRectMake(self.stepImageView.frame.origin.x+40, self.stepImageView.frame.origin.y+5, 30, 30);
    retakeImageView.userInteractionEnabled = YES;
    
    [self.view addSubview:retakeImageView];
    
    self.stepImageView.layer.cornerRadius = 100;
    self.stepImageView.clipsToBounds = YES;
    
  } else {
    [self selectPicture];
  }
  
  // For the image
  [self checkConfirmButton];
}

#pragma mark - UITextField

- (BOOL)isValidEmailWithAlert:(BOOL)showAlert {
  BOOL validEmail = [self validateEmailWithRFC:self.textField.text];
  
  BOOL taken = NO;
  
  if (validEmail && !self.logIn) {// We rent in log in so check the taken status of the email
    [emailTakenQuery cancel];
    emailTakenQuery = nil;
    
    emailTakenQuery = [DUser query];
    [emailTakenQuery whereKey:@"email" equalTo:self.textField.text.lowercaseString];
    
    taken = ([emailTakenQuery countObjects] > 0 );
  }
  
  if ((!validEmail || taken) && showAlert) {
    NSString *title = (taken) ? @"Email Taken" : @"Email Invalid";
    NSString *message = (taken) ? @"This email is already associated with an account." : @"This email appears to be invalid, please check for typos.";
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:ac animated:YES completion:nil];
    
    return NO;
  }
  
  return (validEmail && !taken);
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
