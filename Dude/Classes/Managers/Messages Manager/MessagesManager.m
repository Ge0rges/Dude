//
//  MessagesManager.m
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "MessagesManager.h"

// Managers
#import "ContactsManager.h"

// Classes
#import "AppDelegate.h"

// Models
#import "DUserWatch.h"

// Frameworks
#import <Social/Social.h>

// Pods
#import <SOMotionDetector/SOMotionDetector.h>

@interface MessagesManager () <CLLocationManagerDelegate, SOMotionDetectorDelegate> {
  LocationCompletionBlock locationCompletionBlock;
  
  BOOL userIsInAutomobile;
  
  NSString *searchedLocation;
}

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation MessagesManager

+ (instancetype)sharedInstance {
  static MessagesManager *sharedMessagesManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMessagesManager = [self new];
  });
  
  return sharedMessagesManager;
}

#pragma mark - Location Handling
- (void)setLocationForMessageGenerationWithCompletion:(_Nonnull LocationCompletionBlock)handler {
  self.locationManager = [CLLocationManager new];
  
  // Set the block for later use and modify to set searchedLocation
  __weak typeof(self) weakSelf = self;
  __weak typeof(searchedLocation) weakSearchedLocation = searchedLocation;
  
  locationCompletionBlock = ^( NSError * _Nullable error){
    // Check if we already fetched the location
    if (!weakSearchedLocation) {
      // Get searchedLocation (current city)
      [[CLGeocoder new] reverseGeocodeLocation:weakSelf.locationManager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count) {
          searchedLocation = ([placemarks.firstObject locality]) ?: ([placemarks.firstObject subLocality]) ?: [placemarks.firstObject administrativeArea];
        }
        
        if (!weakSearchedLocation) {
          [weakSelf fetchNearbyVenues:0 fromOldResponse:nil];
        }
        
        handler(error);
      }];
    } else {
      handler(error);
    }
  };
  
  if (fabs([self.locationManager.location.timestamp timeIntervalSinceNow]) < 600 && self.locationManager.location) {// Check if we have a cached location within 10min
    locationCompletionBlock(nil);
    return;
  }
  
  // Set the location manager
  dispatch_async(dispatch_get_main_queue(), ^{
    // User motion type
    [[SOMotionDetector sharedInstance] setUseM7IfAvailable:YES];
    [[SOMotionDetector sharedInstance] startDetection];
    
    // Location
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeOther;
    self.locationManager.distanceFilter = 10;
    
    // If the location permission is underterminded ask for it
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
      [self.locationManager requestWhenInUseAuthorization];
      locationCompletionBlock([NSError errorWithDomain:@"LocationAuthorization" code:500 userInfo:nil]);
      locationCompletionBlock = nil;
    }
    
    // Otherwise start getting the location or call the block with a 500 not allowed error
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
      locationCompletionBlock([NSError errorWithDomain:@"LocationAuthorization" code:501 userInfo:nil]);
      locationCompletionBlock = nil;
    } else {
      [self.locationManager startUpdatingLocation];
    }
  });
}

#pragma mark CLLocationManager
- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  [self.locationManager requestWhenInUseAuthorization];
  
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
    locationCompletionBlock([NSError errorWithDomain:@"Location" code:500 userInfo:nil]);
    locationCompletionBlock = nil;
  } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
    [self.locationManager startUpdatingLocation];
  }
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
  // Get most recent location
  CLLocation *location = [locations lastObject];
  
  // If it's a relatively recent event, turn off updates to save power.
  NSDate *eventDate = location.timestamp;
  NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
  if (fabs(howRecent) < 15.0) {
    // Stop updating
    [manager stopUpdatingLocation];
    
    // Call the block
    locationCompletionBlock(nil);
    locationCompletionBlock = nil;
  }
}


- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region {
  // Stop monitoring region
  [manager stopMonitoringForRegion:region];
  
  // Get the UID
  NSString *uniqueIdentifier = region.identifier;
  
  // Send the push for the identifier of this region
  NSDictionary *pushDict = [NSDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pushesForGeoFence"]];
  
  // Get push
  PFPush *push = pushDict[uniqueIdentifier];
  [push sendPush:nil];
  
  // Remove the push
  NSMutableDictionary *mutablePushDict = [pushDict mutableCopy];
  [mutablePushDict removeObjectForKey:uniqueIdentifier];
  [[NSUserDefaults standardUserDefaults] setObject:[mutablePushDict copy] forKey:@"pushesForGeoFence"];
}

#pragma mark SOMotionDetector
- (void)motionDetector:(SOMotionDetector*)motionDetector motionTypeChanged:(SOMotionType)motionType {
  if (motionType == MotionTypeAutomotive) userIsInAutomobile = YES;
  [[SOMotionDetector sharedInstance] stopDetection];
}

#pragma mark - Context Messaging building
- (NSArray*)generateMessages:(NSInteger)numberOfMessagesToGenerate {// Someday this will be an API call to our server
  if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied && self.locationManager.location) {
    
    // Array to store messages
    NSMutableArray *messages = [NSMutableArray new];
    
    // Add default messages
    DMessage *messageDude = [[DMessage alloc] initWithCategory:@"Just Dude" location:self.locationManager.location venueName:@"Just Dude" venueCity:searchedLocation imageURL:@"http://Badge_Dude.com"];
    DMessage *messageLink = [[DMessage alloc] initURLMessageWithLocation:self.locationManager.location venueCity:searchedLocation];
    DMessage *messageLocation = [[DMessage alloc] initLocationMessage:self.locationManager.location venueCity:searchedLocation];
    
    if (messageDude) [messages addObject:messageDude];
    if (messageLink) [messages addObject:messageLink];
    if (messageLocation) [messages addObject:messageLocation];
    
    if (userIsInAutomobile) {
      DMessage *messageCar = [[DMessage alloc] initWithCategory:@"Car" location:self.locationManager.location venueName:@"In transit" venueCity:searchedLocation imageURL:@"http://Badge_Car.com"];
      DMessage *messageTrain = [[DMessage alloc] initWithCategory:@"Train" location:self.locationManager.location venueName:@"In transit" venueCity:searchedLocation imageURL:@"http://Badge_Train.com"];
      DMessage *messagePlane = [[DMessage alloc] initWithCategory:@"Plane" location:self.locationManager.location venueName:@"In transit" venueCity:searchedLocation imageURL:@"http://Badge_Plane.com"];
      
      if (messageCar) [messages addObject:messageCar];
      if (messageTrain) [messages addObject:messageTrain];
      if (messagePlane) [messages addObject:messagePlane];
      
    } else {
      DMessage *messageHome = [[DMessage alloc] initWithCategory:@"Home" location:self.locationManager.location venueName:@"Home" venueCity:searchedLocation imageURL:@"http://Badge_Home.com"];
      DMessage *messageWork = [[DMessage alloc] initWithCategory:@"Work" location:self.locationManager.location venueName:@"Work" venueCity:searchedLocation imageURL:@"http://Badge_Work.com"];
      DMessage *messageFriend = [[DMessage alloc] initWithCategory:@"Friend" location:self.locationManager.location venueName:@"a Friend's" venueCity:searchedLocation imageURL:@"http://Badge_Friend.com"];
      
      if (messageHome) [messages addObject:messageHome];
      if (messageWork) [messages addObject:messageWork];
      if (messageFriend) [messages addObject:messageFriend];
    }
    
    // Check if user is in a transport
    if (numberOfMessagesToGenerate-6 > 0 && !userIsInAutomobile) {
      NSArray *venues = [self fetchNearbyVenues:numberOfMessagesToGenerate-6 fromOldResponse:nil];
      
      // Check if there are any venues
      if (venues && venues.count > 0) {
        // Get the message for each venue from the dict.
        for (NSArray *venue in venues) {// For each venue
          DMessage *message = [[DMessage alloc] initWithCategory:venue[1] location:self.locationManager.location venueName:venue[0] venueCity:searchedLocation imageURL:venue[2]];
          
          if (message) [messages addObject:message];
        }
      }
    }
    
    return [NSArray arrayWithArray:messages];
  }
  
  return nil;
}

