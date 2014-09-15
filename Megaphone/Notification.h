//
//  Notification.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import <Foundation/Foundation.h>

@interface Notification : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSDate *dateCreated;

@end
