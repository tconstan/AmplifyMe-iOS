//
//  BaseUtils.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-11.
//
//

#import <Foundation/Foundation.h>

@interface BaseUtils : NSObject

+ (NSString*)formatAttendingStringWithArray:(NSMutableArray *)inputArray;
+ (NSString*)formatAttendingStringWithArrayForCondensedString:(NSMutableArray *)inputArray;
+ (void)styleNavigationBar:(UINavigationBar *)navBar;
+ (NSDateFormatter *)loadDateFormatterForDate:(NSDate *)date addPrefix:(BOOL)addPrefix;
+ (NSDictionary*)parseURLParams:(NSString *)query;
+ (UIImage *)createIcon: (UIImage *)image iconSize:(int)size;
+ (UIImage *)fixOrientationForImage:(UIImage *)image;

@end
