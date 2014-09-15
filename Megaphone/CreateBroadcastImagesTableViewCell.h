//
//  CreateBroadcastImagesTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import <UIKit/UIKit.h>

@protocol CreateBroadcastImagesTableViewCellDelegate <NSObject>

- (void)addImageToBroadcast;

@end

@interface CreateBroadcastImagesTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *broadcastPhotos;

@property (nonatomic, weak) id <CreateBroadcastImagesTableViewCellDelegate> delegate;

@end
