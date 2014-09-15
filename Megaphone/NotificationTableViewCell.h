//
//  NotificationTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import <UIKit/UIKit.h>

@class NotificationTableViewCell;

@protocol NotificationTableViewCellDelegate <NSObject>

- (void)performSegueForNotification:(NotificationTableViewCell *)sender withTitle:(NSString *)title;

@end

@interface NotificationTableViewCell : UITableViewCell

@property (nonatomic, weak) id <NotificationTableViewCellDelegate> delegate;

- (void)populateCellWithInfo:(NSDictionary *)dict;

@end
