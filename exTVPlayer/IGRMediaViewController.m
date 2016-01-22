//
//  IGRMediaViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMediaViewController.h"
#import "IGRMediaProgressView.h"
#import "IGRAppDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <TVVLCKit/TVVLCKit.h>

#import "IGREntityExTrack.h"
#import "IGREntityExCatalog.h"
#import "IGREntityAppSettings.h"

@interface IGRMediaViewController () <UIGestureRecognizerDelegate, VLCMediaPlayerDelegate, IGRMediaProgressDelegate>
{
	NSTimer *_idleTimer;
}

@property (weak, nonatomic) IBOutlet UIView *movieView;
@property (weak, nonatomic) IBOutlet IGRMediaProgressView *mediaProgressView;
@property (weak, nonatomic) IBOutlet UIView *titlePanel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) VLCMediaPlayer *mediaplayer;
@property (strong, nonatomic) NSArray *playlist;
@property (assign, nonatomic) NSInteger currentTrack;

@property (assign, nonatomic) IGRTrackProperties trakProperiesStatus;
@property (strong, nonatomic) NSArray *aspectRatios;

@property (assign, nonatomic) CGPoint lastTouchLocation;
@property (assign, nonatomic) NSTimeInterval latestPressTimestamp;
@property (assign, nonatomic) BOOL updatingPosition;
@property (assign, nonatomic) BOOL skipState;

@property (assign, nonatomic) BOOL needResumeVideo;

@end

@implementation IGRMediaViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	/* populate array of supported aspect ratios (there are more!) */
	self.aspectRatios = @[NSLocalizedString(@"Default", @""), @"16:9", @"4:3", @"1:1", @"16:10", @"2.21:1", @"2.35:1", @"2.39:1", @"5:4"];
	
	self.mediaProgressView.hidden = self.titlePanel.hidden = YES;
	self.mediaProgressView.alpha = self.titlePanel.alpha = 0.0;
	
	self.updatingPosition = NO;
	self.skipState = NO;
	self.trakProperiesStatus = IGRTrackProperties_None;
	self.mediaProgressView.delegate = self;
	self.latestPressTimestamp = 0.0;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillResignActive:)
												 name:kApplicationWillResignActive
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidBecomeActive:)
												 name:kapplicationDidBecomeActive
											   object:nil];
	
	_mediaplayer = [[VLCMediaPlayer alloc] initWithOptions:[self defaultVLCOptions]];
	_mediaplayer.delegate = self;
	_mediaplayer.drawable = self.movieView;
	
	/* listen for notifications from the player */
	[_mediaplayer addObserver:self forKeyPath:@"time" options:0 context:nil];
	[_mediaplayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];
	
	[self playCurrentTrack];
	
	UIGestureRecognizer *gr = (self.view).gestureRecognizers.firstObject;
	gr.allowedPressTypes = @[@(UIPressTypeLeftArrow), @(UIPressTypeRightArrow), @(UIPressTypePlayPause), @(UIPressTypeMenu)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (_mediaplayer)
	{
		@try {
			[_mediaplayer removeObserver:self forKeyPath:@"time"];
			[_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
		}
		@catch (NSException *exception) {
			NSLog(@"we weren't an observer yet");
		}
		
		if (_mediaplayer.media)
		{
			IGREntityExTrack *track = [self.playlist[self.currentTrack] objects].firstObject;
			if (_mediaplayer.position > 0.02 && _mediaplayer.position < 0.98)
			{
				track.status = @(IGRTrackState_Half);
				track.position = @(_mediaplayer.position);
			}
			
			track.catalog.latestViewedTrack = @(self.currentTrack);
			[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
			
			self.skipState = YES;
			[_mediaplayer stop];
		}
		
		_mediaplayer = nil;
	}
	
	[self invalidateTimer];
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
	if ((self.currentTrack + 1) < self.playlist.count)
	{
		++self.currentTrack;
		[self playCurrentTrack];
	}
	else
	{
		[self closePlayback];
	}
}

- (void)playPreviousTrack:(id)sender
{
	if ((self.currentTrack - 1) >= 0)
	{
		--self.currentTrack;
		[self playCurrentTrack];
	}
	else
	{
		[self closePlayback];
	}
}

- (void)playCurrentTrack
{
	/* create a media object and give it to the player */
	IGREntityExTrack *track = [self.playlist[self.currentTrack] objects].firstObject;
	
	self.titleLabel.text = track.name;
	
	NSURL *url = [NSURL URLWithString:track.webPath];
	if (track.localName.length)
	{
		url = [[IGRAppDelegate videoFolder] URLByAppendingPathComponent:track.localName];
		if (![[NSFileManager defaultManager] fileExistsAtPath:url.path])
		{
			url = [NSURL URLWithString:track.webPath];
			track.localName = nil;
			track.dataStatus = @(IGRTrackDataStatus_Web);
		}
	}
	
	_mediaplayer.media = [VLCMedia mediaWithURL:url];
	_mediaplayer.position = track.position.floatValue;
	[_mediaplayer play];
		
	if (track.position.floatValue > 0.02 && track.position.floatValue < 0.98)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self setMediaPosition:track.position.floatValue];
		});
	}
	
	if (self.mediaProgressView.isHidden)
	{
		[self toggleControlsVisible];
	}
	
	[self resetIdleTimer];
	
	self.skipState = NO;
	self.trakProperiesStatus = IGRTrackProperties_None;
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

