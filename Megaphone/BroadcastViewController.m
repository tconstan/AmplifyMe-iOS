#import <FBShimmeringView.h>

#import "BroadcastViewController.h"
#import "CreateBroadcastViewController.h"
#import "BeaconService.h"
#import "BaseUtils.h"
#import "Logger.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <Parse/Parse.h>

@interface BroadcastViewController () <BeaconServiceObserver,
CreateBroadcastViewControllerDelegate,
UIActionSheetDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIAlertViewDelegate>

@property (nonatomic, strong) PFObject *broadcast;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UILabel *labelBroadcastInstruction;
@property (weak, nonatomic) IBOutlet FBShimmeringView *shimmeringView;
@property (weak, nonatomic) IBOutlet UIImageView *megaphoneImageView;

@property (weak, nonatomic) IBOutlet UIButton *editBroadcastButton;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (nonatomic, assign) BOOL isBroadcasting;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButtonItem;

@property (nonatomic, strong) NSMutableDictionary *imageArray;
@property (nonatomic) BOOL autoPostToFB;

@property (nonatomic) BOOL datesSame;

@end

@implementation BroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = nil;
    self.shimmeringView.contentView = self.megaphoneImageView;
    self.isBroadcasting = NO;
    [self fetchBroadcastForUser];
    
    [BaseUtils styleNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[BeaconService sharedService] addObserver:self];
    if (self.broadcast) {
        self.megaphoneImageView.alpha = 1;
    } else {
        self.megaphoneImageView.alpha = 0.3;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *checkIn = [defaults objectForKey:@"autoFBPostEnabled"];
    if ([checkIn isEqualToString:@"YES"]) {
        self.autoPostToFB = YES;
    } else {
        self.autoPostToFB = NO;
    }
    if (self.broadcast != nil) {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[BeaconService sharedService] removeObserver:self];
}

- (void)service:(BeaconService *)service updatedLocation:(CLLocation *)location {
    if (self.broadcast != nil && location != nil && self.isBroadcasting) {
        [self.broadcast refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {

            self.broadcast[@"location"] = [PFGeoPoint geoPointWithLocation:location];
            [self.broadcast saveEventually];

            [self updateView];
        }];
    }
}

- (void)fetchBroadcastForUser {
    NSString *broadcastID = [[PFUser currentUser] objectForKey:@"broadcastID"];
    PFQuery *query = [PFQuery queryWithClassName:@"Broadcast"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    broadcastID = [defaults objectForKey:@"broadcastID"];

    if (broadcastID != nil) {
        [query getObjectInBackgroundWithId:broadcastID block:^(PFObject *broadcast, NSError *error) {
            self.broadcast = broadcast;
            self.isBroadcasting = YES;
            self.shimmeringView.shimmering = YES;
            
            [self.megaphoneImageView setImage:[UIImage imageNamed:@"megaphone_red"]];
            self.megaphoneImageView.alpha = 1;
            self.labelBroadcastInstruction.hidden = YES;

            [self updateView];
            
            [[BeaconService sharedService] setBroadcast:broadcast];
        }];
    }else{
        [self updateView];
    }
}

- (void)updateView {
    if (self.broadcast != nil) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_icon"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(actionTapped:)];
        
        PFFile *imageFile = [self.broadcast[@"images"] objectAtIndex:[self.broadcast[@"images"] count]-1];
        
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            self.imageView.image = [BaseUtils createIcon:[UIImage imageWithData:data scale:1.0f] iconSize:100];
            self.imageView.layer.cornerRadius = 5.0f;
            self.imageView.layer.masksToBounds = YES;
        }];
        
        self.titleLabel.text = self.broadcast[@"title"];
        
        self.datesSame = NO;
        NSInteger days1 = [self.broadcast[@"startDate"] timeIntervalSince1970] / 86400;
        NSInteger days2 = [self.broadcast[@"endDate"] timeIntervalSince1970] / 86400;
        if (days1 == days2) {
            self.datesSame = YES;
        }
        
        NSString *formatString = @"Starts on %@, and ends at %@";
        NSString *dateString = [NSString stringWithFormat:formatString,
                                [BaseUtils loadDateFormatterForDate:self.broadcast[@"startDate"] addPrefix:YES],
                                [BaseUtils loadDateFormatterForDate:self.broadcast[@"endDate"] addPrefix:!self.datesSame]];
        
        self.startDateLabel.text = dateString;
        self.viewCountLabel.text = [NSString stringWithFormat:@"%@", self.broadcast[@"reached"]];
        
        [self.editBroadcastButton setTitle:@"Edit Broadcast"
                                  forState:UIControlStateNormal];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.imageView.hidden = (self.broadcast == nil);
    self.titleLabel.hidden = (self.broadcast == nil);
    self.startDateLabel.hidden = (self.broadcast == nil);
    self.viewCountLabel.hidden = (self.broadcast == nil);
    self.viewsLabel.hidden = (self.broadcast == nil);
}

