//
//  FBUserTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import <UIKit/UIKit.h>
#import "FBUsers.h"

@interface FBUserTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelUserName;
@property (weak, nonatomic) IBOutlet UIImageView *imageProfile;
@property (nonatomic, strong) PFObject *broadcast;

- (void)populateCellWithFBUser:(FBUsers *)user;
@end