- (void)closePlayback
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updatePosition:(CGFloat)xDiff
{
	if (xDiff == 0)
	{
		return;
	}
		
	self.updatingPosition = YES;
	
	CGFloat newPosition = self.mediaProgressView.progress + xDiff / 10000;
	
	newPosition = MIN(1.0, newPosition);
	newPosition = MAX(0.0, newPosition);
	
	[self.mediaProgressView setNextTimePosition:newPosition];
	
	if (self.mediaProgressView.isHidden)
	{
		[self toggleControlsVisible];
	}
	
	[self resetIdleTimer];
}

- (void)setMediaPosition:(CGFloat)newPos
{
	_mediaplayer.position = newPos;
	
	self.updatingPosition = NO;
}

- (void)toggleControlsVisible
{
	BOOL controlsHidden = !self.mediaProgressView.hidden;
	
	CGFloat secs = controlsHidden ? 0.3 : 0.1;
	[UIView animateWithDuration:secs animations:^{
		
		self.mediaProgressView.alpha = self.titlePanel.alpha = controlsHidden ? 0.0 : 0.8;
		
	} completion:^(BOOL finished) {
		
		self.mediaProgressView.hidden = self.titlePanel.hidden = controlsHidden;
	}];
}

- (NSArray *)defaultVLCOptions
{
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
	NSString *fileCacheOption = [NSString stringWithFormat:@"--file-caching=%@", @(settings.videoBufferSize.floatValue / 3.0)];
	NSString *discCacheOption = [NSString stringWithFormat:@"--disc-caching=%@", @(settings.videoBufferSize.floatValue / 3.0)];
	NSString *liveCacheOption = [NSString stringWithFormat:@"--live-caching=%@", @(settings.videoBufferSize.floatValue / 3.0)];
	NSString *networkCacheOption = [NSString stringWithFormat:@"--network-caching=%@", settings.videoBufferSize];
	
	NSArray *vlcParams = @[@"--no-color",
						   @"--no-osd",
						   @"--no-video-title-show",
						   @"--no-stats",
						   @"--no-snapshot-preview",
#ifndef NOSCARYCODECS
						   @"--avcodec-fast",
#endif
						   @"--text-renderer=freetype",
						   @"--avi-index=3",
						   @"--extraintf=ios_dialog_provider",
						   fileCacheOption,
						   discCacheOption,
						   liveCacheOption,
						   networkCacheOption];
	return vlcParams;
}

#pragma mark - Trak Properties

- (void)showTrackProperties
{
	if (self.trakProperiesStatus == IGRTrackProperties_Setuped)
	{
		self.trakProperiesStatus = IGRTrackProperties_InConfiguration;
		
		if (_mediaplayer.isPlaying)
		{
			[_mediaplayer pause];
		}
		
		UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Track Properties", @"")
																	  message:@""
															   preferredStyle:UIAlertControllerStyleActionSheet];
		
		__weak typeof(self) weak = self;
		UIAlertAction* audioTrack = [UIAlertAction actionWithTitle:NSLocalizedString(@"Audio Tracks", @"")
															 style:UIAlertActionStyleDefault
														   handler:^(UIAlertAction * action) {
															   
															   [view dismissViewControllerAnimated:YES completion:nil];
															   
															   [weak showAudioTrackProperties];
															   
														   }];
		
		UIAlertAction* aspectRatios = [UIAlertAction actionWithTitle:NSLocalizedString(@"Video Aspect Ratios", @"")
															   style:UIAlertActionStyleDefault
															 handler:^(UIAlertAction * action) {
																 
																 [view dismissViewControllerAnimated:YES completion:nil];
																 
																 [weak showVideoAspectRatiosProperties];
															 }];
		
		UIAlertAction* subtitles = [UIAlertAction actionWithTitle:NSLocalizedString(@"Subtitles", @"")
															style:UIAlertActionStyleDefault
															 handler:^(UIAlertAction * action) {
																 
																 [view dismissViewControllerAnimated:YES completion:nil];
																 
																 [weak showSubtitlesProperties];
															 }];
		
		UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
														 style:UIAlertActionStyleCancel
													   handler:^(UIAlertAction * action) {
														   
														   weak.trakProperiesStatus = IGRTrackProperties_Setuped;
														   
														   [view dismissViewControllerAnimated:YES completion:nil];
													   }];
		
		
		[view addAction:audioTrack];
		[view addAction:aspectRatios];
		[view addAction:subtitles];
		
		[view addAction:cancel];
		[self presentViewController:view animated:YES completion:nil];
	}
}

