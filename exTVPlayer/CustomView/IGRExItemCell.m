//
//  IGRExItemCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRExItemCell.h"
#import "DACircularProgressView.h"
#import "DALabeledCircularProgressView.h"

@implementation IGRExItemCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
	self.trackStatus.thicknessRatio = 1.0;
	self.trackStatus.clockwiseProgress = NO;
	self.trackStatus.trackTintColor = IGR_YELLOWCOLOR;
	self.trackStatus.progressTintColor  = IGR_DARKBLUECOLOR;
	
	
	self.saveProgress.roundedCorners = NO;
	self.saveProgress.progressTintColor = IGR_DARKBLUECOLOR;
	
	CGFloat r, g, b;
	[IGR_DARKBLUECOLOR getRed:&r green:&g blue:&b alpha:nil];
	self.saveProgress.trackTintColor = [UIColor colorWithRed:r green:r blue:b alpha:0.3];
	self.saveProgress.progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	self.saveProgress.progressLabel.textColor = IGR_DARKBLUECOLOR;
	
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
