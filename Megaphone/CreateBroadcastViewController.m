#import "CreateBroadcastViewController.h"
#import "DatePickerTableViewCell.h"
#import "BroadcastHeaderInfoTableViewCell.h"
#import "CreateBroadcastImagesTableViewCell.h"

#import "MPTextField.h"
#import "MPTextView.h"
#import "BeaconService.h"
#import "BaseUtils.h"
#import "Notification.h"
#import "Logger.h"

@interface CreateBroadcastViewController () <
UITableViewDataSource,
UITableViewDelegate,
UIActionSheetDelegate,
UIImagePickerControllerDelegate,
DatePickerTableViewCellDelegate,
BroadcastHeaderInfoTableViewCellDelegate,
CreateBroadcastImagesTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) CGFloat baseHeight;

@property (nonatomic, strong) NSIndexPath *dateIndexPath;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *prettyFormatter;

@property (nonatomic) BOOL editingDate;
@property (nonatomic, strong) NSDate *localDate;

@property (nonatomic, strong) NSString *statePressed;
@property (nonatomic, strong) NSMutableArray *broadcastPhotos;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (nonatomic) BOOL titleNotEmpty;

@end


@implementation CreateBroadcastViewController

- (void)loadDateFormatters {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    self.dateFormatter = dateFormatter;
    
    NSDateFormatter *prettyFormatter = [[NSDateFormatter alloc] init];
    [prettyFormatter setDateStyle:NSDateFormatterShortStyle];
    [prettyFormatter setTimeStyle:NSDateFormatterShortStyle];
    self.prettyFormatter = prettyFormatter;
}

- (void)prepareBroadcast {
    if (self.broadcast == nil) {
        self.broadcast = [PFObject objectWithClassName:@"Broadcast"];
        self.broadcast[@"creator"] = [PFUser currentUser];
        
        NSDate *startDate = [NSDate date];
        NSDate *endDate = [NSDate dateWithTimeInterval:(60 * 60)
                                             sinceDate:startDate];
        NSMutableArray *checkInList = [NSMutableArray array];
        NSDictionary *notification = [[NSDictionary alloc] init];
        
        self.broadcast[@"startDate"] = startDate;
        self.broadcast[@"endDate"] = endDate;
        
        self.broadcast[@"category"] = @"None";
        self.broadcast[@"checkIns"] = checkInList;
        self.broadcast[@"notification"] = notification;
        
        self.broadcast[@"views"] = @0;
        self.broadcast[@"reached"] = @0;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadDateFormatters];
    [self prepareBroadcast];
    
    self.baseHeight = 0;
    [self.tableView reloadData];
    self.broadcastPhotos = [[NSMutableArray alloc] init];
    self.editingDate = NO;
    
    [BaseUtils styleNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self verifyFields];
    if (self.broadcast) {
        self.broadcastPhotos = [[NSMutableArray alloc] init];
        for (int i = 0; i < [self.broadcast[@"images"] count]; i++) {
            PFFile *imageFile = [self.broadcast[@"images"] objectAtIndex:i];
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                [self.broadcastPhotos addObject:[UIImage imageWithData:data scale:1.0f]];
                [self.tableView reloadData];
            }];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidChangeFrame:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
}