- (void)showAudioTrackProperties
{
	UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Audio Tracks", @"")
																  message:@""
														   preferredStyle:UIAlertControllerStyleActionSheet];
	
	__weak typeof(self) weak = self;
	for (NSUInteger i = 0; i < _mediaplayer.numberOfAudioTracks; ++i)
	{
		UIAlertAction* audioTrack = [UIAlertAction actionWithTitle:_mediaplayer.audioTrackNames[i]
															 style:UIAlertActionStyleDefault
														   handler:^(UIAlertAction * action) {
															   //Do some thing here
															   int audioTrackPosition = (int)[weak.mediaplayer.audioTrackNames indexOfObject:action.title];
															   
															   weak.mediaplayer.currentAudioTrackIndex = audioTrackPosition;
															   weak.trakProperiesStatus = IGRTrackProperties_Setuped;
															   
															   [view dismissViewControllerAnimated:YES completion:nil];
															   
														   }];
		
		[view addAction:audioTrack];
	}
	
	UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
													 style:UIAlertActionStyleCancel
												   handler:^(UIAlertAction * action)
							 {
								 weak.trakProperiesStatus = IGRTrackProperties_Setuped;
								 
								 [view dismissViewControllerAnimated:YES completion:nil];
							 }];
	
	
	[view addAction:cancel];
	[self presentViewController:view animated:YES completion:nil];
}

- (void)showVideoAspectRatiosProperties
{
	UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Video Aspect Ratios", @"")
																  message:@""
														   preferredStyle:UIAlertControllerStyleActionSheet];
	
	__weak typeof(self) weak = self;
	for (NSUInteger i = 0; i < self.aspectRatios.count; ++i)
	{
		UIAlertAction* audioTrack = [UIAlertAction actionWithTitle:self.aspectRatios[i]
															 style:UIAlertActionStyleDefault
														   handler:^(UIAlertAction * action) {
															   //Do some thing here
															   int aspectRatioPosition = (int)[self.aspectRatios indexOfObject:action.title];
															   
															   if (aspectRatioPosition == 0)
															   {
																   weak.mediaplayer.videoAspectRatio = NULL;
																   weak.mediaplayer.videoCropGeometry = NULL;
															   }
															   else
															   {
																   weak.mediaplayer.videoCropGeometry = NULL;
																   weak.mediaplayer.videoAspectRatio = (char *)(action.title).UTF8String;
															   }
															   
															   weak.trakProperiesStatus = IGRTrackProperties_Setuped;
															   
															   [view dismissViewControllerAnimated:YES completion:nil];
															   
														   }];
		
		[view addAction:audioTrack];
	}
	
	UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
													 style:UIAlertActionStyleCancel
												   handler:^(UIAlertAction * action)
							 {
								 weak.trakProperiesStatus = IGRTrackProperties_Setuped;
								 
								 [view dismissViewControllerAnimated:YES completion:nil];
							 }];
	
	
	[view addAction:cancel];
	[self presentViewController:view animated:YES completion:nil];
}

- (void)showSubtitlesProperties
{
	UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Subtitles", @"")
																  message:@""
														   preferredStyle:UIAlertControllerStyleActionSheet];
	
	__weak typeof(self) weak = self;
	for (NSUInteger i = 0; i < _mediaplayer.numberOfSubtitlesTracks; ++i)
	{
		UIAlertAction* audioTrack = [UIAlertAction actionWithTitle:_mediaplayer.videoSubTitlesNames[i]
															 style:UIAlertActionStyleDefault
														   handler:^(UIAlertAction * action) {
															   //Do some thing here
															   int subTitlePosition = (int)[weak.mediaplayer.videoSubTitlesNames indexOfObject:action.title];
															   
															   weak.mediaplayer.currentVideoSubTitleIndex = subTitlePosition;
															   weak.trakProperiesStatus = IGRTrackProperties_Setuped;
															   
															   [view dismissViewControllerAnimated:YES completion:nil];
															   
														   }];
		
		[view addAction:audioTrack];
	}
	
	UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
													 style:UIAlertActionStyleCancel
												   handler:^(UIAlertAction * action)
							 {
								 weak.trakProperiesStatus = IGRTrackProperties_Setuped;
								 
								 [view dismissViewControllerAnimated:YES completion:nil];
							 }];
	
	
	[view addAction:cancel];
	[self presentViewController:view animated:YES completion:nil];
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
		if (fabs((_idleTimer.fireDate).timeIntervalSinceNow) < 5.0)
		{
			_idleTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
		}
	}
}

