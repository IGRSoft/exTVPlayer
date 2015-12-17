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

@property (strong, nonatomic) VLCMediaPlayer *mediaplayer;
@property (strong, nonatomic) NSArray *playlist;
@property (assign, nonatomic) NSUInteger currentTrack;

@end

@implementation IGRMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	/* populate array of supported aspect ratios (there are more!) */
	_aspectRatios = @[@"DEFAULT", @"FILL_TO_SCREEN", @"4:3", @"16:9", @"16:10", @"2.21:1"];
	
	/* setup gesture recognizer to toggle controls' visibility */
	_movieView.userInteractionEnabled = NO;
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
																					action:@selector(toggleControlsVisible)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
	
	self.controllerPanel.hidden = self.titlePanel.hidden = YES;
	self.controllerPanel.alpha = self.titlePanel.alpha = 0.0;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	_mediaplayer = [[VLCMediaPlayer alloc] init];
	_mediaplayer.delegate = self;
	_mediaplayer.drawable = self.movieView;
	
	/* listen for notifications from the player */
	//[_mediaplayer addObserver:self forKeyPath:@"time" options:0 context:nil];
	//[_mediaplayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];
	
	[self playCurrentTrack];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (_mediaplayer) {
//		@try {
//			[_mediaplayer removeObserver:self forKeyPath:@"time"];
//			[_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
//		}
//		@catch (NSException *exception) {
//			NSLog(@"we weren't an observer yet");
//		}
		
		if (_mediaplayer.media)
			[_mediaplayer stop];
		
		if (_mediaplayer)
			_mediaplayer = nil;
	}
	
	if (_idleTimer) {
		[_idleTimer invalidate];
		_idleTimer = nil;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition
{
	self.currentTrack = aPosition;
	self.playlist = aPlayList;
}

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
	/* create a media object and give it to the player */
	IGREntityExTrack *track = [[self.playlist[self.currentTrack] objects] firstObject];
	
	self.titleLabel.text = track.name;
	NSURL *url = [NSURL URLWithString:track.location];
	
	_mediaplayer.media = [VLCMedia mediaWithURL:url];
	
	[_mediaplayer play];
	
	if (self.controllerPanel.isHidden)
	{
		[self toggleControlsVisible];
	}
	
	[self _resetIdleTimer];
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
	
//	self.toolbar.hidden = controlsHidden;
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

- (void)_resetIdleTimer
{
	if (!_idleTimer)
		_idleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
													  target:self
													selector:@selector(idleTimerExceeded)
													userInfo:nil
													 repeats:NO];
	else {
		if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 5.0)
			[_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
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

- (void)closePlayback:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - VLCMediaPlayerDelegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
	VLCMediaPlayerState currentState = _mediaplayer.state;
	
	/* distruct view controller on error */
	if (currentState == VLCMediaPlayerStateError || currentState == VLCMediaPlayerStateStopped)
	{
		[self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.0];
	}
	/* or if playback ended */
	else if (currentState == VLCMediaPlayerStateEnded)
	{
		[self performSelector:@selector(playNextTrack:) withObject:nil afterDelay:1.0];
	}
	else if (currentState == VLCMediaPlayerStatePlaying)
	{
		[self.view bringSubviewToFront:self.controllerPanel];
	}
}

-(void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if (presses.anyObject.type == UIPressTypeMenu)
	{
		
	}
	else if (presses.anyObject.type == UIPressTypeUpArrow)
	{

	}
	else if (presses.anyObject.type == UIPressTypeDownArrow)
	{
	}
	else if (presses.anyObject.type == UIPressTypeSelect)
	{
		if (self.controllerPanel.isHidden)
		{
			[self _resetIdleTimer];
		}
		
		[self toggleControlsVisible];
	}
	else if (presses.anyObject.type == UIPressTypePlayPause)
	{
		[self togglePlay];
	}
}

@end
