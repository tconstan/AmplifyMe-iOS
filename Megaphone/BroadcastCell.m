#import "BroadcastCell.h"
#import "BaseUtils.h"

@interface BroadcastCell ()

@property (nonatomic, strong) PFFile *file;

@end

@implementation BroadcastCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.broadcastImageView.image = nil;
    [self.file cancel];
}

- (void)loadImageFromFile:(PFFile *)file {
    self.file = file;
    
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        self.broadcastImageView.image = [BaseUtils createIcon:[UIImage imageWithData:data scale:1.0f] iconSize:100];
        self.broadcastImageView.layer.cornerRadius = 5.0f;
        self.broadcastImageView.layer.masksToBounds = YES;
    } progressBlock:^(int percentDone) {
        
    }];
}

@end
