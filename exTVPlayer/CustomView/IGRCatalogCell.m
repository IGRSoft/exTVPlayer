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
@property (assign, nonatomic) BOOL skipHighlight;

@end

@implementation IGRCatalogCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self initializeLabel];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self initializeLabel];
	}
	
	return self;
}


#pragma mark - Internal methods

- (void)initializeLabel
{
	self.skipHighlight = NO;
}

- (void)prepareForReuse
{
	//self.skipHighlight = _isHighlighted;
}

- (void)setHighlighted:(BOOL)highlighted
{
	if (_isHighlighted == highlighted || self.skipHighlight)
	{
		self.skipHighlight = NO;
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

- (void)setPreviewingDelegate:(id<UIViewControllerPreviewingDelegate>)previewingDelegate
{
	if (!_previewingDelegate)
	{
		_previewingDelegate = previewingDelegate;
		
		UIViewController *controller = (UIViewController *)previewingDelegate;
		controller.definesPresentationContext = YES;
		[controller registerForPreviewingWithDelegate:previewingDelegate sourceView:self.contentView];
	}
}

@end
