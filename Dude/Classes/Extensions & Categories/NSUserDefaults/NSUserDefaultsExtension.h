//
//  NSUserDefaultsExtension.h
//  Dude
//
//  Created by Georges Kanaan on 27/08/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSUserDefaults (CloudKit)
- (void)setCKObject:(id)value forKey:(NSString *)defaultName;
- (id)CKObjectForKey:(NSString *)defaultName;

@end
