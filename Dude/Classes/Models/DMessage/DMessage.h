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

@property (nonatomic) BOOL includeLocation;

@property (strong, nonatomic, readonly) NSString * _Nonnull message;// The full message string (Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic, readonly) NSString * _Nonnull notificationMessage;// The string to be used for notifications (Gio: Dude, I'm eating sushi for lunch at Itsu.)
@property (strong, nonatomic, readonly) NSString * _Nonnull notificationTitle;// The string to be used for notification titles (Gio - Message/Link/'s Location)
@property (strong, nonatomic, readonly) NSString * _Nonnull venueName;// The string to be used for venue reference (Itsu)

@property (strong, nonatomic, readonly) NSString * _Nonnull lastSeen;// The last seen to be used for this message (Eating sushi for lunch at Itsu)

@property (strong, nonatomic, readonly) NSURL * _Nonnull URL;// The URL associted with message (http://itsu.com)
@property (strong, nonatomic, readonly) NSURL * _Nonnull imageURL;// The URL for the image associted with message (category or venue)

@property (strong, nonatomic, readonly) CLLocation * _Nonnull location;// The location of the sender
@property (strong, nonatomic, readonly) NSString * _Nonnull city;// The city of the sender (London)

@property (strong, nonatomic, readonly) NSString * _Nonnull category;// The 4sq category from which it was generated (Sushi Restaurant)

@property (strong, nonatomic) NSDate * _Nonnull sendDate;// The date when the message was *sent*
@property (strong, nonatomic, readonly) NSString * _Nonnull timestamp; // The timestamp to show for this message
@property (nonatomic, readonly) DMessageType type;// What kind of message is this

@property (strong, nonatomic, readonly) NSData * _Nonnull senderRecordIDData;
@property (strong, nonatomic, readonly) NSString * _Nonnull senderFullName;

- (instancetype _Nullable)initWithCategory:(NSString* _Nonnull)messageCategory location:(CLLocation* _Nonnull)messageLocation venueName:(NSString* _Nonnull)messageVenueName venueCity:(NSString* _Nonnull)messageLocationCity imageURL:(NSString* _Nonnull)imageURLString;
- (instancetype _Nullable)initURLMessageWithLocation:(CLLocation* _Nonnull)messageLocation venueCity:(NSString* _Nonnull)messageLocationCity;
- (instancetype _Nullable)initLocationMessage:(CLLocation* _Nonnull)messageLocation venueCity:(NSString* _Nonnull)messageLocationCity;

@end