- (NSArray*)fetchNearbyVenues:(NSInteger)numberOfVenues fromOldResponse:(NSDictionary*)response {
  // Set a default venue count if none is provided
  if (!numberOfVenues || numberOfVenues <= 0) numberOfVenues = 1;
  if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {// If we have permission
    // Only if a response wasn't passed
    if (!response) {
      response = [self queryFoursquareForNearbyVenues:numberOfVenues];
      
      if (!response) return nil;
      if (!searchedLocation) {
        searchedLocation = (response[@"headerLocation"]) ? response[@"headerLocation"] : @"Could not determine City.";
      }
      
      if (numberOfVenues == 0) return nil;// We just wanted the searchedLocation for default messages
    }
    
    // For each venue get the name and category
    NSMutableArray *returnArray = [NSMutableArray new];
    
    // Parse the data
    NSArray *groups = response[@"groups"];
    NSDictionary *nestedGroups = [groups objectAtIndex:0];
    NSArray *items = nestedGroups[@"items"];
    
    for (NSInteger i=0; i<[items count]; i++) {
      // Start parsing until we get the venue
      NSDictionary *outerVenue = [items objectAtIndex:i];
      NSDictionary *venue = outerVenue[@"venue"];
      
      // Get the name and category of the venue
      NSString *name = venue[@"name"];
      
      // Category
      NSArray *categories = venue[@"categories"];
      NSDictionary *innerCategories = [categories objectAtIndex:0];
      
      NSString *category = innerCategories[@"name"];
      
      // Image URL
      NSString *imageURLString = [NSString stringWithFormat:@"%@bg_64%@", innerCategories[@"icon"][@"prefix"], innerCategories[@"icon"][@"suffix"]];
      
      [returnArray addObject:@[name, category, imageURLString]];
    }
    
    return [NSArray arrayWithArray:returnArray];
    
  } else {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"noShowContextMessagingLocationAV"]) {
      [self showLocationServicesAlert];
    }
    
    return  nil;
  }
}

