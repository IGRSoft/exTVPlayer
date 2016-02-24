//
//  IGRCatalogPreviewViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/24/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IGREntityExCatalog;

@protocol IGRCatalogPreviewViewControllerDelegate <NSObject>

- (void)openCatalogForPreview;

@end

@interface IGRCatalogPreviewViewController : UIViewController

- (instancetype)initWithCatalog:(IGREntityExCatalog *)aCatalog;

@property (nonatomic, weak) id<IGRCatalogPreviewViewControllerDelegate> delegate;

@end
