//
//  IGRCatalogCell.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCollectionCell.h"

@interface IGRCatalogCell : IGRCollectionCell

@property (weak  , nonatomic) IBOutlet UIImageView *image;
@property (assign, nonatomic) BOOL favorit;

@property (assign, nonatomic, readonly) BOOL isHighlighted;

@property (weak,nonatomic) id<UIViewControllerPreviewingDelegate> previewingDelegate;

@end
