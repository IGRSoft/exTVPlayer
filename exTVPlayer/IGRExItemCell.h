//
//  IGRExItemCell.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IGRExTrack;

@interface IGRExItemCell : UITableViewCell

@property (weak  , nonatomic) IBOutlet UILabel *title;
@property (weak  , nonatomic) IBOutlet UIImageView *viewStatus;

@end
