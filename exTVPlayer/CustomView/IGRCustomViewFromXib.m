//
//  IGRCustomViewFromXib.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/30/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCustomViewFromXib.h"

@interface IGRCustomViewFromXib ()

@property (nonatomic, strong) IGRCustomViewFromXib *customView;

@end

@implementation IGRCustomViewFromXib

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self)
	{
		NSString *className = NSStringFromClass([self class]);
		_customView = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
		
		[self addSubview:_customView];
		
	}
	
	return self;
}

@end
