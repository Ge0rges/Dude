//
//  DMessage.m
//
//
//  Created by Georges Kanaan on 6/17/15.
//
//

#import "DMessage.h"

// Pods
#import <Parse/Parse.h>

// Models
#import "DUser.h"

NSString* const MessageKey = @"message";
NSString* const NotificationMessageKey = @"notificationMessage";
NSString* const NotificationTitleKey = @"notificationTitle";
NSString* const VenueNameKey = @"venueName";
NSString* const LastSeenKey = @"lastSeen";
NSString* const URLKey = @"URL";
NSString* const ImageURLKey = @"imageURL";
NSString* const LocationKey = @"location";
NSString* const LocationCityKey = @"locationCity";
NSString* const CategoryKey = @"category";
NSString* const TypeKey = @"type";
NSString* const SendDateKey = @"sendDate";
NSString* const TimestampKey = @"timestamp";

@interface DMessage ()

@property (strong, nonatomic) NSString *message;// The full message string (Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic) NSString *notificationMessage;// The string to be used for notifications (Gio: Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic) NSString *notificationTitle;// The string to be used for notification titles (Gio - Message/Link/'s Location)
@property (strong, nonatomic) NSString *venueName;// The string to be used for venue reference (Itsu)

@property (strong, nonatomic) NSString *lastSeen;// The last seen to be used for this message (Eating sushi for lunch at Itsu, London)

@property (strong, nonatomic) NSURL *URL;// The URL associted with message (http://itsu.com)
@property (strong, nonatomic) NSURL *imageURL;// The URL for the image associted with message (category or venue)

@property (strong, nonatomic) CLLocation *location;// The location of the sender
@property (strong, nonatomic) NSString *locationCity;// The city of the sender (London)

@property (strong, nonatomic) NSString *category;// The 4sq category from which it was generated (Sushi Restaurant)

@property (strong, nonatomic) NSString *timestamp; // The timestamp to show for this message
@property (nonatomic) DMessageType type;// What kind of message is this

@end

@implementation DMessage

@synthesize message, notificationMessage, lastSeen, URL, location, locationCity, category, type, notificationTitle, venueName, imageURL, sendDate, timestamp;

#pragma mark - Initilizations
- (instancetype)initWithCategory:(NSString*)messageCategory location:(CLLocation*)messageLocation venueName:(NSString*)messageVenueName  venueCity:(NSString*)messageLocationCity imageURL:(NSString*)imageURLString {
  if (self = [super init]) {
    self.category = [messageCategory copy];
    self.location = [messageLocation copy];
    self.venueName = [messageVenueName copy];
    self.locationCity = [messageLocationCity copy];
    self.type = DMessageTypeMessage;
    self.imageURL = [NSURL URLWithString:imageURLString];
    
    if (!self.location || !self.venueName || !self.locationCity) return nil;
    if (![self actionSentences][self.category]) { // Check that the category is valid othwise notifies dev
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Notify Devs
        PFQuery *innerQuery = [DUser query];
        [innerQuery whereKey:@"email" equalTo:@"ge0rges@ge0rges.com"];
        
        // Build the query for this user's installation
        PFQuery *query = [PFInstallation query];
        [query whereKey:@"user" matchesQuery:innerQuery];
        
        // Send the notification.
        PFPush *push = [PFPush push];
        [push setMessage:[NSString stringWithFormat:@"Dude, unsupported category: [%@]", self.category]];
        [push setQuery:query];
        
        [push sendPushInBackground];
      });
      
      return nil;
    }
    
    // Format venue name
    self.venueName = ([self.venueName hasSuffix:@"."]) ? [self.venueName substringToIndex:[self.venueName length]-1] : self.venueName;
  }
  
  return self;
}

- (instancetype)initForLocation:(CLLocation*)messageLocation venueCity:(NSString*)messageLocationCity {
  if (self = [super init]) {
    self.location = [messageLocation copy];
    self.locationCity = [messageLocationCity copy];
    self.type = DMessageTypeLocation;

    if (!self.location || !self.locationCity) return nil;
  }
  
  return self;
}

- (instancetype)initForPasteboardURLWithLocation:(CLLocation*)messageLocation {
  if (self = [super init]) {
    self.location = [messageLocation copy];
    self.type = DMessageTypeURL;
    
    if (!self.URL || !self.location) return nil;
  }
  
  return self;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  if (self = [super init]) {
    self.message = [aDecoder decodeObjectForKey:MessageKey];
    self.notificationMessage = [aDecoder decodeObjectForKey:NotificationMessageKey];
    self.notificationTitle = [aDecoder decodeObjectForKey:NotificationTitleKey];
    self.venueName = [aDecoder decodeObjectForKey:VenueNameKey];
    self.lastSeen = [aDecoder decodeObjectForKey:LastSeenKey];
    self.URL = [aDecoder decodeObjectForKey:URLKey];
    self.imageURL = [aDecoder decodeObjectForKey:ImageURLKey];
    self.location = [aDecoder decodeObjectForKey:LocationKey];
    self.locationCity = [aDecoder decodeObjectForKey:LocationCityKey];
    self.category = [aDecoder decodeObjectForKey:CategoryKey];
    self.type = [aDecoder decodeIntegerForKey:TypeKey];
    self.sendDate = [aDecoder decodeObjectForKey:SendDateKey];
    self.timestamp = [aDecoder decodeObjectForKey:TimestampKey];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder {
  [aCoder encodeObject:self.message forKey:MessageKey];
  [aCoder encodeObject:self.notificationMessage forKey:NotificationMessageKey];
  [aCoder encodeObject:self.notificationTitle forKey:NotificationTitleKey];
  [aCoder encodeObject:self.venueName forKey:VenueNameKey];
  [aCoder encodeObject:self.lastSeen forKey:LastSeenKey];
  [aCoder encodeObject:self.URL forKey:URLKey];
  [aCoder encodeObject:self.imageURL forKey:ImageURLKey];
  [aCoder encodeObject:self.location forKey:LocationKey];
  [aCoder encodeObject:self.locationCity forKey:LocationCityKey];
  [aCoder encodeObject:self.category forKey:CategoryKey];
  [aCoder encodeInteger:self.type forKey:TypeKey];
  [aCoder encodeObject:self.sendDate forKey:SendDateKey];
  [aCoder encodeObject:self.timestamp forKey:TimestampKey];
}

#pragma mark - Message Parsing
- (NSString*)message {
  switch (self.type) {
    case DMessageTypeURL: {
      return @"Dude, check out this website.";
      break;
    }
    
    case DMessageTypeMessage: {
      // Get raw message
      NSString *rawSentence = [self actionSentences][self.category];
      
      // Get the replacers
      // Determine breakfast, brunch, lunch or dinner
      NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]];
      NSInteger hour = [components hour];
      
      NSString *eatingTime = (hour>=5 && hour<=9) ? @"breakfast" : (hour>=10 && hour<=11) ? @"brunch" : (hour>=12 && hour<=17) ? @"lunch" : @"dinner";
      NSString *eatingActionString = [NSString stringWithFormat:@"having %@", eatingTime];
      
      // Replace the placeholders
      rawSentence = [rawSentence stringByReplacingOccurrencesOfString:@"name" withString:self.venueName];
      rawSentence = [rawSentence stringByReplacingOccurrencesOfString:@"eatingAction" withString:eatingActionString];
      rawSentence = [rawSentence stringByReplacingOccurrencesOfString:@"eatingTime" withString:eatingTime];
      
      return rawSentence;
      break;
    }
    
    case DMessageTypeLocation: {
      return @"Dude, I'm over here.";
      break;
    }
    
    default: {
      return nil;
      break;
    }
  }
  
  return nil;
}

- (NSString*)notificationMessage {
  // All We have to do here is add the current user's name
  return [NSString stringWithFormat:@"%@: %@", [DUser currentUser].username, self.message];
}

- (NSString*)notificationTitle {
  NSString *username = [DUser currentUser].username;
  
  switch (self.type) {
    case DMessageTypeURL: {
      return [NSString stringWithFormat:@"%@ - Link", username];
      break;
    }
    
    case DMessageTypeMessage: {
      return [NSString stringWithFormat:@"%@ - Message", username];
      break;
    }
    
    case DMessageTypeLocation: {
      return [NSString stringWithFormat:@"%@'s Location", username];
      break;
    }
    
    default: {
      return [NSString stringWithFormat:@"%@ - Message", username];
      break;
    }
  }
}

