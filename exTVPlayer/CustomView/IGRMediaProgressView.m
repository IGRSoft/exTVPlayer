//
//  IGRMediaProgressView.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/30/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMediaProgressView.h"

@interface IGRMediaProgressView ()

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (assign, nonatomic) CGFloat progressOffset;
@property (assign, nonatomic) CGFloat progressWidth;

@property (assign, nonatomic) BOOL updatingPosition;

@end

@implementation IGRMediaProgressView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		_progressWidth = self.progressView.bounds.size.width;
		_progressOffset = self.lineView.bounds.size.width;
		
		_remainingTimeLabel.textColor = _timeLabel.textColor = IGR_DARKCOLOR;
		_progressView.progressTintColor = IGR_LIGHTBLUECOLOR;
		
		_updatingPosition = NO;
	}
	
	return self;
}

- (void)setTime:(NSString *)aTime
{
	self.timeLabel.text = aTime;
}

- (void)setRemainingTime:(NSString *)aTime
{
	self.remainingTimeLabel.text = aTime;
}

- (void)setTimePosition:(CGFloat)aPosition
{
	self.progressView.progress = aPosition;
	
	if (!self.updatingPosition)
	{
		CGRect newLineViewRect = self.lineView.frame;
		newLineViewRect.origin.x = self.progressWidth * aPosition - self.progressOffset;
		self.lineView.frame = newLineViewRect;
		
		[self setNeedsDisplay];
	}
}

- (void)setNextTimePosition:(CGFloat)aPosition
{
	if (!self.updatingPosition)
	{
		_updatingPosition = YES;
		
		[UIView animateWithDuration:0.1 animations:^{
			
			self.lineView.alpha = 1.0;
			
		} completion:^(BOOL finished) {
		}];
	}
	
	CGRect newLineViewRect = self.lineView.frame;
	newLineViewRect.origin.x = self.progressWidth * aPosition - self.progressOffset;
	self.lineView.frame = newLineViewRect;
	
	[self setNeedsDisplay];
}

- (void)processNewPosition
{
	[self.delegate updatedProgressPosition:self.progress];
	
	[UIView animateWithDuration:0.1 animations:^{
		
		self.lineView.alpha = 0.0;
		
	} completion:^(BOOL finished) {
	}];
	
	_updatingPosition = NO;
}

- (CGFloat)progress
{
	if (_updatingPosition)
	{
		return (self.lineView.frame.origin.x + self.progressOffset) / self.progressWidth;
	}
	
	return self.progressView.progress;
}

@end
