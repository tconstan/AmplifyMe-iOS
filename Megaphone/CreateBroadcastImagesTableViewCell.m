//
//  CreateBroadcastImagesTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import "CreateBroadcastImagesTableViewCell.h"
#import "BroadcastDetailCollectionViewCell.h"

@interface CreateBroadcastImagesTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation CreateBroadcastImagesTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = @"BroadcastDetailViewCollectionCell";
    
    [self.collectionView registerClass:[BroadcastDetailCollectionViewCell class] forCellWithReuseIdentifier:cellId];
    BroadcastDetailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    if (indexPath.row == [self.broadcastPhotos count]) {
        if ([self.broadcastPhotos count] == 0) {
            [cell populateCellWithImage:[UIImage imageNamed:@"add_images"] atIndex:indexPath.row andBorder:YES];
        } else {
            [cell populateCellWithImage:[UIImage imageNamed:@"add_images"] atIndex:indexPath.row andBorder:NO];
        }
    } else {
        [cell populateCellWithImage:self.broadcastPhotos[indexPath.row] atIndex:indexPath.row andBorder:NO];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.broadcastPhotos count]) {
        [self.delegate addImageToBroadcast];
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

@end