- (IBAction)cancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneTapped:(id)sender {
    MBProgressHUD *progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressView.labelText = @"Saving...";
    progressView.mode = MBProgressHUDModeIndeterminate;
    
    [self.broadcast saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [progressView hide:YES];
        
        if (error) {
            [Logger handleError:error];
        } else {
            [[PFUser currentUser] setObject:self.broadcast.objectId
                                     forKey:@"broadcastID"];
            
            [[PFUser currentUser] saveEventually];
            [self.delegate updateInstructionLabelTitle];
            [self performSegueWithIdentifier:@"UnwindForSave"
                                      sender:self];
        }
    }];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 1;
        case 3:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = [self reuseIdentifierForIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        BroadcastHeaderInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (cell == nil) {
            cell = [[BroadcastHeaderInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        if (self.broadcast) {
            cell.textFieldLabel.text = self.broadcast[@"title"];
            cell.textViewMessage.text = self.broadcast[@"message"];
            if (![self.broadcast[@"message"] isEqualToString:@""]) {
                cell.labelPlaceholderMessage.hidden = YES;
            }
        }
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        NSString *localStateDate = @"";
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Start Date";
            localStateDate = @"startDate";
        } else {
            cell.textLabel.text = @"End Date";
            localStateDate = @"endDate";
        }
        cell.detailTextLabel.text = [self.prettyFormatter stringFromDate:self.broadcast[localStateDate]];
        return cell;
        
    } else if (indexPath.section == 2) {
        DatePickerTableViewCell *cell = (DatePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (cell == nil) {
            cell = [[DatePickerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        cell.delegate = self;
        cell.statePressed = self.statePressed;
        cell.pickerView.minimumDate = [NSDate dateWithTimeIntervalSinceNow:60];
        [cell showPickerView:self.editingDate withDate:self.localDate];
        return cell;
    } else  {
        CreateBroadcastImagesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (cell == nil) {
            cell = [[CreateBroadcastImagesTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        cell.broadcastPhotos = self.broadcastPhotos;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.collectionView reloadData];
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = NSLocalizedString(@"Basic Info", nil);
            break;
        case 1:
            sectionName = NSLocalizedString(@"Dates", nil);
            break;
        case 2:
            if (self.editingDate) {
                sectionName = NSLocalizedString(@"Pick Dates", nil);
            } else {
                sectionName = nil;
            }
            break;
        case 3:
            sectionName = NSLocalizedString(@"Photos", nil);
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return @"TextFieldCell";
        case 1:
            return @"DateCell";
        case 2:
            return @"DatePicker";
        case 3:
            return @"Photos";
        default:
            return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 140;
        case 1:
            return 44;
        case 2:
            if (self.editingDate) {
                return 219;
            } else {
                return 0;
            }
        case 3:
            return 180;
        default:
            return 0;
    }
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 2 && !self.editingDate) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 2 && !self.editingDate)
        return 1;
    return 32;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section == 2 && !self.editingDate)
        return 1;
    return 16;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(section == 2 && !self.editingDate)
        return [[UIView alloc] initWithFrame:CGRectZero];
    else if (section == 2) {
        UIView *myView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 20.0)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *btnImage = [UIImage imageNamed:@"up_arrow"];
        [button setImage:btnImage forState:UIControlStateNormal];
        [button setFrame:CGRectMake(275.0, 0.0, 30.0, 30.0)];
        [button setBackgroundColor:[UIColor clearColor]];
        [button addTarget:self action:@selector(minimizeDatePicker:) forControlEvents:UIControlEventTouchDown];
        [myView addSubview:button];
        return myView;
    }
    return nil;
}

- (IBAction)minimizeDatePicker:(id)sender {
    self.editingDate = NO;
    [UIView animateWithDuration:.4 animations:^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
    }];
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) { // this is my date cell above the picker cell
        self.editingDate = YES;
        
        if (indexPath.row == 0) {
            self.statePressed = @"startDate";
            self.localDate = self.broadcast[@"startDate"];
        } else if (indexPath.row == 1) {
            self.statePressed = @"endDate";
            self.localDate = self.broadcast[@"endDate"];
        }
        
        [UIView animateWithDuration:.4 animations:^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
        }];
        CGPoint offset = CGPointMake(0, 190);
        [self.tableView setContentOffset:offset animated:YES];
        
        
    }
    
    self.dateIndexPath = indexPath;
    
    self.baseHeight = 219;
}

#pragma mark - Keyboard Notifications

- (void)keyboardDidShow:(NSNotification *)notification {
    NSValue *rectValue = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect frame = [rectValue CGRectValue];
    [self moveBottomToHeight:frame.size.height];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    [self resetToBaseHeight];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification {
//    NSLog(@"%@", notification);
}

#pragma mark - Scroll Helpers

- (void)moveBottomToHeight:(CGFloat)height {
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = height;
    
    self.tableView.contentInset = contentInset;
    self.tableView.scrollIndicatorInsets = contentInset;
}

- (void)resetToBaseHeight {
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = self.baseHeight;
    
    self.tableView.contentInset = contentInset;
    self.tableView.scrollIndicatorInsets = contentInset;
}

#pragma mark - DatePickerTableViewCellDelegate Methods

- (void)notifyDateTimeChanged:(NSDate *)date withState:(NSString *)state{
    self.broadcast[state] = date;
    if ([state isEqualToString:@"startDate"]) {
        if ([self.broadcast[@"startDate"] compare:self.broadcast[@"endDate"]] == NSOrderedDescending) {
            self.broadcast[@"endDate"] = self.broadcast[@"startDate"];
            self.localDate = self.broadcast[@"startDate"];
//            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    } else if ([state isEqualToString:@"endDate"]) {
        if ([self.broadcast[@"startDate"] compare:self.broadcast[@"endDate"]] == NSOrderedDescending) {
            self.broadcast[@"startDate"] = self.broadcast[@"endDate"];
            self.localDate = self.broadcast[@"startDate"];
//            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - BroadcastHeaderInfoTableViewCellDelegate

- (void)updateBroadcastInfoWithText:(NSString *)string forState:(NSString *)state {
    self.broadcast[state] = string;
}

- (void)updateTitleFilledState:(BOOL)isFilled {
    self.titleNotEmpty = isFilled;
    [self verifyFields];
}

#pragma mark - CreateBroadcastImagesTableViewCellDelegate

- (void)addImageToBroadcast {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Upload a Picture", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Photo Library", nil), NSLocalizedString(@"Camera", nil), nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
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
}

#pragma mark - Image Picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [BaseUtils fixOrientationForImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    
    UIImage *smallImage = [BaseUtils createIcon:image iconSize:280];
    
    [self.broadcastPhotos addObject:smallImage];
    [self.tableView reloadData];
    
    NSData *data = UIImageJPEGRepresentation(smallImage, 0.5f);
    NSString *filename = [NSString stringWithFormat:@"Image.png"];
    PFFile *imageFile = [PFFile fileWithName:filename data:data];
    
    [self.broadcast addObject:imageFile forKey:@"images"];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Verifications

- (void)verifyFields {
    BOOL enableDoneButton = NO;
    if (self.titleNotEmpty && ([self.broadcastPhotos count] != 0)) {
        enableDoneButton = YES;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = enableDoneButton;
}

@end
