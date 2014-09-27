#import "UserViewController.h"
#import "MPTabBarController.h"
#import "BaseUtils.h"
#import "MButton.h"
#import "UIColor+Megaphone.h"
#import "Logger.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface UserViewController () <NSURLConnectionDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) NSMutableData *imageData;
@property (weak, nonatomic) IBOutlet MButton *buttonLogout;
@property (weak, nonatomic) IBOutlet MButton *buttonDeleteAccount;
@property (weak, nonatomic) IBOutlet UISwitch *switchCheckIn;
@property (weak, nonatomic) IBOutlet UISwitch *switchAutoPostToFB;

@end

@implementation UserViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateView];
    
    if ([PFUser currentUser]) {
        [self updateProfile];
    }
    
    [self fetchProfile];
    [BaseUtils styleNavigationBar:self.navigationController.navigationBar];
}

- (void)fetchProfile {
    FBRequest *request = [FBRequest requestForMe];
    
    [request startWithCompletionHandler:^(FBRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            NSDictionary *userData = (NSDictionary *)result;
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:7];
            
            if (facebookID) {
                userProfile[@"facebookId"] = facebookID;
            }
            
            if (userData[@"name"]) {
                userProfile[@"name"] = userData[@"name"];
            }
            
            if (userData[@"location"][@"name"]) {
                userProfile[@"location"] = userData[@"location"][@"name"];
            }
            
            if (userData[@"gender"]) {
                userProfile[@"gender"] = userData[@"gender"];
            }
            
            if ([pictureURL absoluteString]) {
                userProfile[@"pictureURL"] = [pictureURL absoluteString];
            }
            
            [[PFUser currentUser] setObject:userProfile[@"name"] forKey:@"nickname"];
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            [[PFUser currentUser] saveInBackground];
            
            [self updateProfile];
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            [self logoutTapped:nil];
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

- (void)updateProfile {
    if ([[PFUser currentUser] objectForKey:@"profile"][@"name"]) {
        self.nameLabel.text = [[PFUser currentUser] objectForKey:@"profile"][@"name"];
    }
    
    self.imageData = [NSMutableData data];
    if ([[PFUser currentUser] objectForKey:@"profile"][@"pictureURL"]) {
        NSURL *pictureURL = [NSURL URLWithString:[[PFUser currentUser] objectForKey:@"profile"][@"pictureURL"]];
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:2.0f];
        
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        if (!urlConnection) {
            NSLog(@"Failed to download picture");
        }
    }
}

- (void)updateView {
    [self.buttonLogout setTintColor:[UIColor defaultFacebookColor]];
    [self.buttonLogout showShadowAtBottom];
    [self.buttonDeleteAccount setTintColor:[UIColor defaultOrangeColor]];
    [self.buttonDeleteAccount showShadowAtBottom];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *checkIn = [defaults objectForKey:@"autoCheckInEnabled"];
    if ([checkIn isEqualToString:@"YES"]) {
        [self.switchCheckIn setOn:YES];
    } else {
        [self.switchCheckIn setOn:NO];
    }
    
    NSString *autoFBPost = [defaults objectForKey:@"autoFBPostEnabled"];
    if ([autoFBPost isEqualToString:@"YES"]) {
        [self.switchAutoPostToFB setOn:YES];
    } else {
        [self.switchAutoPostToFB setOn:NO];
    }
}

#pragma mark - IBActions

- (IBAction)switchAutoCheckInToggled:(id)sender {
    if ([sender isOn]) {
        [self.switchCheckIn setOn:YES animated:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *checkIn = @"YES";
        [defaults setObject:checkIn forKey:@"autoCheckInEnabled"];
    } else {
        [self.switchCheckIn setOn:NO animated:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *checkIn = @"NO";
        [defaults setObject:checkIn forKey:@"autoCheckInEnabled"];
    }
}

- (IBAction)switchAutoPostToFBToggled:(id)sender {
    if ([sender isOn]) {
        if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
            
            NSLog(@"No Permissions");
            [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't authorize", nil)
                                                                    message:NSLocalizedString(@"Seems like something went wrong in authorizing automatic posting, try again later", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles: nil];
                    [alert show];
                }
            }];
        }
        [self.switchAutoPostToFB setOn:YES animated:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *postToFB = @"YES";
        [defaults setObject:postToFB forKey:@"autoFBPostEnabled"];
    } else {
        [self.switchAutoPostToFB setOn:NO animated:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *postToFB = @"NO";
        [defaults setObject:postToFB forKey:@"autoFBPostEnabled"];
    }
}

- (IBAction)logoutTapped:(id)sender {
    MPTabBarController *tabBarController = (MPTabBarController *)self.tabBarController;
    [tabBarController logOut];
}

- (IBAction)deleteTapped:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete AmplifyMe Account?", nil)
                                                    message:NSLocalizedString(@"Deleting your account is instant and permanent, are you sure?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                          otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
    [alert show];
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.userImageView.image = [UIImage imageWithData:self.imageData];
    self.userImageView.layer.cornerRadius = 60.0f;
    self.userImageView.layer.masksToBounds = YES;
}

#pragma mark - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (error) {
                [Logger handleError:error];
            } else {
                [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        [Logger handleError:error];
                    } else {
                        MPTabBarController *tabBarController = (MPTabBarController *)self.tabBarController;
                        [tabBarController logOut];
                    }
                }];
            }
        }];
    }
}

@end
