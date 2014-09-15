@class MPBroadcast;

@protocol CreateBroadcastViewControllerDelegate

- (void)updateInstructionLabelTitle;

@end

@interface CreateBroadcastViewController : UIViewController

@property (nonatomic, strong) id <CreateBroadcastViewControllerDelegate> delegate;
@property (nonatomic, strong) PFObject *broadcast;

@end
