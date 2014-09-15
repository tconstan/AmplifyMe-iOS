//
//  NotificationsTableViewController.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import <UIKit/UIKit.h>


@interface NotificationsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, strong) NSArray *broadcasts;
@property (nonatomic, strong) NSDate *lastTimeChecked;

@end
