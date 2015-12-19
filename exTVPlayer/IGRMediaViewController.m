//
//  IGRMediaViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMediaViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <TVVLCKit/TVVLCKit.h>

#import "IGREntityExTrack.h"

@interface IGRMediaViewController () <UIGestureRecognizerDelegate, VLCMediaPlayerDelegate>
{
	BOOL _setPosition;
	BOOL _displayRemainingTime;
	int _currentAspectRatioMask;
	NSArray *_aspectRatios;
	NSTimer *_idleTimer;
}

@property (weak, nonatomic) IBOutlet UIView *movieView;
@property (weak, nonatomic) IBOutlet UIView *controllerPanel;
@property (weak, nonatomic) IBOutlet UIView *titlePanel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *remainingTime;
@property (weak, nonatomic) IBOutlet UIProgressView *progressPosition;

@property (strong, nonatomic) VLCMediaPlayer *mediaplayer;
@property (strong, nonatomic) NSArray *playlist;
@property (assign, nonatomic) NSUInteger currentTrack;
@property (assign, nonatomic) BOOL firstPlay;

@property (assign, nonatomic) CGPoint lastTouchLocation;
@property (assign, nonatomic) BOOL updatingPosition;
@property (assign, nonatomic) BOOL skipState;

@end

@implementation IGRMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	/* populate array of supported aspect ratios (there are more!) */
	_aspectRatios = @[@"DEFAULT", @"FILL_TO_SCREEN", @"4:3", @"16:9", @"16:10", @"2.21:1"];
	
	self.controllerPanel.hidden = self.titlePanel.hidden = YES;
	self.controllerPanel.alpha = self.titlePanel.alpha = 0.0;
	
	self.updatingPosition = NO;
	self.skipState = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	_mediaplayer = [[VLCMediaPlayer alloc] init];
	_mediaplayer.delegate = self;
	_mediaplayer.drawable = self.movieView;
	
	/* listen for notifications from the player */
	[_mediaplayer addObserver:self forKeyPath:@"time" options:0 context:nil];
	[_mediaplayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];
	
	[self playCurrentTrack];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (_mediaplayer) {
		@try {
			[_mediaplayer removeObserver:self forKeyPath:@"time"];
			[_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
		}
		@catch (NSException *exception) {
			NSLog(@"we weren't an observer yet");
		}
		
		if (_mediaplayer.media)
		{
			if (_mediaplayer.position > 0.02 && _mediaplayer.position < 0.98)
			{
				IGREntityExTrack *track = [[self.playlist[self.currentTrack] objects] firstObject];
				track.status = @(IGRTrackState_Half);
				track.position = @(_mediaplayer.position);
				[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
			}
			
			self.skipState = YES;
			[_mediaplayer stop];
		}
		if (_mediaplayer)
		{
			_mediaplayer = nil;
		}
	}
	
	if (_idleTimer)
	{
		[_idleTimer invalidate];
		_idleTimer = nil;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition
{
	self.currentTrack = aPosition;
	self.playlist = aPlayList;
}

#pragma mark - Privat

- (void)playNextTrack:(id)sender
{
	if (++self.currentTrack < self.playlist.count)
	{
		[self playCurrentTrack];
	}
	else
	{
		[self closePlayback:sender];
	}
}

- (void)playCurrentTrack
{
	self.firstPlay = YES;
	/* create a media object and give it to the player */
	IGREntityExTrack *track = [[self.playlist[self.currentTrack] objects] firstObject];
	
	self.titleLabel.text = track.name;
	NSURL *url = [NSURL URLWithString:track.location];
	
	_mediaplayer.media = [VLCMedia mediaWithURL:url];
	
	[_mediaplayer setPosition:track.position.floatValue];
	
	[_mediaplayer play];
	
	if (track.position.floatValue > 0.02 && track.position.floatValue < 0.98)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self setPosition:track.position];
		});
	}
	
	if (self.controllerPanel.isHidden)
	{
		[self toggleControlsVisible];
	}
	
	[self resetIdleTimer];
	
	self.skipState = NO;
}

- (void)togglePlay
{
	if (_mediaplayer.isPlaying)
	{
		[_mediaplayer pause];
	}
	else
	{
		[_mediaplayer play];
	}
}

