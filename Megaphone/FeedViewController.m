#import "FeedViewController.h"
#import "BroadcastCell.h"
#import "BroadcastDetailViewController.h"
#import "BeaconService.h"
#import "BaseUtils.h"
#import "NotificationsTableViewController.h"
#import "FBUsers.h"
#import "UIColor+Megaphone.h"
#import "Logger.h"
#import "UserViewController.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <Parse/Parse.h>

@interface FeedViewController () <BeaconServiceObserver, BeaconServiceDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *broadcasts;
@property (nonatomic, strong) CLLocation *lastFetchedLocation;
@property (weak, nonatomic) IBOutlet UIButton *leftBarButton;
@property (weak, nonatomic) IBOutlet UIButton *rightBarButton;

@property (nonatomic, strong) MBProgressHUD *progressView;
@property (nonatomic, strong) PFGeoPoint *userGeoPoint;
@property (nonatomic, strong) PFObject *currentBroadcastToUpdate;

@property (nonatomic, strong) NSMutableArray *facebookFriends;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, strong) NSDate *lastTimeChecked;
@property (nonatomic) NSInteger newNotificationCount;

@property (nonatomic) BOOL isFirstLaunch;
@property (nonatomic) BOOL isAutoCheckInEnabled;
@property (nonatomic) BOOL askToCheckIn;
@property (nonatomic) BOOL checkInCalled;

@end

@implementation FeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.askToCheckIn = YES;
    
    self.isFirstLaunch = YES;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
    
    [BaseUtils styleNavigationBar:self.navigationController.navigationBar];
    self.facebookFriends = [[NSMutableArray alloc] init];
}

- (BOOL)isAuthenticated {
    return [PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    self.askToCheckIn = YES;
    [self updateData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (([self isAuthenticated])) {
        [self updateData];
        [[BeaconService sharedService] addObserver:self];
        [[BeaconService sharedService] startUpdatingLocation];
    }
}

- (void)updateData {
    self.progressView = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *checkIn = [defaults objectForKey:@"autoCheckInEnabled"];
    if ([checkIn isEqualToString:@"YES"]) {
        self.isAutoCheckInEnabled = YES;
    } else {
        self.isAutoCheckInEnabled = NO;
    }
    
    [self getFacebookFriends];
    [self fetchBroadcasts];
    self.lastTimeChecked= [[PFUser currentUser] objectForKey:@"lastDateCheckedNotifs"];
    [self updateNewNotificationsCount];
    
    [self.progressView hide:YES];
    [self.refreshControl endRefreshing];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[BeaconService sharedService] removeObserver:self];
}

- (void)service:(BeaconService *)service updatedLocation:(CLLocation *)location {
    if (self.lastFetchedLocation == nil && location != nil) {
        self.lastFetchedLocation = location;
        
        self.progressView.labelText = @"Listening...";
        self.progressView.mode = MBProgressHUDModeIndeterminate;
    } else if (location != nil && [self.lastFetchedLocation distanceFromLocation:location] > 200) {
        self.lastFetchedLocation = location;
    }
}

- (void)updateNewNotificationsCount {
    self.newNotificationCount = 0;
    for (NSDictionary *notification in self.notifications) {
        if ([self.lastTimeChecked compare:[notification objectForKey:@"dateCreated"]] == NSOrderedAscending) {
            self.newNotificationCount++;
        }
    }
    if (self.newNotificationCount > 0) {
        [self.leftBarButton setBackgroundImage:[UIImage imageNamed:@"notification_circle"]  forState:UIControlStateNormal];
        [self.leftBarButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.newNotificationCount] forState:UIControlStateNormal];
    } else {
        [self.leftBarButton setBackgroundImage:[UIImage imageNamed:@"white_globe_icon"]  forState:UIControlStateNormal];
        [self.leftBarButton setTitle:@"" forState:UIControlStateNormal];
    }
}