- (NSString*)lastSeen {
  switch (self.type) {
    case DMessageTypeURL: {
      return [NSString stringWithFormat:@"%@", self.URL.absoluteString];
      break;
    }
    
    case DMessageTypeMessage: {
      if ([self.message isEqualToString:@"Dude."]) return self.message;
      
      // Remove Dude, I'm from message
      NSString *truncatedMessage = [self.message stringByReplacingOccurrencesOfString:@"Dude, I'm " withString:@""];
      
      // Add location to end of sentence
      truncatedMessage = [truncatedMessage stringByAppendingString:[NSString stringWithFormat:@", %@.", self.locationCity]];
      
      if (truncatedMessage.length > 0) {
        // Capitalize first letter of sentence
        return [truncatedMessage stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[truncatedMessage substringToIndex:1] capitalizedString]];
        
      } else {
        return self.message;
      }
      
      break;
    }
    
    case DMessageTypeLocation: {
      return [NSString stringWithFormat:@"Current Location, %@", self.locationCity];
      break;
    }
    
    default: {
      break;
    }
  }
}

- (NSURL*)URL {
  return [NSURL URLWithString:[UIPasteboard generalPasteboard].string];
}

- (NSString*)timestamp {
  // Get the users last notification sent to us
  
  NSInteger secondsSinceTimeStamp = -[self.sendDate timeIntervalSinceNow];
  NSString *timestampString;
  
  if (secondsSinceTimeStamp) {
    if (secondsSinceTimeStamp <= 120) {
      timestampString = @"(Now)";
      
    } else if (secondsSinceTimeStamp > 120 && secondsSinceTimeStamp < 3600) {
      NSInteger minutes = secondsSinceTimeStamp/60;
      timestampString = [NSString stringWithFormat:@"(%lim ago)", (long)minutes];
      
    } else if (secondsSinceTimeStamp < 86400) {
      NSInteger hours = secondsSinceTimeStamp/3600;
      timestampString = [NSString stringWithFormat:@"(%lih ago)", (long)hours];
      
    } else {
      NSInteger days = secondsSinceTimeStamp/86400;
      timestampString = [NSString stringWithFormat:@"(%lid ago)", (long)days];
    }
  }
  
  return timestampString;
}

