//
//  IGRCatalogViewControllerCollectionViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

@class IGREntityExChanel;

@interface IGRCChanelViewController : UICollectionViewController

- (void)setChanel:(NSString *)aChanel;
- (void)setCatalog:(NSString *)aCatalog;
- (void)setSearchResult:(NSString *)aSearchRequest;

- (void)showFavorites;
- (void)showHistory;

@property (nonatomic, assign) BOOL needHighlightCell;

@end
