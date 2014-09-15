@interface BroadcastCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UIImageView *broadcastImageView;
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;

- (void)loadImageFromFile:(PFFile *)file;

@end
