#import <Foundation/Foundation.h>

@interface Logger : NSObject

+ (instancetype)sharedLogger;

+ (void)handleError:(NSError *)error;

@end
