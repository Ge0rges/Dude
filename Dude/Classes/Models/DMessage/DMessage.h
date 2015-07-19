//
//  DMessage.h
//  
//
//  Created by Georges Kanaan on 6/17/15.
//
//

// Frameworks
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


typedef NS_ENUM(NSInteger, DMessageType) {
  DMessageTypeMessage = 0,
  DMessageTypeURL,
  DMessageTypeLocation,
};

@interface DMessage : NSObject <NSCoding>

@property (strong, nonatomic, readonly) NSString *message;// The full message string (Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic, readonly) NSString *notificationMessage;// The string to be used for notifications (Gio: Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic, readonly) NSString *notificationTitle;// The string to be used for notification titles (Gio - Message/Link/'s Location)
@property (strong, nonatomic, readonly) NSString *venueName;// The string to be used for notification titles (Itsu)

@property (strong, nonatomic, readonly) NSString *lastSeen;// The last seen to be used for this message (Eating sushi for lunch at Itsu, London)

@property (strong, nonatomic, readonly) NSURL *URL;// The URL associted with message (http://itsu.com)
@property (strong, nonatomic, readonly) NSURL *imageURL;// The URL for the image associted with message (category or venue)

@property (strong, nonatomic, readonly) CLLocation *location;// The location of the sender
@property (strong, nonatomic, readonly) NSString *locationCity;// The city of the sender (London)

@property (strong, nonatomic, readonly) NSString *category;// The 4sq category from which it was generated (Sushi Restaurant)

@property (nonatomic, readonly) DMessageType type;// What kind of message is this

- (instancetype)initWithCategory:(NSString*)messageCategory location:(CLLocation*)messageLocation venueName:(NSString*)messageVenueName venueCity:(NSString*)messageLocationCity image:(NSString*)imageURLString;
- (instancetype)initForPasteboardURLWithLocation:(CLLocation*)messageLocation;
- (instancetype)initForLocation:(CLLocation*)messageLocation venueCity:(NSString*)messageLocationCity;

@end
