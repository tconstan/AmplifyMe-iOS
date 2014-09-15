//
//  NotificationsTableViewController.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import "NotificationsTableViewController.h"
#import "Notification.h"
#import "NotificationTableViewCell.h"
#import "BroadcastDetailViewController.h"
#import "BaseUtils.h"
#import "FBUsers.h"
#import "UIColor+Megaphone.h"

@interface NotificationsTableViewController () <NotificationTableViewCellDelegate>

@property (nonatomic, strong) NSString *broadcastToShow;

@end

@implementation NotificationsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle :style];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [[PFUser currentUser] setObject:[NSDate date] forKey:@"lastDateCheckedNotifs"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"save successful");
        } else {
            NSLog(@"save successful");
        }
    }];
    [self.tableView reloadData];
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
    return [self.notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"notificationCell";
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[NotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    [cell populateCellWithInfo:notification];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([self.lastTimeChecked compare:[notification objectForKey:@"dateCreated"]] == NSOrderedAscending) {
        [cell contentView].backgroundColor = [UIColor notificationColor];
    }
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"showBroadcastFromNotification"]) {
        BroadcastDetailViewController *detailVC = segue.destinationViewController;
        for (PFObject *broadcast in self.broadcasts) {
            if ([[broadcast objectForKey:@"title"] isEqualToString:self.broadcastToShow]) {
                detailVC.broadcast = broadcast;
            }
        }
    }
    self.broadcastToShow = nil;
}


#pragma mark - NotificationTableViewCellDelegate Methods

- (void)performSegueForNotification:(NotificationTableViewCell *)sender withTitle:(NSString *)title{
    self.broadcastToShow = title;
    [self performSegueWithIdentifier:@"showBroadcastFromNotification" sender:self];
}

@end