- (IBAction)startTapped:(id)sender {
    if (self.broadcast == nil) {
        [self performSegueWithIdentifier:@"ShowBroadcast"
                                  sender:self];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.isBroadcasting = YES;
    self.shimmeringView.shimmering = YES;
    [self.megaphoneImageView setImage:[UIImage imageNamed:@"megaphone_red"]];
    self.megaphoneImageView.alpha = 1;
    [defaults setValue:self.broadcast.objectId forKey:@"broadcastID"];
    self.labelBroadcastInstruction.hidden = YES;
    [defaults synchronize];
    [[BeaconService sharedService] startUpdatingLocation];
    [BeaconService sharedService].broadcast = self.broadcast;
    if (self.autoPostToFB) {
        [self postToFacebook];
    }

    self.editBroadcastButton.hidden = YES;
}

- (void)postToFacebook {
    PFFile *image;
    if (self.broadcast[@"images"]) {
        image = [self.broadcast[@"images"] objectAtIndex:0];
    }
    
    self.datesSame = NO;
    NSInteger days1 = [self.broadcast[@"startDate"] timeIntervalSince1970] / 86400;
    NSInteger days2 = [self.broadcast[@"endDate"] timeIntervalSince1970] / 86400;
    if (days1 == days2) {
        self.datesSame = YES;
    }
    
    NSString *formatString = @"%@ - %@";
    
    NSString *eventTitle = self.broadcast[@"title"] != nil ? self.broadcast[@"title"] : [NSString stringWithFormat:@"%@'s Event", [[PFUser currentUser] objectForKey:@"nickname"]];
    NSString *message = self.broadcast[@"message"] != nil ? self.broadcast[@"message"] : @"";
    NSString *picture = self.broadcast[@"images"] != nil ? image.url : @"";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   eventTitle, @"name",
                                   [NSString stringWithFormat:formatString,
                                    [BaseUtils loadDateFormatterForDate:self.broadcast[@"startDate"] addPrefix:YES],
                                    [BaseUtils loadDateFormatterForDate:self.broadcast[@"endDate"] addPrefix:!self.datesSame]], @"caption",
                                   message, @"description",
                                   @"", @"link",
                                   picture, @"picture",
                                   nil];
    
    [FBRequestConnection startWithGraphPath:@"me/feed"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection,
                                              NSDictionary * result,
                                              NSError *error) {
                              if (error) {
                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't post event to Facebook", nil)
                                                                                  message:NSLocalizedString(@"Check your posting permissions or try again later", nil)
                                                                                 delegate:nil
                                                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                        otherButtonTitles: nil];
                                  [alert show];
                              }
                          }];
}
                                                  
