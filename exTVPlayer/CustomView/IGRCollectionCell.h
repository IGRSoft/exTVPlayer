//
//  IGRCollectionCell.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IGRCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;

@end
