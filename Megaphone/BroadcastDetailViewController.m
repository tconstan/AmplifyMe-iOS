#import "BroadcastDetailViewController.h"
#import "BroadcastAnnotation.h"
#import "CreateBroadcastViewController.h"
#import "BaseUtils.h"
#import "BroadcastDetailCollectionViewCell.h"
#import "UIColor+Megaphone.h"
#import "FBUsersTableViewController.h"
#import "TTTAttributedLabel.h"
#import "MButton.h"
#import "AttendingUsersTableViewController.h"
#import "Logger.h"

@interface BroadcastDetailViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, TTTAttributedLabelDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *userImageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) PFObject *owner;
@property (nonatomic, strong) NSMutableArray *broadcastPhotos;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet MButton *attendingButton;
@property (weak, nonatomic) IBOutlet MButton *inviteFriendsButton;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *attendingLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *labelDirections;

@property (nonatomic, assign) int fbShareTag;
@property (nonatomic, assign) int imageSelectorTag;

@property (nonatomic) BOOL datesSame;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintAttendingButtonTopSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintInviteButtonTopSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintScrollViewHeight;

@end

@implementation BroadcastDetailViewController

- (void)viewDidAppear:(BOOL)animated {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    self.owner = self.broadcast[@"creator"];
    
    self.fbShareTag = 1;
    self.imageSelectorTag = 2;
    [self updateView];
}

-(void)viewDidLayoutSubviews {
    if (IsIphone5) {
        self.scrollView.contentSize = CGSizeMake(320, 782);
    } else {
        self.scrollView.contentSize = CGSizeMake(320, 694);
    }
}