- (IBAction)actionTapped:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete Broadcast", nil)
                                                    otherButtonTitles:NSLocalizedString(@"Edit Broadcast", nil),NSLocalizedString(@"Share to Facebook", nil), nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Broadcast?", nil)
                                                        message:NSLocalizedString(@"Deleting this broadcast is permanent and instant, are you sure?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                              otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        [alert show];
    } else if (buttonIndex == 1) {
        [self performSegueWithIdentifier:@"ShowBroadcast"
                                  sender:self];
    } else if (buttonIndex == 2) {
        [self shareLinkWithShareDialog:nil];
    }
}

- (IBAction)shareLinkWithShareDialog:(id)sender
{
    PFFile *image;
    if (self.broadcast[@"images"]) {
        image = [self.broadcast[@"images"] objectAtIndex:0];
    }
    
    NSString *formatString = @"%@ - %@";
    
    NSString *eventTitle = self.broadcast[@"title"] != nil ? self.broadcast[@"title"] : [NSString stringWithFormat:@"%@'s Event", [[PFUser currentUser] objectForKey:@"nickname"]];
    NSString *message = self.broadcast[@"message"] != nil ? self.broadcast[@"message"] : @"";
    NSString *picture = self.broadcast[@"images"] != nil ? image.url : @"";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   eventTitle, @"name",
                                   [NSString stringWithFormat:formatString,
                                    [BaseUtils loadDateFormatterForDate:self.broadcast[@"startDate"] addPrefix:YES],
                                    [BaseUtils loadDateFormatterForDate:self.broadcast[@"endDate"] addPrefix:!self.datesSame]], @"caption",
                                   message, @"description",
                                   @"", @"link",
                                   picture, @"picture",
                                   nil];
    
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                  if (error) {
                                                      // An error occurred, we need to handle the error
                                                      // See: https://developers.facebook.com/docs/ios/errors
                                                      NSLog(@"Error publishing story: %@", error.description);
                                                  } else {
                                                      if (result == FBWebDialogResultDialogNotCompleted) {
                                                          // User canceled.
                                                          NSLog(@"User cancelled.");
                                                      } else {
                                                          // Handle the publish feed callback
                                                          NSDictionary *urlParams = [BaseUtils parseURLParams:[resultURL query]];
                                                          
                                                          if (![urlParams valueForKey:@"post_id"]) {
                                                              // User canceled.
                                                              NSLog(@"User cancelled.");
                                                              
                                                          } else {
                                                              // User clicked the Share button
                                                              NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                              NSLog(@"result %@", result);
                                                          }
                                                      }
                                                  }
                                              }];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"ShowBroadcast"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        CreateBroadcastViewController *createBroadcastVC = (CreateBroadcastViewController *)[navigationController topViewController];
        createBroadcastVC.delegate = self;
        createBroadcastVC.broadcast = self.broadcast;
    }
}

- (IBAction)unwindForSaveBroadcast:(UIStoryboardSegue *)segue {
    CreateBroadcastViewController *viewController = segue.sourceViewController;
    self.broadcast = viewController.broadcast;
    [self updateView];
}

#pragma mark - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        MBProgressHUD *progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressView.labelText = @"Deleting...";
        progressView.mode = MBProgressHUDModeIndeterminate;
        [self.broadcast deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [Logger handleError:error];
            } else {
                self.broadcast = nil;
                self.isBroadcasting = NO;
                self.shimmeringView.shimmering = NO;
                self.imageView.image = nil;
                [self.megaphoneImageView setImage:[UIImage imageNamed:@"megaphone"]];
                self.labelBroadcastInstruction.hidden = NO;
                [self.labelBroadcastInstruction setText:NSLocalizedString(@"Tap to Create Broadcast!", nil)];
                self.megaphoneImageView.alpha = 0.3;
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:nil forKey:@"broadcastID"];
                
                [self updateView];
            }
        }];
        
        [progressView hide:YES];
    }
}

#pragma mark - CreateBroadcastViewControllerDelegate

- (void)updateInstructionLabelTitle {
    [self.labelBroadcastInstruction setText:NSLocalizedString(@"Tap to Broadcast!", nil)];
}

@end