- (void)closePlayback:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updatePosition:(CGFloat)xDiff
{
	if (xDiff == 0)
	{
		return;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setPosition:) object:nil];
	
	self.updatingPosition = YES;
	
	CGFloat newPosition = self.progressPosition.progress + xDiff / 10000;
	
	newPosition = MIN(1.0, newPosition);
	newPosition = MAX(0.0, newPosition);
	
	self.progressPosition.progress = newPosition;
	
	[self performSelector:@selector(setPosition:) withObject:@(newPosition) afterDelay:1.0];
}

- (void)setPosition:(NSNumber *)newPos
{
	[_mediaplayer setPosition:newPos.floatValue];
	
	if (self.controllerPanel.isHidden)
	{
		[self toggleControlsVisible];
	}
	
	[self resetIdleTimer];
	
	self.updatingPosition = NO;
}

- (void)toggleControlsVisible
{
	BOOL controlsHidden = !self.controllerPanel.hidden;
	
	CGFloat secs = controlsHidden ? 0.3 : 0.1;
	[UIView animateWithDuration:secs animations:^{
		
		self.controllerPanel.alpha = self.titlePanel.alpha = controlsHidden ? 0.0 : 0.8;
		
	} completion:^(BOOL finished) {
		
		self.controllerPanel.hidden = self.titlePanel.hidden = controlsHidden;
	}];
}

#pragma mark - Timer

- (void)resetIdleTimer
{
	if (!_idleTimer)
	{
		_idleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
													  target:self
													selector:@selector(idleTimerExceeded)
													userInfo:nil
													 repeats:NO];
	}
	else
	{
		if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 5.0)
		{
			[_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
		}
	}
}

- (void)idleTimerExceeded
{
	_idleTimer = nil;
	
	if (!self.controllerPanel.isHidden)
	{
		[self toggleControlsVisible];
	}
}

#pragma mark - VLCMediaPlayerDelegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
	VLCMediaPlayerState currentState = _mediaplayer.state;
	
	/* distruct view controller on error */
	if (currentState == VLCMediaPlayerStateError)
	{
		[self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.0];
	}
	/* or if playback ended */
	else if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped)
	{
		if (!self.skipState)
		{
			self.skipState = YES;
			IGREntityExTrack *track = [[self.playlist[self.currentTrack] objects] firstObject];
			track.position = @(0.0);
			track.status = @(IGRTrackState_Done);
			
			[self performSelector:@selector(playNextTrack:) withObject:nil afterDelay:1.0];
		}
	}
	else if (currentState == VLCMediaPlayerStatePlaying)
	{
	}
	else if (currentState == VLCMediaPlayerStatePaused)
	{
	}
}

#pragma mark - Touches

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if (presses.anyObject.type == UIPressTypeSelect)
	{
		if (self.controllerPanel.isHidden)
		{
			[self resetIdleTimer];
		}
		
		[self toggleControlsVisible];
	}
	else if (presses.anyObject.type == UIPressTypePlayPause)
	{
		[self togglePlay];
	}
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	self.lastTouchLocation = CGPointMake(-1, -1);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	for (UITouch *touch in touches)
	{
		CGPoint location = [touch locationInView:self.movieView];
		
		if(self.lastTouchLocation.x == -1 && self.lastTouchLocation.y == -1)
		{
			// Prevent cursor from recentering
			self.lastTouchLocation = location;
		}
		else
		{
			CGFloat xDiff = location.x - self.lastTouchLocation.x;

			if (self.updatingPosition || (!self.updatingPosition && (xDiff < -5.0 || xDiff > 5.0)))
			{
				[self updatePosition:xDiff];
			}
			
			self.lastTouchLocation = location;
		}
		
		// We only use one touch, break the loop
		break;
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (!self.updatingPosition)
	{
		self.progressPosition.progress = [_mediaplayer position];
		
		if (self.progressPosition.progress > 1.0)
		{
			[_mediaplayer stop];
		}
	}
	
	self.remainingTime.text = [[_mediaplayer remainingTime] stringValue];
	self.time.text = [[_mediaplayer time] stringValue];
}

@end