- (void)fetchBroadcasts {
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (error) {
            [Logger handleError:error];
        } else {
            self.userGeoPoint = geoPoint;
            PFQuery *query = [PFQuery queryWithClassName:@"Broadcast"];

            [query whereKey:@"location" nearGeoPoint:self.userGeoPoint withinKilometers:10.0f];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error) {
                    [Logger handleError:error];
                } else {
                    self.broadcasts = objects;
                    [self fetchNotifications];
                    [self.tableView reloadData];
                    self.checkInCalled = NO;
                }
            }];
        }
    }];
}


- (void)fetchNotifications {
    self.notifications = [[NSMutableArray alloc] init];
    for (PFObject *broadcast in self.broadcasts) {
        NSMutableArray *allNotifications = [broadcast objectForKey:@"notifications"];
        for (NSDictionary *notification in allNotifications) {
            if ([[notification objectForKey:@"type"] isEqualToString:@"Invite"]) {
                if ([[notification objectForKey:@"username"] isEqualToString:[[PFUser currentUser] objectForKey:@"nickname"]]) {
                    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[notification objectForKey:@"message"], @"message",
                                          [notification objectForKey:@"eventPhotoPFFile"], @"photoFile",
                                          [notification objectForKey:@"title"], @"title",
                                          [notification objectForKey:@"eventInvitee"], @"eventInvitee",
                                          [notification objectForKey:@"dateCreated"], @"dateCreated",
                                          nil];
                    [self.notifications addObject:dict];
                }
            } else if ([[notification objectForKey:@"type"] isEqualToString:@"Check-In"]) {
                BOOL isFriend = NO;
                for (FBUsers *fbFriend in self.facebookFriends) {
                    if ([fbFriend.username isEqualToString:[notification objectForKey:@"username"]]) {
                        isFriend = YES;
                        break;
                    }
                }
                if (isFriend) {
                    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[notification objectForKey:@"message"], @"message",
                                          [notification objectForKey:@"eventPhotoPFFile"], @"photoFile",
                                          [notification objectForKey:@"title"], @"title",
                                          @"", @"eventInvitee",
                                          [notification objectForKey:@"dateCreated"], @"dateCreated",
                                          nil];
                    [self.notifications addObject:dict];
                }
                
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.broadcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BroadcastCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BroadcastCell" forIndexPath:indexPath];
    PFObject *broadcast = [self.broadcasts objectAtIndex:indexPath.row];
    
    cell.titleLabel.text = broadcast[@"title"];
    cell.distanceLabel.text = [self friendlyDistanceForGeoPointFromBroadcast:(PFObject *)broadcast];
    cell.friendsLabel.text = [BaseUtils formatAttendingStringWithArrayForCondensedString:broadcast[@"attendingList"]];
    
    if (!broadcast[@"image"]) {
        PFFile *imageFile = [broadcast[@"images"] objectAtIndex:0];
        [cell loadImageFromFile:imageFile];
    }else{
        PFFile *imageFile = broadcast[@"image"];
        [cell loadImageFromFile:imageFile];
    }
    
    return cell;
}

- (NSString *)friendlyDistanceForGeoPointFromBroadcast:(PFObject *)broadcast {
    PFGeoPoint *location = [PFGeoPoint geoPointWithLocation:self.lastFetchedLocation];
    double kilometersAway = [location distanceInKilometersTo:broadcast[@"location"]];
    NSUInteger minutesValue = (NSUInteger)ceil(kilometersAway * 10);
    double distanceValue;
    BOOL useMeters;

    if (kilometersAway < 1.00) {
        distanceValue = ceil(kilometersAway*1000);
        useMeters = true;
    }else{
        distanceValue = ceilf(kilometersAway * 100) / 100;
        useMeters = false;
    }
    
    if (minutesValue <= 1) {
        [self checkInToBroadcast:broadcast];
        return @"At current location";
    } else {
        if (!self.checkInCalled) {
            [self.rightBarButton setHidden:YES];
        }
        if (useMeters) {
            return [NSString stringWithFormat:@"%lu m away", (unsigned long)distanceValue];
        }else{
            return [NSString stringWithFormat:@"%.2f km away", distanceValue];
        }
    }
}

- (void)checkInToBroadcast:(PFObject *)broadcast {
    BOOL shouldCheckIn = YES;
    self.checkInCalled = YES;
    NSArray *checkInList = [NSArray arrayWithArray:broadcast[@"checkIns"]];
    for (NSString *checkIn in checkInList) {
        if ([checkIn isEqualToString:[[PFUser currentUser] objectForKey:@"nickname"]]) {
            shouldCheckIn = NO;
            break;
        }
    }
    if (self.askToCheckIn) {
        if (shouldCheckIn) {
            NSArray *attendingList = [NSArray arrayWithArray:broadcast[@"attendingList"]];
            for (NSString *attendee in attendingList) {
                if ([attendee isEqualToString:[[PFUser currentUser] objectForKey:@"nickname"]]) {
                    if (self.isAutoCheckInEnabled) {
                        self.currentBroadcastToUpdate = broadcast;
                        [self checkIn];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check In!"
                                                                        message:[NSString stringWithFormat:@"Would you like to check in to the broadcast \"%@\"?", broadcast[@"title"]]
                                                                       delegate:self
                                                              cancelButtonTitle:@"NO"
                                                              otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
                        alert.tag = 100;
                        self.currentBroadcastToUpdate = broadcast;
                        [alert show];
                    }
                }
            }
        } else {
            [self.rightBarButton setHidden:YES];
        }
        self.askToCheckIn = NO;
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    if ([segue.identifier isEqualToString:@"ShowBroadcast"]) {
        BroadcastDetailViewController *detailVC = segue.destinationViewController;
        detailVC.broadcast = [self.broadcasts objectAtIndex:indexPath.row];
    } else if ([segue.identifier isEqualToString:@"ShowNotifications"]) {
        NotificationsTableViewController *detailVC = segue.destinationViewController;
        detailVC.broadcasts = self.broadcasts;
        detailVC.notifications = self.notifications;
        detailVC.lastTimeChecked = self.lastTimeChecked;
    }    
}

#pragma mark - IBActions

- (IBAction)actionSelectNotifications:(id)sender {
    [self performSegueWithIdentifier:@"ShowNotifications" sender:self];
}

- (IBAction)actionSelectAlert:(id)sender {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self refresh:self.refreshControl];
}
#pragma mark - BeaconDelegate

- (void)updateLocation {
//    [self.tableView reloadData];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        if (buttonIndex == 1) {
            [self checkIn];
            [self.rightBarButton setHidden:YES];
        } else if (buttonIndex == 0) {
            [self.rightBarButton setHidden:NO];
        }
    }
}

