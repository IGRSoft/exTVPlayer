//
//  IGRUpdateView.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 3/18/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRUpdateView.h"
@import QuartzCore;

@interface IGRUpdateView ()

@property (strong, nonatomic) UIView *customView;
@property (weak  , nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation IGRUpdateView

- (void)setupView
{
	self.layer.cornerRadius = 10;
	self.layer.masksToBounds = YES;
	self.layer.borderColor = IGR_DARKBLUECOLORALPHA.CGColor;
	self.layer.borderWidth = 2.0;
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = self.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithWhite:0.900 alpha:0.900] CGColor], (id)[[UIColor colorWithWhite:0.900 alpha:0.900] CGColor],nil];
	[self.layer insertSublayer:gradient atIndex:0];
}

- (void)startUpdating
{
	if (self.activityIndicator.isAnimating)
	{
		return;
	}
	
	[self.activityIndicator startAnimating];
	
	CGRect newFect = self.frame;
	newFect.origin.y -= (newFect.size.height - 10);
	
	__weak typeof(self) weak = self;
	[UIView animateWithDuration:kReloadTime animations:^{
		
		weak.frame = newFect;
	}];
}

- (void)stopUpdating
{
	if (!self.activityIndicator.isAnimating)
	{
		return;
	}
	
	CGRect newFect = self.frame;
	newFect.origin.y += (newFect.size.height - 10);
	
	__weak typeof(self) weak = self;
	[UIView animateWithDuration:kReloadTime animations:^{
		
		weak.frame = newFect;
	} completion:^(BOOL finished) {
		
		[weak.activityIndicator stopAnimating];
	}];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		NSString *className = NSStringFromClass([self class]);
		_customView = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
		
		if(CGRectIsEmpty(frame))
		{
			self.frame = _customView.frame;
			self.bounds = _customView.bounds;
		}
		
		[self addSubview:_customView];
		[self setupView];
	}
	
	return self;
}

@end