- (NSDictionary*)queryFoursquareForNearbyVenues:(NSInteger)numberOfVenues {
  if (!self.locationManager.location) return nil;
  
  // Get the date in YYYYMMDD
  NSDateFormatter *dateFormat = [NSDateFormatter new];
  [dateFormat setDateFormat:@"YYYMMdd"];
  
  // Build the URL
  NSString *openNow = @"1";
  NSString *sortByDistance = @"1";
  NSString *radius = @"50";
  NSString *clientID = @"3VUKCE1KQH5G30T4XDF0M0L1L25ETMTGFWXJ05PXNMG3QXW5";
  NSString *clientSecret = @"4O34UZ5VIQVMRSI5GQTGEG4P1MJP3QNWGY0IPYQYWQVQ25U1";
  NSString *date = [dateFormat stringFromDate:[NSDate date]];
  CLLocationCoordinate2D currentLocationCoordinates = self.locationManager.location.coordinate;
  
  NSString *urlString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/explore?ll=%f,%f&openNow=%@&sortByDistance=%@&limit=%li&radius=%@&llAcc=%f&client_id=%@&client_secret=%@&v=%@",  currentLocationCoordinates.latitude, currentLocationCoordinates.longitude, openNow, sortByDistance, (long)numberOfVenues, radius,self.locationManager.location.horizontalAccuracy, clientID, clientSecret, date];
  
  // Make the request
  NSMutableURLRequest *request = [NSMutableURLRequest new];
  [request setURL:[NSURL URLWithString:urlString]];
  [request setHTTPMethod:@"GET"];
  
  // Make sure we have valid data to parse otherwise app will crash
  NSData *responseData = [QNSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
  if (responseData) {
    return [(NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil] objectForKey:@"response"];
  }
  
  return nil;
}

#pragma mark - Sending
- (void)sendMessage:(DMessage* _Nonnull)message toContact:(DUser* _Nonnull)user withCompletion:(_Nullable MessageCompletionBlock)handler {
  // Check if we blocked this user or if he blocked us
  if ([[DUser currentUser].blockedEmails containsObject:user.email] || [user.blockedEmails containsObject:[DUser currentUser].email]) {
    handler(NO, [NSError errorWithDomain:@"Blocked" code:500 userInfo:nil]);
  }
    
  // Build the payload
  NSDictionary *payload;
  
  switch (message.type) {
    case DMessageTypeLocation: {
      if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied && message.includeLocation) {// If we have permission
        payload = @{
                    @"aps": @{
                        @"alert": @{
                            @"title": message.notificationTitle,
                            @"body": message.notificationMessage,
                            @"actions" : @[
                                @{
                                  @"id" : @"REPLY_ACTION",
                                  @"title" : @"Reply"
                                  },
                                ]
                            },
                        
                        @"sound": @"default",
                        @"category": @"REPLY_CATEGORY"
                        },
                    
                    @"long": [NSNumber numberWithDouble:message.location.coordinate.longitude],
                    @"lat": [NSNumber numberWithDouble:message.location.coordinate.latitude],
                    
                    @"username": [DUser currentUser].username,
                    @"email": [DUser currentUser].email,
                    
                    @"lastSeen": message.lastSeen
                    };
        
      } else if (message.includeLocation) {
        [self showLocationServicesAlert];
        
        handler(NO, [NSError errorWithDomain:@"Location" code:500 userInfo:nil]);
      }
      
      break;
    }
    
    case DMessageTypeMessage: {
      payload = @{
                  @"aps": @{
                      @"alert": @{
                          @"title": message.notificationTitle,
                          @"body": message.notificationMessage,
                          @"actions" : @[
                              @{
                                @"id" : @"REPLY_ACTION",
                                @"title" : @"Reply"
                                },
                              ]
                          },
                      
                      @"sound": @"default",
                      @"category": @"REPLY_CATEGORY"
                      },

                  @"long": (message.includeLocation) ? [NSNumber numberWithDouble:message.location.coordinate.longitude] : @"",
                  @"lat": (message.includeLocation) ? [NSNumber numberWithDouble:message.location.coordinate.latitude] : @"",
                  @"email": [DUser currentUser].email,
                  @"username": [DUser currentUser].username,
                  
                  @"lastSeen": message.lastSeen
                  };
      
      break;
    }
    
    case DMessageTypeURL: {
      if (message.URL) {
        payload = @{
                    @"aps": @{
                        @"alert": @{
                            @"title": message.notificationTitle,
                            @"body": message.notificationMessage,
                            @"actions" : @[
                                @{
                                  @"id" : @"REPLY_ACTION",
                                  @"title" : @"Reply"
                                  },
                                ]
                            },
                        
                        @"sound": @"default",
                        @"category": @"REPLY_CATEGORY"
                        },
                    
                    @"url": message.URL.absoluteString,
                    
                    @"username": [DUser currentUser].username,
                    @"email": [DUser currentUser].email,
                    
                    @"long": (message.includeLocation) ? [NSNumber numberWithDouble:message.location.coordinate.longitude] : @"",
                    @"lat": (message.includeLocation) ? [NSNumber numberWithDouble:message.location.coordinate.latitude] : @"",
                    
                    @"lastSeen": message.lastSeen
                    };
        
      } else {
        handler(NO, [NSError errorWithDomain:@"URL" code:404 userInfo:nil]);
      }

      break;
    }
  }
  
  // Build the query for this user's installation
  PFQuery *query = [PFInstallation query];
  [query whereKey:@"user" equalTo:user];
  
  // Send the notification.
  PFPush *push = [PFPush push];
  [push setData:payload];
  [push setQuery:query];
  
  [push sendPushInBackgroundWithBlock:handler];
  
  NSDictionary *cloudFunctionPayload = @{@"builtDictionary": @{@"data": [NSKeyedArchiver archivedDataWithRootObject:message]},
                            @"email": [DUser currentUser].email};
  
  [PFCloud callFunctionInBackground:@"updateLastSeen" withParameters:cloudFunctionPayload block:^(id result, NSError *error) {
    if (error) {
      NSLog(@"error calling 'updateLastSeen' function: %@", error);
    }
  }];
}

