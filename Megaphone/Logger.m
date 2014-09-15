#import "Logger.h"

@implementation Logger

+ (instancetype)sharedLogger {
    static dispatch_once_t once;
    static Logger *logger;
    
    dispatch_once(&once, ^{
        logger = [[self alloc] init];
    });
    
    return logger;
}

+ (void)handleError:(NSError *)error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh oh, something went wrong"
                                                        message:@"Check that you have a valid wifi or 3G connection"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [self logError:error];
    [alertView show];
}

+ (void)logError:(NSError *)error {
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Message: %@", [error localizedFailureReason]);
}

@end
