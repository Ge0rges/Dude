//
//  Constants.h
//
//
//  Created by Georges Kanaan on 6/2/15.
//
//

#import "NSStringExtensions.h"
#import "QNSURLConnection.h"

#define WatchContactsKey @"favoriteContactsArray"// receiving key for contacts array
#define WatchMessagesKey @"messagesArray"// receiving key for messages array

#define WatchRequestTypeKey @"requestType"// Key for the request values to be assigned to
#define WatchRequestMessagesValue @"requestMessages"// request value for messages
#define WatchRequestSendMessageValue @"sendMessage"// request value for sending a message

// Encoding keys
NSString* const ProfileImageKey = @"Picture";
NSString* const BlockedContactsKey = @"BlockedContacts";
NSString* const ContactsKey = @"Contacts";
NSString* const FavouriteContactsKey = @"FavoriteContacts";
NSString* const LastSeensKey = @"LastSeens";
NSString* const FullNameKey = @"fullName";
