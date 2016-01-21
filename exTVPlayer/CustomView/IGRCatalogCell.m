//
//  IGRCatalogCell.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCatalogCell.h"

@interface IGRCatalogCell ()

@property (weak  , nonatomic) IBOutlet UIImageView *isFavorit;

@end

@implementation IGRCatalogCell

- (void)setHighlighted:(BOOL)highlighted
{
	if (_isHighlighted == highlighted)
	{
		return;
	}
	
	_isHighlighted = highlighted;
	
	super.highlighted = highlighted;
}

- (void)setFavorit:(BOOL)isFavorit
{
	_favorit = isFavorit;
	
	self.isFavorit.image = isFavorit ? [UIImage imageNamed:@"favorit-on"] : [UIImage imageNamed:@"favorit-off"];
	[self setNeedsDisplay];
}

@end