- (void)checkIn {
    PFUser *currentUser = [PFUser currentUser];
    [self.currentBroadcastToUpdate addObject:[[PFUser currentUser] objectForKey:@"nickname"] forKey:@"checkIns"];
    NSDictionary *notification = @{@"username": [currentUser objectForKey:@"nickname"],
                                   @"string": [currentUser objectForKey:@"username"],
                                   @"message": [NSString stringWithFormat:@"%@ checked in to the event %@", [currentUser objectForKey:@"nickname"], self.currentBroadcastToUpdate[@"title"]],
                                   @"title" : self.currentBroadcastToUpdate[@"title"],
                                   @"eventInvitee" : @"",
                                   @"eventPhotoPFFile" : [self.currentBroadcastToUpdate[@"images"] objectAtIndex:0],
                                   @"type": @"Check-In",
                                   @"dateCreated" : [NSDate date]};
    
    [self.currentBroadcastToUpdate addObject:notification forKey:@"notifications"];
    [self.currentBroadcastToUpdate saveEventually];
    self.currentBroadcastToUpdate = nil;
}

#pragma mark - Helpers

- (void)getFacebookFriends {
    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        NSArray *fbFriends = [result objectForKey:@"data"];
        self.facebookFriends = [[NSMutableArray alloc] init];
        for (NSDictionary<FBGraphUser>* friend in fbFriends) {
            FBUsers *user = [[FBUsers alloc] init];
            user.username = friend.name;
            user.userId = friend.objectID;
            
            //get profile picture url
            NSString *pictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", user.userId];
            user.profileImageUrl = pictureURL;
            
            [self.facebookFriends addObject:user];
        }
    }];
}

@end
