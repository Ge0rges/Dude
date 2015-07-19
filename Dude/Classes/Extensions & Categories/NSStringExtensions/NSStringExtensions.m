//
//  NSStringExtensions.m
//  Dude
//
//  Created by Georges Kanaan on 3/28/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "NSStringExtensions.h"

@implementation NSString (BetweenCategory)

- (NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end {
    NSRange startRange = [self rangeOfString:start];
    if (startRange.location != NSNotFound) {
        NSRange targetRange;
        targetRange.location = startRange.location + startRange.length;
        targetRange.length = [self length] - targetRange.location;
        NSRange endRange = [self rangeOfString:end options:0 range:targetRange];
        if (endRange.location != NSNotFound) {
            targetRange.length = endRange.location - targetRange.location;
            return [self substringWithRange:targetRange];
        }
    }
    return nil;
}

@end