- (void)updateView {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(actionTapped:)];
    
    [self.attendingButton setTintColor:[UIColor defaultFacebookColor]];
    [self.attendingButton showShadowAtBottom];
    [self.inviteFriendsButton showShadowAtBottom];
    
    BroadcastAnnotation *annotation = [[BroadcastAnnotation alloc] initWithBroadcast:self.broadcast];
    [self.mapView addAnnotation:annotation];
    
    self.mapView.zoomEnabled = NO;
    self.mapView.scrollEnabled = NO;
    self.mapView.userInteractionEnabled = NO;

    MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(0.02, 0.02));
    [self.mapView setRegion:region animated:NO];
    
    self.titleLabel.text = self.broadcast[@"title"];
    self.messageLabel.text = self.broadcast[@"message"];
    
    self.datesSame = NO;
    NSInteger days1 = [self.broadcast[@"startDate"] timeIntervalSince1970] / 86400;
    NSInteger days2 = [self.broadcast[@"endDate"] timeIntervalSince1970] / 86400;
    if (days1 == days2) {
        self.datesSame = YES;
    }
    
    NSString *formatString = @"%@ - %@";
    
    NSString *dateString = [NSString stringWithFormat:formatString,
                            [BaseUtils loadDateFormatterForDate:self.broadcast[@"startDate"] addPrefix:YES],
                            [BaseUtils loadDateFormatterForDate:self.broadcast[@"endDate"] addPrefix:!self.datesSame]];
    
    self.dateLabel.text = dateString;
    BOOL isAttending = [self isCurrentUserAttendingEvent:self.broadcast[@"attendingList"]];
    if (isAttending) {
        [self.attendingButton setTitle:NSLocalizedString(@"Attending!", nil) forState:UIControlStateNormal];
    } else {
        [self.attendingButton setTitle:NSLocalizedString(@"Not Attending!", nil) forState:UIControlStateNormal];
    }
    NSString *attendingString = [BaseUtils formatAttendingStringWithArray:self.broadcast[@"attendingList"]];
    self.attendingLabel.text = attendingString;
    
    NSString *stringToSearch = [NSString stringWithFormat:@"%lu others", ([self.broadcast[@"attendingList"] count] - 2)];
    NSRange textRange = [self.attendingLabel.text rangeOfString:stringToSearch];
    if (textRange.location != NSNotFound) {
        //textrange found
        NSString *param = [self.attendingLabel.text substringFromIndex:textRange.location + textRange.length];
        self.attendingLabel.delegate = self;
        self.attendingLabel.linkAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:self.attendingLabel.font.pointSize],
                                                        NSForegroundColorAttributeName: [UIColor blackColor],
                                                        NSUnderlineStyleAttributeName: [NSNumber numberWithInt:0] };
        [self.attendingLabel addLinkToAddress: @{
                                                         param : param
                                                         }
                                            withRange: textRange];
        
    }
    
    NSString *stringToSearchDirections = @"Directions";
    textRange = [self.labelDirections.text rangeOfString:stringToSearchDirections];
    if (textRange.location != NSNotFound) {
        //textrange found
        NSString *param = [self.labelDirections.text substringFromIndex:textRange.location + textRange.length];
        self.labelDirections.delegate = self;
        self.labelDirections.linkAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:self.labelDirections.font.pointSize],
                                                NSForegroundColorAttributeName: [UIColor blackColor],
                                                NSUnderlineStyleAttributeName: [NSNumber numberWithInt:0] };
        [self.labelDirections addLinkToAddress: @{
                                                 param : param
                                                 }
                                    withRange: textRange];
        
    }
    
    self.broadcastPhotos = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.broadcast[@"images"] count]; i++) {
        PFFile *imageFile = [self.broadcast[@"images"] objectAtIndex:i];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            [self.broadcastPhotos addObject:[UIImage imageWithData:data scale:1.0f]];
            self.userImageView.image = [BaseUtils createIcon:[UIImage imageWithData:data scale:1.0f] iconSize:140];
            self.userImageView.layer.cornerRadius = 5.0f;
            self.userImageView.layer.masksToBounds = YES;
            [self.collectionView reloadData];
        }];
    }
    
    if (IsIphone5) {
        self.constraintScrollViewHeight.constant = 580;
        self.constraintAttendingButtonTopSpacing.constant = 75;
        self.constraintInviteButtonTopSpacing.constant = 64;
        if ([self.messageLabel.text isEqualToString:@""] || !self.messageLabel.text) {
            self.constraintAttendingButtonTopSpacing.constant = 10;
            self.constraintScrollViewHeight.constant += 60;
        }
        if ([self.attendingLabel.text isEqualToString:@""] || !self.attendingLabel.text) {
            self.constraintInviteButtonTopSpacing.constant = 14;
            self.constraintScrollViewHeight.constant += 60;
        }
    } else {
        self.constraintScrollViewHeight.constant = 408;
        self.constraintAttendingButtonTopSpacing.constant = 75;
        self.constraintInviteButtonTopSpacing.constant = 64;
        if ([self.messageLabel.text isEqualToString:@""] || !self.messageLabel.text) {
            self.constraintAttendingButtonTopSpacing.constant = 10;
            self.constraintScrollViewHeight.constant += 60;
        }
        if ([self.attendingLabel.text isEqualToString:@""] || !self.attendingLabel.text) {
            self.constraintInviteButtonTopSpacing.constant = 14;
            self.constraintScrollViewHeight.constant += 60;
        }
    }
    
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
    if ([label.text isEqualToString:@"Directions to this Broadcast"]) {
        [self openInMaps:self];
    } else {
        [self performSegueWithIdentifier:@"showAttendingUsers" sender:self];
    }
}

- (BOOL)isCurrentUserAttendingEvent:(NSMutableArray *)input {
    for (NSString *username in input) {
        if ([username isEqualToString:[[PFUser currentUser] objectForKey:@"nickname"]]) {
            return YES;
        }
    }
    return NO;
}

- (IBAction)openInMaps:(id)sender {
    PFGeoPoint *location = self.broadcast[@"location"];
    CLLocationCoordinate2D distination = CLLocationCoordinate2DMake(location.latitude, location.longitude);

    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:distination addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    [mapItem setName:self.broadcast[@"title"]];

    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking,};
    [mapItem openInMapsWithLaunchOptions:launchOptions];
}

- (IBAction)openMapView:(id)sender {
    PFGeoPoint *location = self.broadcast[@"location"];
    CLLocationCoordinate2D distination = CLLocationCoordinate2DMake(location.latitude, location.longitude);

    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:distination addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    [mapItem setName:self.broadcast[@"title"]];

    [mapItem openInMapsWithLaunchOptions:nil];
}
#pragma mark - IBActions

