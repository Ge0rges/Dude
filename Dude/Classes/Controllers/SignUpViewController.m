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
#warning replace this timer with appropriate callings
  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkConfirmButton) userInfo:nil repeats:YES];
  
  // Simulate a first press for initial setup
  [self confirmed:self.confirmButton];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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
        
        [self proceedToPassword];
        break;
      }
        
      case 2: {
        user.password = self.textField.text;
        DUser *loggedInUser = [DUser logInWithUsername:user.username password:user.password];
        if (!loggedInUser) {
          [self dismissViewControllerAnimated:YES completion:nil];
          
        } else {
          // Go back to the redirection controller
          [self dismissViewControllerAnimated:YES completion:^{
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
          }];
        }
        break;
      }
        
      default: {
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
        [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToEmail];
        break;
      }
        
      case 2: {
        if (![self isValidEmailWithAlert:YES]) return;
        
        user.email = self.textField.text.lowercaseString;
        user.username = self.textField.text.lowercaseString;
        
        [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToPassword];
        break;
      }
        
      case 3: {
        user.password = self.textField.text;
        
        [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToPhoto];
        break;
      }
        
      case 4: {
        [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToSocial];
        break;
      }
        
      case 5: {
        [user selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
          [user selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
            [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
              if (!succeeded) {
                [self dismissViewControllerAnimated:YES completion:nil];
                
              } else {
                // Go back to the redirection controller
                [self dismissViewControllerAnimated:YES completion:^{
                  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                }];
              }
            }];
          }];
        }];
      }
        
      default: {
        break;
      }
    }
  }
}

- (void)proceedToName {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Name Tag"]];
  [self.stepLabel setText:@"Your name will be shown to others along with your profile photo"];
  [self.titleStepLabel setText:@"Your Name"];
  
  [self.textField setPlaceholder:@"The Duderino"];
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField setKeyboardType:UIKeyboardTypeDefault];
  [self.textField setSecureTextEntry:NO];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Back" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.35];//.05 seconds after animation
}

- (void)proceedToPassword {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Password"]];
  [self.stepLabel setText:@"Choose a super secret password. (Pssst, don't share it)"];
  [self.titleStepLabel setText:@"Password"];
  
  [self.textField setPlaceholder:@"At least six characters, security!"];
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField setKeyboardType:UIKeyboardTypeDefault];
  [self.textField setSecureTextEntry:YES];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Email" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.textField becomeFirstResponder];
}

- (void)proceedToSocial {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"CoumpoundSocial"]];
  [self.stepLabel setText:@"We only use your Twitter and Facebook account when you use them to post messages."];
  [self.titleStepLabel setText:@"Accounts"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"ALLOW ACCESS" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Photo" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField resignFirstResponder];
}

- (void)proceedToEmail {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Mail"]];
  [self.stepLabel setText:@"We never share your email address, and we only contact you about your account."];
  [self.titleStepLabel setText:@"Email Address"];
  
  [self.textField setPlaceholder:@"thedude@is.awesome"];
  [self.textField setText:@""];
  [self.textField setHidden:NO];
  [self.textField setKeyboardType:UIKeyboardTypeEmailAddress];
  [self.textField setSecureTextEntry:NO];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Name" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField becomeFirstResponder];
  
}

- (void)proceedToPhoto {
  // Prepare for animation
  [self screenshot];
  
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Add Photo"]];
  [self.stepLabel setText:@"Your profile photo will be visible other users. Smile!"];
  [self.titleStepLabel setText:@"Profile Photo"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Password" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPicture)];
  [self.stepImageView addGestureRecognizer:tapGestureRecognizer];
  
  [self.textField resignFirstResponder];
}

#pragma mark - Animation
- (UIImage *)screenshot {
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

- (void)animateToNextStepWithInitialScreenshot:(UIImage*)screenshot fromRight:(BOOL)fromRight {
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
- (void)checkConfirmButton {
  switch (self.confirmButton.tag) {
    case 1: {
      self.confirmButton.enabled = (self.textField.text.length > 0);
      break;
    }
      
    case 2: {
      self.confirmButton.enabled = [self isValidEmailWithAlert:NO];
      break;
    }
      
    case 3: {
      self.confirmButton.enabled = (self.textField.text.length > 5);
      break;
    }
      
    case 4: {
      self.confirmButton.enabled = (selectedImageFile);
      
      break;
    }
      
    case 5: {
      self.confirmButton.enabled = YES;
      break;
    }
      
    default: {
      break;
    }
  }
  
  self.confirmButton.backgroundColor = (self.confirmButton.enabled) ? self.confirmButton.tintColor : [UIColor lightGrayColor];
}

- (IBAction)back {
  switch (self.confirmButton.tag) {
    case 1: {
      [self performSegueWithIdentifier:@"backToWelcomeSegue" sender:nil];
      break;
    }
      
    case 2: {
      [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToName];
      break;
    }
      
    case 3: {
      [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToEmail];
      break;
    }
      
    case 4: {
      [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToPassword];
      
      break;
    }
      
    case 5: {
      [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToPhoto];
      break;
    }
      
    case 6: {
      [self animateToNextStepWithInitialScreenshot:[self screenshot] fromRight:NO];
      [self proceedToSocial];
      break;
    }
      
    default: {
      break;
    }
  }
  
  self.confirmButton.tag--;// One to compensate for the ++ the proceed command does
  self.confirmButton.tag--;// One to actually go back
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  UIImagePickerController *picker = [UIImagePickerController new];
  picker.delegate = self;
  picker.allowsEditing = YES;
  
  switch (buttonIndex) {
    case 0:
      picker.sourceType = UIImagePickerControllerSourceTypeCamera;
      [self presentViewController:picker animated:YES completion:nil];
      break;
      
    case 1:
      picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      [self presentViewController:picker animated:YES completion:nil];
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
  [picker dismissViewControllerAnimated:YES completion:nil];
  
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

- (BOOL)isValidEmailWithAlert:(BOOL)showAlert {
  BOOL validEmail = [self validateEmailWithRFC:self.textField.text];
  
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