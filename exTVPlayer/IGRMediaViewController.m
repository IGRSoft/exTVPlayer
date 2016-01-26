//
//  IGRMediaViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMediaViewController.h"
#import "IGRAppDelegate.h"

#import "IGREntityExTrack.h"
#import "IGREntityExCatalog.h"
#import "IGREntityAppSettings.h"

@interface IGRMediaViewController () <UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *gestureView;

@property (strong, nonatomic) NSArray *tracks;
@property (strong, nonatomic) NSArray *playlist;
@property (assign, nonatomic) IGREntityExTrack *currentTrack;
@property (assign, nonatomic) NSInteger currentTrackPosition;

@property (assign, nonatomic) IGRTrackProperties trakProperiesStatus;
@property (assign, nonatomic) NSTimeInterval latestPressTimestamp;

@property (assign, nonatomic) BOOL needResumeVideo;
@property (assign, nonatomic) BOOL isPlaying;

@end

@implementation IGRMediaViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
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
	
	AVPlayer *player = [[AVPlayer alloc] init];
	self.delegate = self;
	self.player = player;
	
	/* listen for notifications from the player */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playFinished:)
												 name:AVPlayerItemDidPlayToEndTimeNotification
											   object:nil];
	
	[self playCurrentTrack];
	
	UIGestureRecognizer *gr = self.gestureView.gestureRecognizers.firstObject;
	gr.allowedPressTypes = @[@(UIPressTypeLeftArrow), @(UIPressTypeRightArrow)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
//	
//	if (_mediaplayer)
//	{
//		@try {
//			[_mediaplayer removeObserver:self forKeyPath:@"time"];
//			[_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
//		}
//		@catch (NSException *exception) {
//			NSLog(@"we weren't an observer yet");
//		}
//		
//		if (_mediaplayer.media)
//		{
//			IGREntityExTrack *track = [self.playlist[self.currentTrack] objects].firstObject;
//			if (_mediaplayer.position > 0.02 && _mediaplayer.position < 0.98)
//			{
//				track.status = @(IGRTrackState_Half);
//				track.position = @(_mediaplayer.position);
//			}
//			
//			track.catalog.latestViewedTrack = @(self.currentTrack);
//			[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
//			
//			self.skipState = YES;
//			[_mediaplayer stop];
//		}
//		
//		_mediaplayer = nil;
//	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Public

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition
{
	self.currentTrackPosition = aPosition;
	self.tracks = aPlayList;
}

#pragma mark - Privat

- (void)updatePlaylist
{
	/* create a media object and give it to the player */
	NSMutableArray *playList = [NSMutableArray arrayWithCapacity:self.tracks.count];
	for (NSUInteger i = 0; i < self.tracks.count; ++i)
	{
		IGREntityExTrack *track = [self.tracks[i] objects].firstObject;
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
		
		AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
		[playList addObject:item];
	}
	
	self.playlist = [NSArray arrayWithArray:playList];
}

- (void)playNextTrack:(id)sender
{
	if ((self.currentTrackPosition + 1) < self.playlist.count)
	{
		++self.currentTrackPosition;
		[self playCurrentTrack];
	}
	else
	{
		[self closePlayback];
	}
}

- (void)playPreviousTrack:(id)sender
{
	if ((self.currentTrackPosition - 1) >= 0)
	{
		--self.currentTrackPosition;
		[self playCurrentTrack];
	}
	else
	{
		[self closePlayback];
	}
}

- (void)setCurrentTrackPosition:(NSInteger)currentTrackPosition
{
	_currentTrackPosition = currentTrackPosition;
	
	self.currentTrack = [self.tracks[currentTrackPosition] objects].firstObject;
}

- (void)playCurrentTrack
{
	[self updatePlaylist];
	
	AVPlayerItem *item = self.playlist[self.currentTrackPosition];
	[self.player replaceCurrentItemWithPlayerItem:item];
	[self.player play];
	
	if (self.currentTrack.position.floatValue > 0.02)
	{
		CMTime time = CMTimeMakeWithSeconds(self.currentTrack.position.floatValue, 1);
		[self.player seekToTime:time];
	}
	
	self.trakProperiesStatus = IGRTrackProperties_None;
}

- (void)closePlayback
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isPlaying
{
	return self.player.rate != 0 && !self.player.error;
}

#pragma mark - NSNotification

- (void)playFinished:(NSNotification*)nstification
{
	[self playNextTrack:nil];
}

#pragma mark - AVPlayerViewControllerDelegate

- (void)playerViewController:(AVPlayerViewController *)playerViewController didPresentInterstitialTimeRange:(AVInterstitialTimeRange *)interstitial
{
	
}

#pragma mark - VLCMediaPlayerDelegate

//- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
//{
//	VLCMediaPlayer *mediaplayer = aNotification.object;
//	VLCMediaPlayerState currentState = mediaplayer.state;
//	
//	/* distruct view controller on error */
//	if (currentState == VLCMediaPlayerStateError)
//	{
//		[self performSelector:@selector(closePlayback) withObject:nil afterDelay:2.0];
//	}
//	/* or if playback ended */
//	else if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped)
//	{
//		if (!self.skipState)
//		{
//			self.skipState = YES;
//			IGREntityExTrack *track = [self.playlist[self.currentTrack] objects].firstObject;
//			track.position = @(0.0);
//			track.status = @(IGRTrackState_Done);
//			
//			[self performSelector:@selector(playNextTrack:) withObject:nil afterDelay:1.0];
//		}
//	}
//	else if (currentState == VLCMediaPlayerStatePlaying)
//	{
//	}
//	else if (currentState == VLCMediaPlayerStatePaused)
//	{
//	}
//}
//
//- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification
//{
//	if (self.trakProperiesStatus == IGRTrackProperties_None)
//	{
//		self.trakProperiesStatus = IGRTrackProperties_Setuped;
//	}
//}

#pragma mark - Touches

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
//	if (self.trakProperiesStatus == IGRTrackProperties_None)
//	{
//		return;
//	}
	
	[super pressesEnded:presses withEvent:event];
	
	UIPress *press = presses.anyObject;
	NSTimeInterval deltaTouchTime = [NSDate timeIntervalSinceReferenceDate] - self.latestPressTimestamp;
	NSTimeInterval timeLimit = 0.5; //0.5s
	
	if (press.type == UIPressTypeLeftArrow)
	{
		if (deltaTouchTime < timeLimit)
		{
			[self playPreviousTrack:nil];
		}
		else
		{
			self.latestPressTimestamp = [NSDate timeIntervalSinceReferenceDate];
		}
	}
	else if (press.type == UIPressTypeRightArrow)
	{
		if (deltaTouchTime < timeLimit)
		{
			[self playNextTrack:nil];
		}
		else
		{
			self.latestPressTimestamp = [NSDate timeIntervalSinceReferenceDate];
		}
	}
}

#pragma mark - KVO

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//	CGFloat position = _mediaplayer.position;
//	[self.mediaProgressView setTimePosition:position];
//	
//	if (position > 1.0)
//	{
//		[_mediaplayer stop];
//	}
//	
//	[self.mediaProgressView setRemainingTime:_mediaplayer.remainingTime.stringValue];
//	[self.mediaProgressView setTime:_mediaplayer.time.stringValue];
//}
//
- (void)applicationWillResignActive:(NSNotification *)aNotification
{
	self.needResumeVideo = self.isPlaying;
	if (self.isPlaying)
	{
		[self.player pause];
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if (self.needResumeVideo)
	{
		[self.player play];
	}
}

@end
