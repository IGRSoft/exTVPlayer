//
//  IGRCollectionCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCollectionCell.h"

@implementation IGRCollectionCell

- (void)setHighlighted:(BOOL)highlighted
{
	super.highlighted = highlighted;
	
	UIColor *cellColor = highlighted ?  IGR_LIGHTBLUECOLOR :
										[UIColor whiteColor];
	
	UIColor *textColor = highlighted ?  [UIColor whiteColor] : IGR_DARKBLUECOLOR;
	
	[UIView animateWithDuration:0.1
						  delay:0
						options:(UIViewAnimationOptionAllowUserInteraction)
					 animations:^{
						 (self.backgroundView).backgroundColor = cellColor;
						 self.title.textColor = textColor;
					 }
					 completion:nil];
}

- (void)setSelected:(BOOL)selected
{
	if (selected)
	{
		[self.progress startAnimating];
	}
	else
	{
		[self.progress stopAnimating];
	}
}

@end
