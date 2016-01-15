//
//  IGRTableViewCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRTableViewCell.h"

@implementation IGRTableViewCell

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	
	UIColor *cellColor = highlighted ?  [UIColor colorWithRed:0.035 green:0.314 blue:0.816 alpha:1.000] :
										[UIColor whiteColor];
	
	UIColor *textColor = highlighted ?  [UIColor whiteColor] : [UIColor colorWithRed:0.075 green:0.000 blue:0.459 alpha:1.000];
	
	[UIView animateWithDuration:0.1
						  delay:0
						options:(UIViewAnimationOptionAllowUserInteraction)
					 animations:^{
						 [self.backgroundView setBackgroundColor:cellColor];
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