- (void)tweetMessage:(DMessage* _Nonnull)message withCompletion:(_Nullable MessageCompletionBlock)handler {
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"twitterAccountID"]];
  
  NSString *socialMessage = [message.message stringByReplacingOccurrencesOfString:@"Dude" withString:@"Dudes"];
  
  NSDictionary *messageDict;
  switch (message.type) {
    case DMessageTypeMessage: {}
    case DMessageTypeLocation: {
      messageDict = @{
                      @"status": socialMessage,
                      @"long" : (message.includeLocation) ? [NSString stringWithFormat:@"%f", message.location.coordinate.longitude] : @"",
                      @"lat" : (message.includeLocation) ? [NSString stringWithFormat:@"%f", message.location.coordinate.latitude] : @"",
                      @"display_coordinates": (message.includeLocation) ? @"true" : @"false"
                      };
      break;
    }
    
    
    case DMessageTypeURL: {
      // Shorten the URL
      NSURL *apiEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", message.URL.absoluteString]];
      NSURLRequest *request = [NSURLRequest requestWithURL:apiEndpoint cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0f];
      
      NSError *error;
      NSData *resultData = [QNSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

      if (!resultData && handler) handler(NO, error);

      NSString *shortenedURL = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
      
      // Modify the message string
      socialMessage = [socialMessage stringByReplacingOccurrencesOfString:@"." withString:@":"];
      messageDict = @{
                      @"status": [NSString stringWithFormat:@"%@ %@", socialMessage, shortenedURL],
                      @"long" : (message.includeLocation) ? [NSString stringWithFormat:@"%f", message.location.coordinate.longitude] : @"",
                      @"lat" : (message.includeLocation) ? [NSString stringWithFormat:@"%f", message.location.coordinate.latitude] : @"",
                      @"display_coordinates": (message.includeLocation) ? @"true" : @"false"

                      };
      break;
    }
  }
  
  NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
  
  SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:requestURL parameters:messageDict];
  
  postRequest.account = account;
  
  [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *requestError) {
    if (requestError && handler) {
      handler(NO, requestError);
      
    } else if (urlResponse.statusCode == 200 && handler) {
      handler(YES, nil);
    }
  }];
}

- (void)postMessage:(DMessage* _Nonnull)message withCompletion:(_Nullable MessageCompletionBlock)handler {
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccountID"]];
  
  NSString *socialMessage = [message.message stringByReplacingOccurrencesOfString:@"Dude" withString:@"Dudes"];
  
  NSDictionary *messageDict;
  switch (message.type) {
    case DMessageTypeLocation: {}
    case  DMessageTypeMessage: {
      messageDict = @{
                      @"access_token": account.credential.oauthToken,
                      @"message": socialMessage,
                      @"link": (message.includeLocation) ? [NSString stringWithFormat:@"http://maps.apple.com/maps?q=%f,%f", message.location.coordinate.latitude, message.location.coordinate.longitude] : @""
                      };
      break;
    }
    
    
    case DMessageTypeURL: {
      // Shorten the URL
      NSURL *apiEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", message.URL.absoluteString]];
      NSURLRequest *request = [NSURLRequest requestWithURL:apiEndpoint cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0f];
      
      NSError *error;
      NSData *resultData = [QNSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
      
      if (!resultData && handler) handler(NO, error);
      
      NSString *shortenedURL = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
      
      // Modify the message string
      messageDict = @{
                      @"access_token": account.credential.oauthToken,
                      @"message": socialMessage,
                      @"link": shortenedURL
                      };
      break;
    }
  }
  
  NSURL *requestURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
  
  SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:requestURL parameters:messageDict];
  
  postRequest.account = account;
  
  [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *requestError) {
    if (requestError && handler) {
      handler(NO, requestError);
      
    } else if (urlResponse.statusCode == 200 && handler) {
      handler(YES, nil);
    }
  }];
}

#pragma mark - Helper Methods
- (void)showLocationServicesAlert {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *locationServicesAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"You must enable location services to be able to send your location and generate meaningfull messages." preferredStyle:UIAlertControllerStyleAlert];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
      [locationServicesAlertController addAction:[UIAlertAction actionWithTitle:@"Open Preferences" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
      }]];
    }
    
    [locationServicesAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController presentViewController:locationServicesAlertController animated:YES completion:nil];
  });
}

@end