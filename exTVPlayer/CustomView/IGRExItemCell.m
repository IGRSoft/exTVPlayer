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
	self.trackStatus.thicknessRatio = 1.0;
	self.trackStatus.clockwiseProgress = NO;
	self.trackStatus.trackTintColor = [UIColor colorWithRed:0.999 green:1.000 blue:0.895 alpha:1.000];
	self.trackStatus.progressTintColor  = [UIColor colorWithRed:0.500 green:0.675 blue:1.000 alpha:1.000];
	
	self.savedIcon.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
}

@end
