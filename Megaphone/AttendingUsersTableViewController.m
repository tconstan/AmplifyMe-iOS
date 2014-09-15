//
//  AttendingUsersTableViewController.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import "AttendingUsersTableViewController.h"
#import "AttendingUsersTableViewCell.h"

@interface AttendingUsersTableViewController ()

@property (nonatomic, strong) NSMutableArray *users;

@end

@implementation AttendingUsersTableViewController

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
}

- (void)viewWillAppear:(BOOL)animated {    
    [self getUsersGoingFromBroadcast];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getUsersGoingFromBroadcast {
    self.users = [[NSMutableArray alloc] init];
    for (NSString *userName in self.broadcast[@"attendingList"]) {
        PFQuery *query = [PFUser query];
        [query whereKey:@"nickname" equalTo:userName];
        NSArray *going = [query findObjects];
        for (PFUser *user in going) {
            [self.users addObject:user];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.users count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"attendingUsersCell";
    AttendingUsersTableViewCell *cell = (AttendingUsersTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[AttendingUsersTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    PFUser *newUser = (PFUser *)[self.users objectAtIndex:indexPath.row];
    [cell populateCellWithUser:newUser];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

@end
