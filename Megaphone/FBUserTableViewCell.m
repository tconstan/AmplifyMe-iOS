//
//  FBUserTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import "FBUserTableViewCell.h"
#import "Notification.h"
#import "Logger.h"

@interface FBUserTableViewCell () <NSURLConnectionDelegate>

@property (nonatomic, strong) PFFile *file;
@property (nonatomic, strong) NSMutableData *imageData;
@property (weak, nonatomic) IBOutlet UIButton *buttonInviteFriend;
@property (nonatomic, strong) FBUsers *fbUser;

@end

@implementation FBUserTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)populateCellWithFBUser:(FBUsers *)user {
    self.fbUser = user;
    self.labelUserName.text = user.username;
    [self updateInviteButton];
    NSURL *pictureURL = [NSURL URLWithString:user.profileImageUrl];
    [self loadProfilePictureWithUrl:pictureURL];
}

- (void)updateInviteButton {
    NSMutableArray *allNotifications = [self.broadcast objectForKey:@"notifications"];
    for (NSDictionary *notification in allNotifications) {
        if ([[notification objectForKey:@"username"] isEqualToString:self.fbUser.username]) {
            self.buttonInviteFriend.hidden = YES;
        }
    }
}

- (void)loadProfilePictureWithUrl:(NSURL *)url {
    NSURL *pictureURL = url;
    
    self.imageData = [NSMutableData data];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:2.0f];
    
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    if (!urlConnection) {
        NSLog(@"Failed to download picture");
    }
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.imageProfile.image = [UIImage imageWithData:self.imageData];
    self.imageProfile.layer.masksToBounds = YES;
}

#pragma mark - IBAction

- (IBAction)actionSelectInviteFBFriend:(id)sender {
    self.buttonInviteFriend.hidden = YES;
    
    NSDictionary *notification = @{@"username": self.fbUser.username,
                                   @"string": self.fbUser.userId,
                                   @"message": [NSString stringWithFormat:@"%@ invited you to the event %@", [[PFUser currentUser] objectForKey:@"nickname"], self.broadcast[@"title"]],
                                   @"title" : self.broadcast[@"title"],
                                   @"eventInvitee" : [[PFUser currentUser] objectForKey:@"nickname"],
                                   @"eventPhotoPFFile" : [self.broadcast[@"images"] objectAtIndex:0],
                                   @"type" : @"Invite",
                                   @"dateCreated" : [NSDate date]};
    
    [self.broadcast addObject:notification forKey:@"notifications"];
    
    [self.broadcast saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [Logger handleError:error];
        }
    }];
}

@end