- (void)idleTimerExceeded
{
	_idleTimer = nil;
	
	if (!self.mediaProgressView.isHidden)
	{
		[self toggleControlsVisible];
	}
}

- (void)invalidateTimer
{
	if (_idleTimer)
	{
		[_idleTimer invalidate];
		_idleTimer = nil;
	}
	
}

#pragma mark - VLCMediaPlayerDelegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
	VLCMediaPlayer *mediaplayer = aNotification.object;
	VLCMediaPlayerState currentState = mediaplayer.state;
	
	/* distruct view controller on error */
	if (currentState == VLCMediaPlayerStateError)
	{
		[self performSelector:@selector(closePlayback) withObject:nil afterDelay:2.0];
	}
	/* or if playback ended */
	else if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped)
	{
		if (!self.skipState)
		{
			self.skipState = YES;
			IGREntityExTrack *track = [self.playlist[self.currentTrack] objects].firstObject;
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

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification
{
	if (self.trakProperiesStatus == IGRTrackProperties_None)
	{
		self.trakProperiesStatus = IGRTrackProperties_Setuped;
	}
}

#pragma mark - IGRMediaProgressDelegate

- (void)updatedProgressPosition:(CGFloat)aProgressPosition
{
	[self setMediaPosition:aProgressPosition];
}

#pragma mark - Touches

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if (self.trakProperiesStatus == IGRTrackProperties_None)
	{
		return;
	}
	
	UIPress *press = presses.anyObject;
	NSInteger deltaTouchTime = press.timestamp - self.latestPressTimestamp;
	NSInteger timeLimit = CLOCKS_PER_SEC * 500; //0.5s
	
	if (press.type == UIPressTypeSelect)
	{
		[self togglePlay];
		
		if (_mediaplayer.isPlaying && !self.mediaProgressView.hidden)
		{
			//do nothing
		}
		else
		{
			[self toggleControlsVisible];
		}
		
		[self resetIdleTimer];
	}
	else if (press.type == UIPressTypePlayPause)
	{
		[self togglePlay];
	}
	else if (press.type == UIPressTypeLeftArrow && deltaTouchTime < timeLimit)
	{
		[self playPreviousTrack:nil];
	}
	else if (press.type == UIPressTypeRightArrow && deltaTouchTime < timeLimit)
	{
		[self playNextTrack:nil];
	}
	
	self.latestPressTimestamp = press.timestamp;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	self.lastTouchLocation = CGPointMake(-1, -1);
	
	if (self.updatingPosition)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self.mediaProgressView
												 selector:@selector(processNewPosition)
												   object:nil];
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	if (self.trakProperiesStatus == IGRTrackProperties_InConfiguration)
	{
		return;
	}
	
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
			
			if (self.updatingPosition || (!self.updatingPosition && (xDiff < -35.0 || xDiff > 35.0)))
			{
				[self updatePosition:xDiff];
			}
			
			if (!self.updatingPosition)
			{
				CGFloat yDiff = location.y - self.lastTouchLocation.y;
				
				if (yDiff > 45.0)
				{
					[self showTrackProperties];
				}
			}
			
			self.lastTouchLocation = location;
		}
		
		// We only use one touch, break the loop
		break;
	}
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
	if (self.updatingPosition)
	{
		[self.mediaProgressView performSelector:@selector(processNewPosition) withObject:nil afterDelay:1.0];
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	CGFloat position = _mediaplayer.position;
	[self.mediaProgressView setTimePosition:position];
	
	if (position > 1.0)
	{
		[_mediaplayer stop];
	}
	
	[self.mediaProgressView setRemainingTime:_mediaplayer.remainingTime.stringValue];
	[self.mediaProgressView setTime:_mediaplayer.time.stringValue];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
	if (_mediaplayer.playing)
	{
		[_mediaplayer pause];
	}
	
	self.needResumeVideo = _mediaplayer.playing;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if (self.needResumeVideo)
	{
		[_mediaplayer play];
	}
}

@end