#pragma mark - Actions Sentences
- (NSDictionary*)actionSentences {// Someday this will fetch from our server or hopefully be automated
  return @{
           // Custom
           @"Just Dude": @"Dude.",
           
           @"Car": @"Dude, I'm in a car.",
           @"Train": @"Dude, I'm in a train.",
           @"Plane": @"Dude, I'm in a plane.",

           @"Home": @"Dude, I'm at Home.",
           @"Work": @"Dude, I'm at work.",
           @"Friend": @"Dude, I'm at a Friend's.",

           //Foursquare categories
           @"Arts & Entertainment":	@"Dude, I'm having fun at name.",
           @"Aquarium":	@"Dude, I'm seeing fish at name.",
           @"Arcade":	@"Dude, I'm playing have fun at name.",
           @"Art Gallery":	@"Dude, I'm enjoying some beautiful art at name.",
           @"Bowling Alley":	@"Dude, I'm bowling at name.",
           @"Casino":	@"Dude, I'm gambling at name.",
           @"Circus":	@"Dude, I'm having a laugh at name.",
           @"Comedy Club":	@"Dude, I'm having a laugh at name.",
           @"Concert Hall":	@"Dude, I'm watching a concert at name.",
           @"Country Dance Club":	@"Dude, I'm dancing at name.",
           @"Disc Golf":	@"Dude, I'm playing some disc golf at name.",
           @"General Entertainment":	@"Dude, I'm being entertained at name.",
           @"Go Kart Track":	@"Dude, I'm karting at name.",
           @"Historic Site":	@"Dude, I'm appreciating history at name.",
           @"Laser Tag":	@"Dude, I'm shooting some lasers at name.",
           @"Mini Golf":	@"Dude, I'm playing mini golf at name.",
           @"Movie Theater":	@"Dude, I'm watching a movie at name.",
           @"Indie Movie Theater":	@"Dude, I'm at watching a indie movie at name.",
           @"Multiplex":	@"Dude, I'm watching a movie at name.",
           @"Museum":	@"Dude, I'm learning stuff at name.",
           @"Art Museum":	@"Dude, I'm enjoying art at name.",
           @"History Museum":	@"Dude, I'm learning about history at name.",
           @"Planetarium":	@"Dude, I'm watching stars at name.",
           @"Science Museum":	@"Dude, I'm exploring science at name.",
           @"Music Venue":	@"Dude, I'm listening to music at name.",
           @"Jazz Club":	@"Dude, I'm listening to jazz at name.",
           @"Piano Bar":	@"Dude, I'm listening to some piano at name.",
           @"Rock Club":	@"Dude, I'm rocking out at name.",
           @"Outdoor Sculpture":	@"Dude, I'm contemplating sculptures at name.",
           @"Performing Arts Venue":	@"Dude, I'm watching people perform at name.",
           @"Dance Studio":	@"Dude, I'm learning to dance at name.",
           @"Indie Theater":	@"Dude, I'm watching indie dancers at name.",
           @"Opera House":	@"Dude, I'm watching an opera at name.",
           @"Theater":	@"Dude, I'm at name.",
           @"Pool Hall":	@"Dude, I'm playing some pool at name.",
           @"Public Art":	@"Dude, I'm admiring some public art at name.",
           @"Racetrack":	@"Dude, I'm watching a car race at name.",
           @"Roller Rink":	@"Dude, I'm rollerblading at name.",
           @"Salsa Club":	@"Dude, I'm dancing the salsa at name.",
           @"Stadium":	@"Dude, I'm watching sports at name.",
           @"Baseball Stadium":	@"Dude, I'm watching baseball at name.",
           @"Basketball Stadium":	@"Dude, I'm watching basketball at name.",
           @"Cricket Ground":	@"Dude, I'm watching cricket at name.",
           @"Football Stadium":	@"Dude, I'm watching football at name.",
           @"Hockey Arena":	@"Dude, I'm watching hokey at name.",
           @"Soccer Stadium":	@"Dude, I'm watching soccer at name.",
           @"Tennis":	@"Dude, I'm watching tennis at name.",
           @"Track Stadium":	@"Dude, I'm a track race at name.",
           @"Street Art":	@"Dude, I'm looking at street art at name.",
           @"Theme Park":	@"Dude, I'm having fun at name.",
           @"Theme Park Ride / Attraction":	@"Dude, I'm having fun on name.",
           @"Water Park":	@"Dude, I'm splashing around at name.",
           @"Zoo": 	@"Dude, I'm seeing animals at name.",
           @"College & University":	@"Dude, I'm studying at name.",
           @"College Academic Building":	@"Dude, I'm studying at name.",
           @"College Arts Building":	@"Dude, I'm studying art at name.",
           @"College Communications Building":	@"Dude, I'm studying at name.",
           @"College Engineering Building":	@"Dude, I'm studying engineering at name.",
           @"College History Building":	@"Dude, I'm studying history at name.",
           @"College Math Building":	@"Dude, I'm studying math at name.",
           @"College Science Building":	@"Dude, I'm studying science at name.",
           @"College Technology Building":	@"Dude, I'm studying tech. at name.",
           @"College Administrative Building":	@"Dude, I'm studying at name.",
           @"College Auditorium":	@"Dude, I'm studying at name.",
           @"College Bookstore":	@"Dude, I'm buying books at name.",
           @"College Cafeteria":	@"Dude, I'm eatingAction at name.",
           @"College Classroom":	@"Dude, I'm studying at name.",
           @"College Gym":	@"Dude, I'm at name.",
           @"College Lab":	@"Dude, I'm studying science at name.",
           @"College Library":	@"Dude, I'm reading at name.",
           @"College Quad":	@"Dude, I'm relaxing at name.",
           @"College Rec Center":	@"Dude, I'm taking a break at name.",
           @"College Residence Hall":	@"Dude, I'm at name.",
           @"College Stadium":	@"Dude, I'm watching sports at name.",
           @"College Baseball Diamond":	@"Dude, I'm watching baseball at name.",
           @"College Basketball Court":	@"Dude, I'm watching basketball at name.",
           @"College Cricket Pitch":	@"Dude, I'm watching cricket at name.",
           @"College Football Field":	@"Dude, I'm watching football at name.",
           @"College Hockey Rink":	@"Dude, I'm watching hokey at name.",
           @"College Soccer Field":	@"Dude, I'm watching soccer at name.",
           @"College Tennis Court":	@"Dude, I'm watching tennis at name.",
           @"College Track":	@"Dude, I'm watching a track race at name.",
           @"College Theater":	@"Dude, I'm watching a play at name.",
           @"Community College":	@"Dude, I'm at name.",
           @"Fraternity House":	@"Dude, I'm partying at name.",
           @"General College & University":	@"Dude, I'm studying at name.",
           @"Law School":	@"Dude, I'm studying law at name.",
           @"Medical School":	@"Dude, I'm studying medicine at name.",
           @"Sorority House":	@"Dude, I'm partying at name.",
           @"Student Center":	@"Dude, I'm hanging out at name.",
           @"Trade School":	@"Dude, I'm studying trade at name.",
           @"University":	@"Dude, I'm studying at name.",
           @"Event":	@"Dude, I'm attending an event at name.",
           @"Conference":	@"Dude, I'm attending a conference at name.",
           @"Convention":	@"Dude, I'm attending a convention at name.",
           @"Festival":	@"Dude, I'm having fun at name.",
           @"Music Festival":	@"Dude, I'm listening to music at name.",
           @"Other Event":	@"Dude, I'm attending an event at name.",
           @"Parade":	@"Dude, I'm participating in a parade at name.",
           @"Stoop Sale":	@"Dude, I'm buying stuff at name.",
           @"Street Fair":	@"Dude, I'm participating in a street fair at name.",
           @"Food":	@"Dude, I'm eatingAction at name.",
           @"Afghan Restaurant":	@"Dude, I'm eating afghan food for eatingTime at name.",
           @"African Restaurant":	@"Dude, I'm eating african food for eatingTime at name.",
           @"American Restaurant":	@"Dude, I'm eating american food for eatingTime at name.",
           @"Arepa Restaurant":	@"Dude, I'm eating arepas food for eatingTime at name.",
           @"Argentinian Restaurant":	@"Dude, I'm eating Argentinian food for eatingTime at name.",
           @"Asian Restaurant":	@"Dude, I'm eating asian food for eatingTime at name.",
           @"Australian Restaurant":	@"Dude, I'm eating Australian food for eatingTime at name.",
           @"Austrian Restaurant":	@"Dude, I'm eating Austrian food for eatingTime at name.",
           @"BBQ Joint":	@"Dude, I'm eating BBQ food for eatingTime at name.",
           @"Bagel Shop":	@"Dude, I'm eating bagels food for eatingTime at name.",
           @"Bakery":	@"Dude, I'm eating pastries food for eatingTime at name.",
           @"Belarusian Restaurant":	@"Dude, I'm eating Belarusian food for eatingTime at name.",
           @"Belgian Restaurant":	@"Dude, I'm eating Belgian food for eatingTime at name.",
           @"Bistro":	@"Dude, I'm eatingAction at name.",
           @"Brazilian Restaurant":	@"Dude, I'm eating Brazilian food for eatingTime at name.",
           @"Acai House":	@"Dude, I'm eating açai food for eatingTime at name.",
           @"Baiano Restaurant":	@"Dude, I'm eating baiano food for eatingTime at name.",
           @"Central Brazilian Restaurant":	@"Dude, I'm eating central Brazilian food for eatingTime at name.",
           @"Churrascaria":	@"Dude, I'm eating churrascaria at name.",
           @"Empada House":	@"Dude, I'm eating empadas at name.",
           @"Goiano Restaurant":	@"Dude, I'm eating goiano food for eatingTime at name.",
           @"Mineiro Restaurant":	@"Dude, I'm eatingAction at a mineiro restaurant called name.",
           @"Northeastern Brazilian Restaurant":	@"Dude, I'm eating northeastern Brazilian goiano food for eatingTime at name.",
           @"Northern Brazilian Restaurant":	@"Dude, I'm eating northern Brazilian food for eatingTime at name.",
           @"Pastelaria":	@"Dude, I'm eatingAction at a pastelaria called name.",
           @"Southeastern Brazilian Restaurant":	@"Dude, I'm eating southeastern Brazilian food for eatingTime at name.",
           @"Southern Brazilian Restaurant":	@"Dude, I'm eating Southern Brazilian food for eatingTime at name.",
           @"Tapiocaria":	@"Dude, I'm eatingAction at a tapiocaria called name.",
           @"Breakfast Spot":	@"Dude, I'm having breakfast at name.",
           @"Bubble Tea Shop":	@"Dude, I'm buying bubble tea at name.",
           @"Buffet":	@"Dude, I'm eatingAction at a buffet for eatingTime at name.",
           @"Burger Joint":	@"Dude, I'm eating a burger for eatingTime at name.",
           @"Burrito Place":	@"Dude, I'm eating burritos at name.",
           @"Cafeteria":	@"Dude, I'm eatingAction at name.",
           @"Café":	@"Dude, I'm having coffee at name.",
           @"Cajun / Creole Restaurant":	@"Dude, I'm eating creole food for eatingTime at name.",
           @"Cambodian Restaurant":	@"Dude, I'm eating Cambodian food for eatingTime at name.",
           @"Caribbean Restaurant":	@"Dude, I'm eating Caribbean food for eatingTime at name.",
           @"Caucasian Restaurant":	@"Dude, I'm eating Caucasian food for eatingTime at name.",
           @"Chinese Restaurant":	@"Dude, I'm eating Chinese food for eatingTime at name.",
           @"Anhui Restaurant":	@"Dude, I'm eating Anhui food for eatingTime at name.",
           @"Beijing Restaurant":	@"Dude, I'm eating Chinese food for eatingTime at name.",
           @"Cantonese Restaurant":	@"Dude, I'm eating Cantonese food for eatingTime at name.",
           @"Chinese Aristocrat Restaurant":	@"Dude, I'm eating Chinese aristocrat food for eatingTime at name.",
           @"Chinese Breakfast Place":	@"Dude, I'm having a Chinese breakfast at name.",
           @"Dongbei Restaurant":	@"Dude, I'm eating Dongbei food for eatingTime at name.",
           @"Fujian Restaurant":	@"Dude, I'm eating Fujian food for eatingTime at name.",
           @"Guizhou Restaurant":	@"Dude, I'm eating Guizhou food for eatingTime at name.",
           @"Hainan Restaurant":	@"Dude, I'm eating Hainan food for eatingTime at name.",
           @"Hakka Restaurant":	@"Dude, I'm eating Hakka food for eatingTime at name.",
           @"Henan Restaurant":	@"Dude, I'm eating Henan food for eatingTime at name.",
           @"Hong Kong Restaurant":	@"Dude, I'm eating food from Hong Kong at name.",
           @"Huaiyang Restaurant":	@"Dude, I'm eating Huaiyang food at name.",
           @"Hubei Restaurant":	@"Dude, I'm eating Hubei food for eatingTime at name.",
           @"Hunan Restaurant":	@"Dude, I'm eating Hunan food for eatingTime at name.",
           @"Imperial Restaurant":	@"Dude, I'm eating imperial food for eatingTime at name.",
           @"Jiangsu Restaurant":	@"Dude, I'm eating Jiangsu food for eatingTime at name.",
           @"Jiangxi Restaurant":	@"Dude, I'm eating Jiangxi food for eatingTime at name.",
           @"Macanese Restaurant":	@"Dude, I'm eating Macanese food for eatingTime at name.",
           @"Manchu Restaurant":	@"Dude, I'm eating Manchu food for eatingTime at name.",
           @"Peking Duck Restaurant":	@"Dude, I'm eatingAction at a Peking Duck Restaurant called name.",
           @"Shaanxi Restaurant":	@"Dude, I'm eating Shaanxi food for eatingTime at name.",
           @"Shandong Restaurant":	@"Dude, I'm eating Shandong food for eatingTime at name.",
           @"Shanghai Restaurant":	@"Dude, I'm eating Shanghais food for eatingTime at name.",
           @"Shanxi Restaurant":	@"Dude, I'm eating Shanxi food for eatingTime at name.",
           @"Szechuan Restaurant":	@"Dude, I'm eating Szechuan food for eatingTime at name.",
           @"Taiwanese Restaurant":	@"Dude, I'm eating Yaiwanese food for eatingTime at name.",
           @"Tianjin Restaurant":	@"Dude, I'm eating Yianjin food for eatingTime at name.",
           @"Xinjiang Restaurant":	@"Dude, I'm eating Xinjiang food for eatingTime at name.",
           @"Yunnan Restaurant":	@"Dude, I'm eating Yunnan food for eatingTime at name.",
           @"Zhejiang Restaurant":	@"Dude, I'm eating Zhejiang food for eatingTime at name.",
           @"Coffee Shop":	@"Dude, I'm having some coffee at name.",
           @"Comfort Food Restaurant":	@"Dude, I'm eatingAction at name.",
           @"Creperie":	@"Dude, I'm having crepes at name.",
           @"Cuban Restaurant":	@"Dude, I'm eating cuban food for eatingTime at name.",
           @"Cupcake Shop":	@"Dude, I'm having cupcakes at name.",
           @"Czech Restaurant":	@"Dude, I'm eating Czech food for eatingTime at name.",
           @"Deli / Bodega":	@"Dude, I'm eatingAction at name.",
           @"Dessert Shop":	@"Dude, I'm having dessert at name.",
           @"Dim Sum Restaurant":	@"Dude, I'm eatingAction at name.",
           @"Diner":	@"Dude, I'm eatingAction at name.",
           @"Distillery":	@"Dude, I'm drinking at name.",
           @"Donut Shop":	@"Dude, I'm snacking on donuts at name.",
           @"Dumpling Restaurant":	@"Dude, I'm eating dumpling food for eatingTime at name.",
           @"Eastern European Restaurant":	@"Dude, I'm eating Eastern European food for eatingTime at name.",
           @"English Restaurant":	@"Dude, I'm eating English food for eatingTime at name.",
           @"Ethiopian Restaurant":	@"Dude, I'm eating Ethiopian food for eatingTime at name.",
           @"Falafel Restaurant":	@"Dude, I'm eating falafel food for eatingTime at name.",
           @"Fast Food Restaurant":	@"Dude, I'm eating fast food for eatingTime at name.",
           @"Filipino Restaurant":	@"Dude, I'm eating Filipino food for eatingTime at name.",
           @"Fish & Chips Shop":	@"Dude, I'm eating fish & chips at name.",
           @"Fondue Restaurant":	@"Dude, I'm eating fondue for eatingTime at name.",
           @"Food Truck":	@"Dude, I'm eating from a food truck called name.",
           @"French Restaurant":	@"Dude, I'm eating French food for eatingTime at name.",
           @"Fried Chicken Joint":	@"Dude, I'm eating fried chicken at name.",
           @"Gastropub":	@"Dude, I'm eatingAction at name.",
           @"German Restaurant":	@"Dude, I'm eating German food for eatingTime at name.",
           @"Gluten-free Restaurant":	@"Dude, I'm eating gluten-free food for eatingTime at name.",
           @"Greek Restaurant":	@"Dude, I'm eating Greek food for eatingTime at name.",
           @"Bougatsa Shop":	@"Dude, I'm eating bougatsa at name.",
           @"Cretan Restaurant":	@"Dude, I'm eating Cretan food for eatingTime at name.",
           @"Fish Taverna":	@"Dude, I'm eating fish at name.",
           @"Grilled Meat Restaurant":	@"Dude, I'm eating grilled meat at name.",
           @"Kafenio":	@"Dude, I'm drinking greek coffee bougatsa at name.",
           @"Magirio":	@"Dude, I'm eating Cypriot food for eatingTime at name.",
           @"Meze Restaurant":	@"Dude, I'm eating Meze food for eatingTime at name.",
           @"Modern Greek Restaurant":	@"Dude, I'm eating Greek food for eatingTime at name.",
           @"Ouzeri":	@"Dude, I'm eating ouzeri at name.",
           @"Patsa Restaurant":	@"Dude, I'm eating patsa food for eatingTime at name.",
           @"Taverna":	@"Dude, I'm eatingAction at name.",
           @"Tsipouro Restaurant":	@"Dude, I'm eating tsipouro food for eatingTime at name.",
           @"Halal Restaurant":	@"Dude, I'm eating halal food for eatingTime at name.",
           @"Hawaiian Restaurant":	@"Dude, I'm eating Hawaiian food for eatingTime at name.",
           @"Himalayan Restaurant":	@"Dude, I'm eating himalayan food for eatingTime at name.",
           @"Hot Dog Joint":	@"Dude, I'm eating hot dogs at name.",
           @"Hotpot Restaurant":	@"Dude, I'm eating hotpot food for eatingTime at name.",
           @"Hungarian Restaurant":	@"Dude, I'm eating Hungarian food for eatingTime at name.",
           @"Ice Cream Shop":	@"Dude, I'm enjoying ice cream at name.",
           @"Indian Restaurant":	@"Dude, I'm eating Indian food for eatingTime at name.",
           @"Andhra Restaurant":	@"Dude, I'm eating andhra food for eatingTime at name.",
           @"Awadhi Restaurant":	@"Dude, I'm eating awadhi food for eatingTime at name.",
           @"Bengali Restaurant":	@"Dude, I'm eating bengali food for eatingTime at name.",
           @"Chaat Place":	@"Dude, I'm eating chaat snacks at name.",
           @"Chettinad Restaurant":	@"Dude, I'm eating chettinad food for eatingTime at name.",
           @"Dhaba":	@"Dude, I'm eating Indian food for eatingTime at name.",
           @"Dosa Place":	@"Dude, I'm eating south indian at name.",
           @"Goan Restaurant":	@"Dude, I'm eating Goan food for eatingTime at name.",
           @"Gujarati Restaurant":	@"Dude, I'm eating gujarati food for eatingTime at name.",
           @"Hyderabadi Restaurant":	@"Dude, I'm eating hyderabadi food for eatingTime at name.",
           @"Indian Chinese Restaurant":	@"Dude, I'm eating indian Chinese food for eatingTime at name.",
           @"Irani Cafe":	@"Dude, I'm drinking Irani coffee at name.",
           @"Jain Restaurant":	@"Dude, I'm eating jain food for eatingTime at name.",
           @"Karnataka Restaurant":	@"Dude, I'm eating Karnataka food for eatingTime at name.",
           @"Kerala Restaurant":	@"Dude, I'm eating Kerala food for eatingTime at name.",
           @"Maharashtrian Restaurant":	@"Dude, I'm eating Maharashtrian food for eatingTime at name.",
           @"Mughlai Restaurant":	@"Dude, I'm eating Mughlai food for eatingTime at name.",
           @"Multicuisine Indian Restaurant":	@"Dude, I'm eating multicuisine Indian food for eatingTime at name.",
           @"North Indian Restaurant":	@"Dude, I'm eating north Indian food for eatingTime at name.",
           @"Northeast Indian Restaurant":	@"Dude, I'm eating northeast Indian food for eatingTime at name.",
           @"Parsi Restaurant":	@"Dude, I'm eating parsi food for eatingTime at name.",
           @"Punjabi Restaurant":	@"Dude, I'm eating punjabi food for eatingTime at name.",
           @"Rajasthani Restaurant":	@"Dude, I'm eating rajasthani food for eatingTime at name.",
           @"South Indian Restaurant":	@"Dude, I'm eating south Indian food for eatingTime at name.",
           @"Sweet Shop":	@"Dude, I'm eating sweets at name.",
           @"Udupi Restaurant":	@"Dude, I'm eating udupi food for eatingTime at name.",
           @"Indonesian Restaurant":	@"Dude, I'm eating Indonesian food for eatingTime at name.",
           @"Acehnese Restaurant":	@"Dude, I'm eating Acehnese food for eatingTime at name.",
           @"Balinese Restaurant":	@"Dude, I'm eating Balinese food for eatingTime at name.",
           @"Betawinese Restaurant":	@"Dude, I'm eating Betawinese food for eatingTime at name.",
           @"Javanese Restaurant":	@"Dude, I'm eating Javanese food for eatingTime at name.",
           @"Manadonese Restaurant":	@"Dude, I'm eating Manadonese food for eatingTime at name.",
           @"Meatball Place":	@"Dude, I'm eating meatballs food for eatingTime at name.",
           @"Padangnese Restaurant":	@"Dude, I'm eating Padangnese food for eatingTime at name.",
           @"Sundanese Restaurant":	@"Dude, I'm eating Sundanese food for eatingTime at name.",
           @"Irish Pub":	@"Dude, I'm drinking Irish beer at name.",
           @"Italian Restaurant":	@"Dude, I'm eating Italian food for eatingTime at name.",
           @"Japanese Restaurant":	@"Dude, I'm eating Japanese food for eatingTime at name.",
           @"Jewish Restaurant":	@"Dude, I'm eating jewish food for eatingTime at name.",
           @"Juice Bar":	@"Dude, I'm drinking some juice food for eatingTime at name.",
           @"Korean Restaurant":	@"Dude, I'm eating Korean food for eatingTime at name.",
           @"Kosher Restaurant":	@"Dude, I'm eating kosher food for eatingTime at name.",
           @"Latin American Restaurant":	@"Dude, I'm eating latin american food for eatingTime at name.",
           @"Empanada Restaurant":	@"Dude, I'm eating empanada food for eatingTime at name.",
           @"Mac & Cheese Joint":	@"Dude, I'm eating mac & cheese food for eatingTime at name.",
           @"Malaysian Restaurant":	@"Dude, I'm eating Malaysian food for eatingTime at name.",
           @"Mediterranean Restaurant":	@"Dude, I'm eating mediterranean food for eatingTime at name.",
           @"Mexican Restaurant":	@"Dude, I'm eating Mexican food for eatingTime at name.",
           @"Middle Eastern Restaurant":	@"Dude, I'm eating middle eastern food for eatingTime at name.",
           @"Modern European Restaurant":	@"Dude, I'm eating modern european food for eatingTime at name.",
           @"Molecular Gastronomy Restaurant":	@"Dude, I'm eating molecularly perfect food for eatingTime at name.",
           @"Mongolian Restaurant":	@"Dude, I'm eating Mongolian food for eatingTime at name.",
           @"Moroccan Restaurant":	@"Dude, I'm eating moroccan food for eatingTime at name.",
           @"New American Restaurant":	@"Dude, I'm eating american food for eatingTime at name.",
           @"Pakistani Restaurant":	@"Dude, I'm eating Pakistani food for eatingTime at name.",
           @"Persian Restaurant":	@"Dude, I'm eating Persian food for eatingTime at name.",
           @"Peruvian Restaurant":	@"Dude, I'm eating Peruvian food for eatingTime at name.",
           @"Pie Shop":	@"Dude, I'm eating pie at name.",
           @"Pizza Place":	@"Dude, I'm eating pizza for eatingTime at name.",
           @"Polish Restaurant":	@"Dude, I'm eating Polish food for eatingTime at name.",
           @"Portuguese Restaurant":	@"Dude, I'm eating Portuguese food for eatingTime at name.",
           @"Ramen / Noodle House":	@"Dude, I'm eating ramen at name.",
           @"Restaurant":	@"Dude, I'm eatingAction at name.",
           @"Romanian Restaurant":	@"Dude, I'm eating Romanian food for eatingTime at name.",
           @"Russian Restaurant":	@"Dude, I'm eating Russian food for eatingTime at name.",
           @"Blini House":	@"Dude, I'm eating a blini at name.",
           @"Pelmeni House":	@"Dude, I'm eating pelmenis at name.",
           @"Salad Place":	@"Dude, I'm having some salad at name.",
           @"Sandwich Place":	@"Dude, I'm eating a sandwich at name.",
           @"Scandinavian Restaurant":	@"Dude, I'm eating Scandinavian food for eatingTime at name.",
           @"Seafood Restaurant":	@"Dude, I'm eating seafood for eatingTime at name.",
           @"Snack Place":	@"Dude, I'm having a snack at name.",
           @"Soup Place":	@"Dude, I'm drinking some soup at name.",
           @"South American Restaurant":	@"Dude, I'm eating south american food for eatingTime at name.",
           @"Southern / Soul Food Restaurant":	@"Dude, I'm soul fool food for eatingTime at name.",
           @"Souvlaki Shop":	@"Dude, I'm buying some souvlaki at name.",
           @"Spanish Restaurant":	@"Dude, I'm eating Spanish food for eatingTime at name.",
           @"Paella Restaurant":	@"Dude, I'm eating paellas at name.",
           @"Sri Lankan Restaurant":	@"Dude, I'm eating some Sri Lankan food for eatingTime at name.",
           @"Steakhouse":	@"Dude, I'm eating a juicy steak at name.",
           @"Sushi Restaurant":	@"Dude, I'm eating sushi food for eatingTime at name.",
           @"Swiss Restaurant":	@"Dude, I'm eating swiss food for eatingTime at name.",
           @"Taco Place":	@"Dude, I'm having some tacos at name.",
           @"Tapas Restaurant":	@"Dude, I'm eating tapas at name.",
           @"Tatar Restaurant":	@"Dude, I'm eating tatar at name.",
           @"Tea Room":	@"Dude, I'm drinking some tea at name.",
           @"Thai Restaurant":	@"Dude, I'm eating thai food for eatingTime at name.",
           @"Tibetan Restaurant":	@"Dude, I'm eating tibetan food for eatingTime at name.",
           @"Turkish Restaurant":	@"Dude, I'm eating turkish food for eatingTime at name.",
           @"Borek Place":	@"Dude, I'm eating borek at name.",
           @"Cigkofte Place":	@"Dude, I'm eating cigkofte at name.",
           @"Doner Restaurant":	@"Dude, I'm eating doner food for eatingTime at name.",
           @"Gozleme Place":	@"Dude, I'm eating gozleme at name.",
           @"Home Cooking Restaurant":	@"Dude, I'm eating home cooking food for eatingTime at name.",
           @"Kebab Restaurant":	@"Dude, I'm eating kebabs at name.",
           @"Kofte Place":	@"Dude, I'm eating kofte at name.",
           @"Kokoreç Restaurant":	@"Dude, I'm eating Kokoreç food for eatingTime at name.",
           @"Manti Place":	@"Dude, I'm eating manti at name.",
           @"Meyhane":	@"Dude, I'm eatingAction at name.",
           @"Pide Place":	@"Dude, I'm eatingAction at name.",
           @"Ukrainian Restaurant":	@"Dude, I'm eating Ukrainian food for eatingTime at name.",
           @"Varenyky restaurant":	@"Dude, I'm eating Varenyky food for eatingTime at name.",
           @"West-Ukrainian Restaurant":	@"Dude, I'm eating West-Ukrainian food for eatingTime at name.",
           @"Vegetarian / Vegan Restaurant":	@"Dude, I'm eating some vegan at name.",
           @"Vietnamese Restaurant":	@"Dude, I'm eating vietnamese food for eatingTime at name.",
           @"Winery":	@"Dude, I'm making wine at name.",
           @"Wings Joint":	@"Dude, I'm eating chicken wings for eatingTime at name.",
           @"Frozen Yogurt":	@"Dude, I'm enjoying some frozen yogurt at name.",
           @"Nightlife Spot":	@"Dude, I'm partying at name.",
           @"Bar": 	@"Dude, I'm having a drink at name.",
           @"Beach Bar":	@"Dude, I'm having a drink by the ocean at name.",
           @"Beer Garden":	@"Dude, I'm having a drink at name.",
           @"Brewery":	@"Dude, I'm learning about beer at name.",
           @"Champagne Bar":	@"Dude, I'm drinking some champagne at name.",
           @"Cocktail Bar":	@"Dude, I'm drinking some cocktails at name.",
           @"Dive Bar":	@"Dude, I'm having a drink at name.",
           @"Gay Bar":	@"Dude, I'm with homesexuals at name.",
           @"Hookah Bar":	@"Dude, I'm enjoying shisha at name.",
           @"Hotel Bar":	@"Dude, I'm having a drink at name.",
           @"Karaoke Bar":	@"Dude, I'm singing at name.",
           @"Lounge":	@"Dude, I'm relaxing at name.",
           @"Night Market":	@"Dude, I'm shopping at name.",
           @"Nightclub":	@"Dude, I'm partying at name.",
           @"Other Nightlife":	@"Dude, I'm having fun at name.",
           @"Pub": 	@"Dude, I'm pumping it up at name.",
           @"Sake Bar":	@"Dude, I'm drinking sake at name.",
           @"Speakeasy":	@"Dude, I'm buying adult beverages at name.",
           @"Sports Bar":	@"Dude, I'm socializing at name.",
           @"Strip Club":	@"Dude, I'm getting turned on at name.",
           @"Whisky Bar":	@"Dude, I'm drinking some whisky at name.",
           @"Wine Bar":	@"Dude, I'm enjoying some wine at name.",
           @"Outdoors & Recreation":	@"Dude, I'm having fun at name.",
           @"Athletics & Sports":	@"Dude, I'm working out at name.",
           @"Badminton Court":	@"Dude, I'm playing badminton at name.",
           @"Baseball Field":	@"Dude, I'm playing baseball at name.",
           @"Basketball Court":	@"Dude, I'm playing basketball at name.",
           @"Bowling Green":	@"Dude, I'm playing bowling at name.",
           @"Golf Course":	@"Dude, I'm playing golf at name.",
           @"Hockey Field":	@"Dude, I'm playing hockey at name.",
           @"Paintball Field":	@"Dude, I'm painting people at name.",
           @"Rugby Pitch":	@"Dude, I'm playing rugby at name.",
           @"Skate Park":	@"Dude, I'm skating at name.",
           @"Skating Rink":	@"Dude, I'm skating at name.",
           @"Soccer Field":	@"Dude, I'm playing soccer at name.",
           @"Sports Club":	@"Dude, I'm doing sports at name.",
           @"Squash Court":	@"Dude, I'm playing squash at name.",
           @"Tennis Court":	@"Dude, I'm playing tennis at name.",
           @"Volleyball Court":	@"Dude, I'm playing volleyball at name.",
           @"Bath House":	@"Dude, I'm taking a bath at name.",
           @"Bathing Area":	@"Dude, I'm taking a bath at name.",
           @"Beach":	@"Dude, I'm swimming in the ocean at name.",
           @"Nudist Beach":	@"Dude, I'm skinny dipping in the ocean at name.",
           @"Surf Spot":	@"Dude, I'm surfing at name.",
           @"Botanical Garden":	@"Dude, I'm walking around at name.",
           @"Bridge":	@"Dude, I'm crossing a bridge at name.",
           @"Campground":	@"Dude, I'm camping at name.",
           @"Castle":	@"Dude, I'm at name.",
           @"Cemetery":	@"Dude, I'm mourning at name.",
           @"Dive Spot":	@"Dude, I'm diving at name.",
           @"Dog Run":	@"Dude, I'm walking my dog at name.",
           @"Farm":	@"Dude, I'm with animals at name.",
           @"Field":	@"Dude, I'm having fun at name.",
           @"Fishing Spot":	@"Dude, I'm fishing at name.",
           @"Forest":	@"Dude, I'm enjoying nature at name.",
           @"Garden":	@"Dude, I'm walking around at name.",
           @"Gun Range":	@"Dude, I'm learning to shoot at name.",
           @"Harbor / Marina":	@"Dude, I'm on a boat at name.",
           @"Hot Spring":	@"Dude, I'm enjoying nature at name.",
           @"Island":	@"Dude, I'm enjoying nature at name.",
           @"Lake":	@"Dude, I'm at name.",
           @"Lighthouse":	@"Dude, I'm signaling boats at name.",
           @"Mountain":	@"Dude, I'm at name.",
           @"National Park":	@"Dude, I'm breathing fresh air at name.",
           @"Nature Preserve":	@"Dude, I'm enjoying nature at name.",
           @"Other Great Outdoors":	@"Dude, I'm breathing fresh air at name.",
           @"Palace":	@"Dude, I'm at name.",
           @"Park":	@"Dude, I'm breathing fresh air in a city at name.",
           @"Pedestrian Plaza":	@"Dude, I'm walking around at name.",
           @"Playground":	@"Dude, I'm having fun at name.",
           @"Plaza":	@"Dude, I'm at name.",
           @"Pool":	@"Dude, I'm swimming at name.",
           @"Rafting":	@"Dude, I'm rafting at name.",
           @"Recreation Center":	@"Dude, I'm having fun at name.",
           @"River":	@"Dude, I'm at name.",
           @"Rock Climbing Spot":	@"Dude, I'm rock climbing at name.",
           @"Scenic Lookout":	@"Dude, I'm enjoying the view at name.",
           @"Sculpture Garden":	@"Dude, I'm contemplating sculptures at name.",
           @"Ski Area":	@"Dude, I'm skiing at name.",
           @"Apres Ski Bar":	@"Dude, I'm relaxing at name.",
           @"Ski Chairlift":	@"Dude, I'm skiing at name.",
           @"Ski Chalet":	@"Dude, I'm relaxing at name.",
           @"Ski Lodge":	@"Dude, I'm relaxing at name.",
           @"Ski Trail":	@"Dude, I'm skiing at name.",
           @"Stables":	@"Dude, I'm looking at horses at name.",
           @"States & Municipalities":	@"Dude, I'm at name.",
           @"City":	@"Dude, I'm at name.",
           @"County":	@"Dude, I'm at name.",
           @"Country":	@"Dude, I'm at name.",
           @"Neighborhood":	@"Dude, I'm at name.",
           @"State":	@"Dude, I'm at name.",
           @"Town":	@"Dude, I'm at name.",
           @"Village":	@"Dude, I'm at name.",
           @"Summer Camp":	@"Dude, I'm having fun camping at name.",
           @"Trail":	@"Dude, I'm hiking at name.",
           @"Tree":	@"Dude, I'm enjoying nature at name.",
           @"Vineyard":	@"Dude, I'm enjoying vine at name.",
           @"Volcano":	@"Dude, I'm hiking at name.",
           @"Well":	@"Dude, I'm getting some water at name.",
           @"Professional & Other Places":	@"Dude, I'm at name.",
           @"Animal Shelter":	@"Dude, I'm adopting a pet at name.",
           @"Auditorium":	@"Dude, I'm at name.",
           @"Building":	@"Dude, I'm at name.",
           @"Club House":	@"Dude, I'm hanging out at name.",
           @"Community Center":	@"Dude, I'm socializing at name.",
           @"Convention Center":	@"Dude, I'm participating in a convention at name.",
           @"Meeting Room":	@"Dude, I'm in a meeting at name.",
           @"Cultural Center":	@"Dude, I'm cultivating my knowledge at name.",
           @"Distribution Center":	@"Dude, I'm at name.",
           @"Event Space":	@"Dude, I'm at name.",
           @"Factory":	@"Dude, I'm making stuff at name.",
           @"Fair":	@"Dude, I'm having fun at name.",
           @"Funeral Home":	@"Dude, I'm mourning at name.",
           @"Government Building":	@"Dude, I'm at name.",
           @"Capitol Building":	@"Dude, I'm at name.",
           @"City Hall":	@"Dude, I'm at name.",
           @"Courthouse":	@"Dude, I'm at name.",
           @"Embassy / Consulate":	@"Dude, I'm managing my nationality at name.",
           @"Fire Station":	@"Dude, I'm reporting a fire at name.",
           @"Monument / Landmark":	@"Dude, I'm visiting a monument at name.",
           @"Police Station":	@"Dude, I'm reporting a crime at name.",
           @"Town Hall":	@"Dude, I'm dealing with legal stuff at name.",
           @"Library":	@"Dude, I'm reading at name.",
           @"Medical Center":	@"Dude, I'm being healed at name.",
           @"Acupuncturist":	@"Dude, I'm relaxing at name.",
           @"Alternative Healer":	@"Dude, I'm getting healed in an unconventional at name.",
           @"Chiropractor":	@"Dude, I'm getting my back fixed at name.",
           @"Dentist's Office":	@"Dude, I'm getting my teeth looked checked at name.",
           @"Doctor's Office":	@"Dude, I'm having a general check-up at name.",
           @"Emergency Room":	@"Dude, I'm being treated at name.",
           @"Eye Doctor":	@"Dude, I'm getting my eye looked checked at name.",
           @"Hospital":	@"Dude, I'm being healed at name.",
           @"Laboratory":	@"Dude, I'm exploring science at name.",
           @"Mental Health Office":	@"Dude, I'm evaluating peoples mental health at name.",
           @"Veterinarian":	@"Dude, I'm healing animals at name.",
           @"Military Base":	@"Dude, I'm defending my country at name.",
           @"Non-Profit":	@"Dude, I'm helping the world at name.",
           @"Office":	@"Dude, I'm working at name.",
           @"Advertising Agency":	@"Dude, I'm working on advertisement at name.",
           @"Campaign Office":	@"Dude, I'm campaigning at name.",
           @"Conference Room":	@"Dude, I'm participating in a conference at name.",
           @"Coworking Space":	@"Dude, I'm working at name.",
           @"Tech Startup":	@"Dude, I'm checking out a startup at name.",
           @"Parking":	@"Dude, I'm parking my car at name.",
           @"Post Office":	@"Dude, I'm mailing a letter at name.",
           @"Prison":	@"Dude, I'm paying for breaking the law at name.",
           @"Radio Station":	@"Dude, I'm broadcasting music at name.",
           @"Recruiting Agency":	@"Dude, I'm getting a new job at name.",
           @"School":	@"Dude, I'm learning stuff at name.",
           @"Circus School":	@"Dude, I'm learning to entertain people at name.",
           @"Driving School":	@"Dude, I'm learning to drive at name.",
           @"Elementary School":	@"Dude, I'm learning stuff at name.",
           @"Flight School":	@"Dude, I'm learning to fly at name.",
           @"High School":	@"Dude, I'm learning stuff at name.",
           @"Language School":	@"Dude, I'm learning a new language at name.",
           @"Middle School":	@"Dude, I'm learning stuff at name.",
           @"Music School":	@"Dude, I'm learning music at name.",
           @"Nursery School":	@"Dude, I'm dropping off my kids at name.",
           @"Preschool":	@"Dude, I'm dropping off my kids at name.",
           @"Private School":	@"Dude, I'm learning stuff at name.",
           @"Religious School":	@"Dude, I'm learning theology at name.",
           @"Swim School":	@"Dude, I'm learning to swim at name.",
           @"Social Club":	@"Dude, I'm socializing at name.",
           @"Spiritual Center":	@"Dude, I'm obliging by my religious duties at name.",
           @"Buddhist Temple":	@"Dude, I'm obliging by my religious duties at name.",
           @"Church":	@"Dude, I'm obliging by my religious duties at name.",
           @"Hindu Temple":	@"Dude, I'm obliging by my religious duties at name.",
           @"Monastery":	@"Dude, I'm obliging by my religious duties at name.",
           @"Mosque":	@"Dude, I'm obliging by my religious duties at name.",
           @"Prayer Room":	@"Dude, I'm obliging by my religious duties at name.",
           @"Shrine":	@"Dude, I'm obliging by my religious duties at name.",
           @"Synagogue":	@"Dude, I'm obliging by my religious duties at name.",
           @"Temple":	@"Dude, I'm obliging by my religious duties at name.",
           @"TV Station":	@"Dude, I'm broadcasting on a TV network at name.",
           @"Voting Booth":	@"Dude, I'm voting at name.",
           @"Warehouse":	@"Dude, I'm at name.",
           @"Residence":	@"Dude, I'm at home (name).",
           @"Assisted Living":	@"Dude, I'm at name.",
           @"Home (private)":	@"Dude, I'm at home (name).",
           @"Housing Development":	@"Dude, I'm checking out a house development at name.",
           @"Residential Building (Apartment / Condo)":	@"Dude, I'm at home (name).",
           @"Trailer Park":	@"Dude, I'm in a trailer at name.",
           @"Shop & Service":	@"Dude, I'm at name.",
           @"ATM": 	@"Dude, I'm withdrawing some cash at name.",
           @"Adult Boutique":	@"Dude, I'm buying adult toys at name.",
           @"Antique Shop":	@"Dude, I'm buying some antiques at name.",
           @"Arts & Crafts Store":	@"Dude, I'm getting some art & crafts supplies at name.",
           @"Astrologer":	@"Dude, I'm studying the stars at name.",
           @"Auto Garage":	@"Dude, I'm getting my car fixed at name.",
           @"Automotive Shop":	@"Dude, I'm checking out the latest car supplies at name.",
           @"Baby Store":	@"Dude, I'm getting some baby stuff at name.",
           @"Bank":	@"Dude, I'm managing my bank account at name.",
           @"Betting Shop":	@"Dude, I'm betting at name.",
           @"Big Box Store":	@"Dude, I'm shopping at name.",
           @"Bike Shop":	@"Dude, I'm buying some new bike gear at name.",
           @"Board Shop":	@"Dude, I'm at name.",
           @"Bookstore":	@"Dude, I'm buying a book at name.",
           @"Bridal Shop":	@"Dude, I'm preparing my wedding at name.",
           @"Business Service":	@"Dude, I'm getting business service at name.",
           @"Camera Store":	@"Dude, I'm buying a new camera at name.",
           @"Candy Store":	@"Dude, I'm buying some candy at name.",
           @"Car Dealership":	@"Dude, I'm buying a new car at name.",
           @"Car Wash":	@"Dude, I'm getting my car cleaned at name.",
           @"Carpet Store":	@"Dude, I'm getting some carpet laid down at name.",
           @"Check Cashing Service":	@"Dude, I'm cashing a check at name.",
           @"Chocolate Shop":	@"Dude, I'm buying some sweet chocolate at name.",
           @"Christmas Market":	@"Dude, I'm getting some christmas decorations at name.",
           @"Clothing Store":	@"Dude, I'm buying some clothes at name.",
           @"Accessories Store":	@"Dude, I'm getting some accessories at name.",
           @"Boutique":	@"Dude, I'm shopping at name.",
           @"Kids Store":	@"Dude, I'm buying some kids stuff at name.",
           @"Lingerie Store":	@"Dude, I'm buying lingerie at name.",
           @"Men's Store":	@"Dude, I'm some clothes at name.",
           @"Shoe Store":	@"Dude, I'm buying some shoes at name.",
           @"Women's Store":	@"Dude, I'm buying some clothes at name.",
           @"Comic Shop":	@"Dude, I'm getting some comics at name.",
           @"Construction & Landscaping":	@"Dude, I'm getting some construction supplies at name.",
           @"Convenience Store":	@"Dude, I'm shopping at name.",
           @"Cosmetics Shop":	@"Dude, I'm getting some cosmetics at name.",
           @"Costume Shop":	@"Dude, I'm getting some costumes at name.",
           @"Credit Union":	@"Dude, I'm withdrawing some cash at name.",
           @"Daycare":	@"Dude, I'm dropping off my kid at name.",
           @"Department Store":	@"Dude, I'm shopping at name.",
           @"Design Studio":	@"Dude, I'm designing some stuff at name.",
           @"Discount Store":	@"Dude, I'm buying discounted stuff at name.",
           @"Dive Shop":	@"Dude, I'm getting some diving gear at name.",
           @"Drugstore / Pharmacy":	@"Dude, I'm getting some medicine at name.",
           @"Dry Cleaner":	@"Dude, I'm getting my clothes dry cleaned at name.",
           @"EV Charging Station":	@"Dude, I'm charging up my car at name.",
           @"Electronics Store":	@"Dude, I'm getting some gadgets at name.",
           @"Event Service":	@"Dude, I'm planing an event at name.",
           @"Fabric Shop":	@"Dude, I'm buying some fabric at name.",
           @"Financial or Legal Service":	@"Dude, I'm getting legal advice at name.",
           @"Fireworks Store":	@"Dude, I'm buying some fireworks at name.",
           @"Fishing Store":	@"Dude, I'm buying some fishing supplies at name.",
           @"Flea Market":	@"Dude, I'm buying stuff at name.",
           @"Flower Shop":	@"Dude, I'm buying some flowers at name.",
           @"Food & Drink Shop":	@"Dude, I'm buying some groceries at name.",
           @"Beer Store":	@"Dude, I'm buying some beer at name.",
           @"Butcher":	@"Dude, I'm buying some meat at name.",
           @"Cheese Shop":	@"Dude, I'm buying some cheese at name.",
           @"Farmers Market":	@"Dude, I'm buying some organic produce at name.",
           @"Fish Market":	@"Dude, I'm buying some fish at name.",
           @"Food Court":	@"Dude, I'm eatingAction at name.",
           @"Gourmet Shop":	@"Dude, I'm at name.",
           @"Grocery Store":	@"Dude, I'm buying some groceries at name.",
           @"Health Food Store":	@"Dude, I'm at name.",
           @"Liquor Store":	@"Dude, I'm buying some adult beverages at name.",
           @"Organic Grocery":	@"Dude, I'm buying some organic groceries at name.",
           @"Street Food Gathering":	@"Dude, I'm getting some good food for eatingTime at name.",
           @"Supermarket":	@"Dude, I'm shopping at name.",
           @"Wine Shop":	@"Dude, I'm getting some wine at name.",
           @"Frame Store":	@"Dude, I'm getting my painting framed at name.",
           @"Fruit & Vegetable Store":	@"Dude, I'm buying groceries at name.",
           @"Furniture / Home Store":	@"Dude, I'm buying some furniture at name.",
           @"Gaming Cafe":	@"Dude, I'm gaming with some hot coffee at name.",
           @"Garden Center":	@"Dude, I'm buying garden supplies at name.",
           @"Gas Station / Garage":	@"Dude, I'm filling up with gas at name.",
           @"Gift Shop":	@"Dude, I'm buying a gift at name.",
           @"Gun Shop":	@"Dude, I'm exercising my right to keep & bear arms at name.",
           @"Gym / Fitness Center":	@"Dude, I'm working out at name.",
           @"Boxing Gym":	@"Dude, I'm boxing out at name.",
           @"Climbing Gym":	@"Dude, I'm climbing out at name.",
           @"Cycle Studio":	@"Dude, I'm cycling out at name.",
           @"Gym Pool":	@"Dude, I'm stretching out at name.",
           @"Gymnastics Gym":	@"Dude, I'm stretching out at name.",
           @"Gym": 	@"Dude, I'm working out at name.",
           @"Martial Arts Dojo":	@"Dude, I'm training to kill at name.",
           @"Track":	@"Dude, I'm running at name.",
           @"Yoga Studio":	@"Dude, I'm doing some yoga at name.",
           @"Hardware Store":	@"Dude, I'm buying some tools at name.",
           @"Health & Beauty Service":	@"Dude, I'm at name.",
           @"Herbs & Spices Store":	@"Dude, I'm buying some spices at name.",
           @"Hobby Shop":	@"Dude, I'm having fun at name.",
           @"Home Service":	@"Dude, I'm at name.",
           @"Hunting Supply":	@"Dude, I'm getting some hunting supplies at name.",
           @"IT Services":	@"Dude, I'm getting some IT help at name.",
           @"Internet Cafe":	@"Dude, I'm drinking some coffee while surfing the web at name.",
           @"Jewelry Store":	@"Dude, I'm buying some jewelry at name.",
           @"Knitting Store":	@"Dude, I'm buying some knitting equipment at name.",
           @"Laundromat":	@"Dude, I'm cleaning some clothes at name.",
           @"Laundry Service":	@"Dude, I'm getting some clothes cleaned at name.",
           @"Lawyer":	@"Dude, I'm getting some advice at name.",
           @"Leather Goods Store":	@"Dude, I'm buying some leather goods at name.",
           @"Locksmith":	@"Dude, I'm getting new locks at name.",
           @"Lottery Retailer":	@"Dude, I'm buying some lottery tickets at name.",
           @"Luggage Store":	@"Dude, I'm buying some luggage at name.",
           @"Mall":	@"Dude, I'm buying stuff at name.",
           @"Marijuana Dispensary":	@"Dude, I'm getting some weed at name.",
           @"Market":	@"Dude, I'm buying food for eatingTime at name.",
           @"Massage Studio":	@"Dude, I'm getting a massage at name.",
           @"Mattress Store":	@"Dude, I'm checking out some mattresses at name.",
           @"Miscellaneous Shop":	@"Dude, I'm buying something at name.",
           @"Mobile Phone Shop":	@"Dude, I'm buying a new phone at name.",
           @"Motorcycle Shop":	@"Dude, I'm checking out some motorcycles at name.",
           @"Music Store":	@"Dude, I'm buying some music at name.",
           @"Nail Salon":	@"Dude, I'm getting pampered at name.",
           @"Newsstand":	@"Dude, I'm getting the latest news at name.",
           @"Optical Shop":	@"Dude, I'm buying glasses at name.",
           @"Other Repair Shop":	@"Dude, I'm repairing something at name.",
           @"Outdoor Supply Store":	@"Dude, I'm buying outdoor supplies at name.",
           @"Outlet Store":	@"Dude, I'm buying stuff at name.",
           @"Paper / Office Supplies Store":	@"Dude, I'm buying some office supplies at name.",
           @"Pawn Shop":	@"Dude, I'm at name.",
           @"Perfume Shop":	@"Dude, I'm buying some perfume at name.",
           @"Pet Service":	@"Dude, I'm pampering my pet at name.",
           @"Pet Store":	@"Dude, I'm buying a pet at name.",
           @"Photography Lab":	@"Dude, I'm developing some photos at name.",
           @"Piercing Parlor":	@"Dude, I'm getting a piercing at name.",
           @"Pop-Up Shop":	@"Dude, I'm at name.",
           @"Print Shop":	@"Dude, I'm printing stuff at name.",
           @"Real Estate Office":	@"Dude, I'm looking for a house at name.",
           @"Record Shop":	@"Dude, I'm buying some records at name.",
           @"Recording Studio":	@"Dude, I'm recording my next hit at name.",
           @"Recycling Facility":	@"Dude, I'm being eco-friendly at name.",
           @"Salon / Barbershop":	@"Dude, I'm getting a haircut at name.",
           @"Shipping Store":	@"Dude, I'm at name.",
           @"Shoe Repair":	@"Dude, I'm getting my shoes fixed at name.",
           @"Smoke Shop":	@"Dude, I'm at name.",
           @"Smoothie Shop":	@"Dude, I'm getting a smoothie at name.",
           @"Souvenir Shop":	@"Dude, I'm getting a souvenir at name.",
           @"Spa": 	@"Dude, I'm really relaxing at name.",
           @"Sporting Goods Shop":	@"Dude, I'm buying sporting goods at name.",
           @"Stationery Store":	@"Dude, I'm buying things at name.",
           @"Storage Facility":	@"Dude, I'm storing stuff at name.",
           @"Tailor Shop":	@"Dude, I'm getting some clothes fitted at name.",
           @"Tanning Salon":	@"Dude, I'm tanning at name.",
           @"Tattoo Parlor":	@"Dude, I'm getting a tattoo at name.",
           @"Thrift / Vintage Store":	@"Dude, I'm buying some stuff at name.",
           @"Toy / Game Store":	@"Dude, I'm buying some toys at name.",
           @"Travel Agency":	@"Dude, I'm looking into my next vacation at name.",
           @"Used Bookstore":	@"Dude, I'm buying a used book at name.",
           @"Video Game Store":	@"Dude, I'm buying a video game at name.",
           @"Video Store":	@"Dude, I'm renting a movie at name.",
           @"Warehouse Store":	@"Dude, I'm at name.",
           @"Watch Repair Shop":	@"Dude, I'm repairing my watch at name.",
           @"Travel & Transport":	@"Dude, I'm at name.",
           @"Airport":	@"Dude, I'm at name.",
           @"Airport Food Court":	@"Dude, I'm eating while I wait to board at name.",
           @"Airport Gate":	@"Dude, I'm boarding at name.",
           @"Airport Lounge":	@"Dude, I'm waiting for boarding to start at name.",
           @"Airport Terminal":	@"Dude, I'm checking-in my flight at name.",
           @"Airport Tram":	@"Dude, I'm taking the tram at name.",
           @"Plane":	@"Dude, I'm on a plane at name.",
           @"Bike Rental / Bike Share":	@"Dude, I'm renting a bike at name.",
           @"Boat or Ferry":	@"Dude, I'm on a boat at name.",
           @"Border Crossing":	@"Dude, I'm crossing a border at name.",
           @"Bus Station":	@"Dude, I'm waiting for the bus at name.",
           @"Bus Line":	@"Dude, I'm on the bus at name.",
           @"Bus Stop":	@"Dude, I'm waiting for the bus at name.",
           @"Cable Car":	@"Dude, I'm enjoying the view from name.",
           @"General Travel":	@"Dude, I'm at name.",
           @"Hotel":	@"Dude, I'm at name.",
           @"Bed & Breakfast":	@"Dude, I'm relaxing at name.",
           @"Boarding House":	@"Dude, I'm at name.",
           @"Hostel":	@"Dude, I'm relaxing at name.",
           @"Hotel Pool":	@"Dude, I'm swimming at name.",
           @"Motel":	@"Dude, I'm relaxing at name.",
           @"Resort":	@"Dude, I'm on vacation at name.",
           @"Roof Deck":	@"Dude, I'm at name.",
           @"Intersection":	@"Dude, I'm driving at name.",
           @"Light Rail":	@"Dude, I'm at name.",
           @"Moving Target":	@"Dude, I'm shooting at name.",
           @"Pier":	@"Dude, I'm enjoying the water at name.",
           @"RV Park":	@"Dude, I'm in my RV at name.",
           @"Rental Car Location":	@"Dude, I'm renting a car at name.",
           @"Rest Area":	@"Dude, I'm resting at name.",
           @"Road":	@"Dude, I'm at name.",
           @"Street":	@"Dude, I'm at name.",
           @"Subway":	@"Dude, I'm in the subway at name.",
           @"Taxi Stand":	@"Dude, I'm waiting for a taxi at name.",
           @"Taxi":	@"Dude, I'm in a taxi at name.",
           @"Toll Booth":	@"Dude, I'm at name.",
           @"Toll Plaza":	@"Dude, I'm at name.",
           @"Tourist Information Center":	@"Dude, I'm getting info. at name.",
           @"Train Station":	@"Dude, I'm waiting for a train at name.",
           @"Platform":	@"Dude, I'm waiting for a train at name.",
           @"Train":	@"Dude, I'm in a train at name.",
           @"Tram":	@"Dude, I'm in a tram at name.",
           @"Transportation Service":	@"Dude, I'm moving from one place to another at name.",
           @"Travel Lounge":	@"Dude, I'm waiting to travel at name.",
           @"Tunnel":	@"Dude, I'm driving through name."
           };
}

@end