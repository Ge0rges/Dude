//
//  QNSURLConnection.h
//  Dude
//
//  Created by Georges Kanaan on 19/09/2015.
//  Copyright © 2015 Georges Kanaan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QNSURLConnection : NSObject

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(__autoreleasing NSURLResponse **)responsePtr error:(__autoreleasing NSError **)errorPtr;

@end
