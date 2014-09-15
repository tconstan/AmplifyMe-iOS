//
//  AttendingUsersTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import "AttendingUsersTableViewCell.h"

@interface AttendingUsersTableViewCell () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSMutableData *imageData;

@end

@implementation AttendingUsersTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)populateCellWithUser:(PFUser *)user {
    NSDictionary *userInfo = [user objectForKey:@"profile"];
    
    self.labelUserName.text = [userInfo objectForKey:@"name"];
    
    NSURL *pictureURL = [NSURL URLWithString:[userInfo objectForKey:@"pictureURL"]];
    [self loadProfilePictureWithUrl:pictureURL];
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
    self.imageViewUser.image = [UIImage imageWithData:self.imageData];
    self.imageViewUser.layer.masksToBounds = YES;
}

@end