- (IBAction)actionSelectAttending:(id)sender {
    if ([self.attendingButton.titleLabel.text isEqualToString:[NSString stringWithFormat:@"Not Attending!"]]) {
        NSString *username = [[PFUser currentUser] objectForKey:@"nickname"];
        [self.broadcast addObject:username forKey:@"attendingList"];
    } else {
        NSString *username = [[PFUser currentUser] objectForKey:@"nickname"];
        [self.broadcast removeObject:username forKey:@"attendingList"];
    }
    
    [self.broadcast saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [Logger handleError:error];
        }
    }];
    
    
    [self updateView];
}

- (IBAction)actionSelectInviteFriendsButton:(id)sender {
    [self performSegueWithIdentifier:@"showFBFriends" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showFBFriends"]) {
        FBUsersTableViewController *fbUsersVC = segue.destinationViewController;
        fbUsersVC.broadcast = self.broadcast;
    } else if ([segue.identifier isEqualToString:@"showAttendingUsers"]) {
        AttendingUsersTableViewController *attendingUsersVC = segue.destinationViewController;
        attendingUsersVC.broadcast = self.broadcast;
    }
}

#pragma mark - ActionSheet

- (IBAction)actionTapped:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share to Facebook", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Get Directions", nil)];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.tag = self.fbShareTag;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}



- (void)addNewImageTapped {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Upload a Picture", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Photo Library", nil), NSLocalizedString(@"Camera", nil), nil];
    actionSheet.tag = self.imageSelectorTag;
    [actionSheet showInView:self.parentViewController.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == self.imageSelectorTag) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
            
            if (buttonIndex == 0) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            }else if(buttonIndex == 1){
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            imagePickerController.delegate = (id)self;
            
            self.imagePickerController = imagePickerController;
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    } else if (actionSheet.tag == self.fbShareTag) {
        if (buttonIndex == 0) {
            [self shareLinkWithShareDialog:nil];
        }else if(buttonIndex == 1){
            [self openInMaps:nil];
        }
    }
}

#pragma mark - FBShare

- (IBAction)shareLinkWithShareDialog:(id)sender
{
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
        
        NSString *eventTitle = self.broadcast[@"title"] != nil ? self.broadcast[@"title"] : [NSString stringWithFormat:@"%@'s Event", self.broadcast[@"creator"]];
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

#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = @"BroadcastDetailViewCollectionCell";
    
    [self.collectionView registerClass:[BroadcastDetailCollectionViewCell class] forCellWithReuseIdentifier:cellId];
    BroadcastDetailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    if (indexPath.row == [self.broadcastPhotos count]) {
        [cell populateCellWithImage:[UIImage imageNamed:@"add_images"] atIndex:indexPath.row andBorder:NO];
    } else {
        [cell populateCellWithImage:self.broadcastPhotos[indexPath.row] atIndex:indexPath.row andBorder:NO];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.broadcastPhotos count]) {
        [self addNewImageTapped];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.broadcastPhotos count] + 1;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - Image Picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    MBProgressHUD *progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressView.labelText = @"Uploading...";
    progressView.mode = MBProgressHUDModeIndeterminate;
    UIImage *image = [BaseUtils fixOrientationForImage:[info objectForKey:UIImagePickerControllerOriginalImage]];

    UIImage *smallImage = [BaseUtils createIcon:image iconSize:280];

    NSData *data = UIImageJPEGRepresentation(smallImage, 0.5f);
    NSString *filename = [NSString stringWithFormat:@"Image.png"];
    PFFile *imageFile = [PFFile fileWithName:filename data:data];

    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // The image has now been uploaded to Parse. Associate it with a new object
            [self.broadcast addObject:imageFile forKey:@"images"];
            [self.broadcast saveEventually];
            [self updateView];
        } else if (error) {
            [Logger handleError:error];
        }

        [picker dismissViewControllerAnimated:YES completion:nil];
    }];

    [self.collectionView reloadData];
    [progressView hide:YES];
}

@end
