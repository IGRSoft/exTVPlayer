//
//  IGRExItemCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRExItemCell.h"
#import "DACircularProgressView.h"

@implementation IGRExItemCell

- (void)awakeFromNib
{
	self.trackStatus.roundedCorners = YES;
	self.trackStatus.clockwiseProgress = NO;
	self.trackStatus.trackTintColor = [UIColor whiteColor];
	self.trackStatus.innerTintColor = [UIColor colorWithWhite:0.900 alpha:1.000];
	self.trackStatus.progressTintColor  = [UIColor colorWithRed:0.756 green:0.856 blue:1.000 alpha:1.000];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
