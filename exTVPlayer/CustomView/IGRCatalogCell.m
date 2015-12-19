//
//  IGRCatalogCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCatalogCell.h"

@implementation IGRCatalogCell

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	
	UIColor *cellColor = highlighted ?  [UIColor colorWithRed:213/255.0f green:232/255.0f blue:255/255.0f alpha:1] :
	[UIColor whiteColor];
	[UIView animateWithDuration:0.1
						  delay:0
						options:(UIViewAnimationOptionAllowUserInteraction)
					 animations:^{
						 [self.backgroundView setBackgroundColor:cellColor];
					 }
					 completion:nil];
}

@end
