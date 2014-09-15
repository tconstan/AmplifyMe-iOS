//
//  FBUsersTableViewController.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-16.
//
//

#import "FBUsersTableViewController.h"
#import "FBUserTableViewCell.h"
#import "FBUsers.h"
#import "BroadcastDetailViewController.h"

@interface FBUsersTableViewController ()

@property (nonatomic, strong) NSMutableArray *facebookFriends;

@end

@implementation FBUsersTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self getFacebookFriends];
}

- (void)getFacebookFriends {
    // Issue a Facebook Graph API request to get your user's friend list
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            self.facebookFriends = [[NSMutableArray alloc] init];
            // result will contain an array with your user's friends in the "data" key
            NSArray *friendObjects = [result objectForKey:@"data"];
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                FBUsers *user = [[FBUsers alloc] init];
                user.username = [friendObject objectForKey:@"name"];
                user.userId = [friendObject objectForKey:@"id"];
                
                //get profile picture url
                NSString *pictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", user.userId];
                user.profileImageUrl = pictureURL;
                
                [self.facebookFriends addObject:user];
            }
        }
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.facebookFriends count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"facebookFriendsCell";
    FBUserTableViewCell *cell = (FBUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[FBUserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    FBUsers *newUser = (FBUsers *)[self.facebookFriends objectAtIndex:indexPath.row];
    cell.broadcast = self.broadcast;
    [cell populateCellWithFBUser:newUser];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

@end
