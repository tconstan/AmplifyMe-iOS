//
//  AttendingUsersTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import <UIKit/UIKit.h>

@interface AttendingUsersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelUserName;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewUser;

- (void)populateCellWithUser:(PFUser *)user;

@end
