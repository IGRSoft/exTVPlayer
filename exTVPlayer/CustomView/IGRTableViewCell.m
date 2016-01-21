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
	super.highlighted = highlighted;
	
	UIColor *cellColor = highlighted ?  [UIColor colorWithRed:0.015 green:0.250 blue:0.900 alpha:1.000] :
										[UIColor whiteColor];
	
	UIColor *textColor = highlighted ?  [UIColor whiteColor] : [UIColor colorWithRed:0.020 green:0.200 blue:0.520 alpha:1.000];
	
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
