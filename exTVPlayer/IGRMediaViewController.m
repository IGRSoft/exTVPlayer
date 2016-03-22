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
#import "IGRSettingsViewController.h"

@import AVFoundation;

static void * const IGRMediaViewControllerContext = (void*)&IGRMediaViewControllerContext;

@interface IGRMediaViewController ()

@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) NSArray *playlist;
@property (nonatomic, assign) IGREntityExTrack *currentTrack;
@property (nonatomic, assign) NSInteger currentTrackPosition;

@property (nonatomic, assign) NSTimeInterval latestPressTimestamp;

@property (nonatomic, assign) BOOL needResumeVideo;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isBuffering;

@property (nonatomic, strong) AVQueuePlayer					*player;
@property (nonatomic, strong) AVPlayerViewController		*playerController;
@property (nonatomic, strong) AVAudioSession				*session;

@end

@implementation IGRMediaViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_session = [AVAudioSession sharedInstance];
	[self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
	
	_playerController = [[AVPlayerViewController alloc] init];
	
	self.playerController.videoGravity = AVLayerVideoGravityResizeAspect;
	
#if	TARGET_OS_IOS
	
	if (AVPictureInPictureController.isPictureInPictureSupported)
	{
		self.playerController.delegate = self.delegate;
		self.playerController.allowsPictureInPicturePlayback = YES;
	}
	self.view.translatesAutoresizingMaskIntoConstraints = YES;
	self.playerController.view.translatesAutoresizingMaskIntoConstraints = YES;
#endif
	
	[self addChildViewController:self.playerController];
	self.playerController.view.frame = self.view.bounds;
	[self.view addSubview:self.playerController.view];
	
	self.isPIP = NO;
	self.isBuffering = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!self.isPIP)
	{
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		/* listen for notifications from the player */
		[defaultCenter addObserver:self
						  selector:@selector(itemDidPlayToEndTime:)
							  name:AVPlayerItemDidPlayToEndTimeNotification
							object:nil];
		
		[defaultCenter addObserver:self
						  selector:@selector(itemFailedToPlayToEnd:)
							  name:AVPlayerItemFailedToPlayToEndTimeNotification
							object:nil];
		
#if	TARGET_OS_TV
		/* listen for notifications from the application */
		[defaultCenter addObserver:self
						  selector:@selector(applicationWillResignActive:)
							  name:kApplicationWillResignActive
							object:nil];
		
		[defaultCenter addObserver:self
						  selector:@selector(applicationDidBecomeActive:)
							  name:kapplicationDidBecomeActive
							object:nil];
#endif
		
		if (!self.isPlaying)
		{
			[self playCurrentTrack];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (!self.isPIP)
	{
		[self prerareViewForDisappear];
	}
}

- (void)prerareViewForDisappear
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeObserverFromUnplayedTracks];
	
	Float64 currentTime = CMTimeGetSeconds(self.player.currentTime);
	if (currentTime > 60)
	{
		self.currentTrack.status = @(IGRTrackState_Half);
		self.currentTrack.position = @(currentTime);
	}

#if	TARGET_OS_TV
	[self.playerController.player pause];
	self.playerController.player = nil;
	self.playerController = nil;
	self.session = nil;
#endif
	
	self.currentTrack.catalog.latestViewedTrack = @(self.currentTrackPosition);
	
	if (MR_DEFAULT_CONTEXT.hasChanges)
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

- (void)removeObserverFromUnplayedTracks
{
	NSUInteger pos = MIN((self.currentTrackPosition + 1), self.playlist.count);
	NSArray *items = [self.playlist subarrayWithRange:NSMakeRange(pos,
																  self.playlist.count - pos)];
	
	for(AVPlayerItem *item in items)
	{
		[self removePlayerItemObservers:item];
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
	self.tracks = aPlayList;
	self.currentTrackPosition = aPosition;
}

- (void)stopPIP
{
	if (self.isPIP)
	{
		self.isPIP = NO;
		
		[self prerareViewForDisappear];
		
		[self.playerController.player pause];
#if	TARGET_OS_IOS
		self.playerController.allowsPictureInPicturePlayback = NO;
#endif
		[self.playerController removeFromParentViewController];
		self.playerController = nil;
	}
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
			//check downloaded files
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

- (void)playNextTrackFromRemoteControl:(BOOL)isFromRemoteControl
{
	if ((self.currentTrackPosition + 1) < self.playlist.count)
	{
		if (isFromRemoteControl)
		{
			[self removeObserverFromUnplayedTracks];
		}
		++self.currentTrackPosition;
		
		if (isFromRemoteControl)
		{
			[self playCurrentTrack];
		}
	}
	else
	{
		[self closePlayback];
	}
}

- (void)playPreviousTrackFromRemoteControl:(BOOL)isFromRemoteControl
{
	if ((self.currentTrackPosition - 1) >= 0)
	{
		if (isFromRemoteControl)
		{
			[self removeObserverFromUnplayedTracks];
		}
		--self.currentTrackPosition;
		
		if (isFromRemoteControl)
		{
			[self playCurrentTrack];
		}
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
	self.isBuffering = YES;
	
	[self updatePlaylist];
	
	NSArray *items = [self.playlist subarrayWithRange:NSMakeRange(self.currentTrackPosition,
																  self.playlist.count - self.currentTrackPosition)];
	
	for(AVPlayerItem *item in items)
	{
		[self addPlayerItemObservers:item];
	}
	
	_player = [[AVQueuePlayer alloc] initWithItems:items];
	self.player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
	
	self.playerController.player = self.player;
	
	[self.player play];
}

- (void)closePlayback
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isPlaying
{
	return self.player.rate != 0 && !self.player.error;
}

#pragma mark - Touches

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	[super pressesEnded:presses withEvent:event];
	
	if (self.isBuffering)
	{
		return;
	}
	
	UIPress *press = presses.anyObject;
	NSTimeInterval deltaTouchTime = [NSDate timeIntervalSinceReferenceDate] - self.latestPressTimestamp;
	NSTimeInterval timeLimit = 0.5; //0.5s
	
	__weak typeof(self) weak = self;
	void (^saveTrackTimePosition)(void) = ^void (void) {
		
		[weak.player pause];
		Float64 currentTime = CMTimeGetSeconds(weak.player.currentTime);
		weak.currentTrack.position = @(currentTime);
	};

	if (press.type == UIPressTypeLeftArrow)
	{
		if (deltaTouchTime < timeLimit)
		{
			saveTrackTimePosition();
			[self playPreviousTrackFromRemoteControl:YES];
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
			saveTrackTimePosition();
			[self playNextTrackFromRemoteControl:YES];
		}
		else
		{
			self.latestPressTimestamp = [NSDate timeIntervalSinceReferenceDate];
		}
	}
}

#pragma mark - NSNotificationCenter

- (void)itemDidPlayToEndTime:(NSNotification*)aNotification
{
	self.currentTrack.status = @(IGRTrackState_Done);
	self.currentTrack.position = @(0.0);
		
	[IGRSettingsViewController removeSavedTrack:self.currentTrack];
	
	[self playNextTrackFromRemoteControl:NO];
}

- (void)itemFailedToPlayToEnd:(NSNotification*)aNotification
{
	[self playNextTrackFromRemoteControl:NO];
}

#if	TARGET_OS_TV
- (void)applicationWillResignActive:(NSNotification *)aNotification
{
	self.needResumeVideo = self.isPlaying;
	[self.player pause];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if (self.needResumeVideo)
	{
		[self.player play];
	}
}
#endif

#pragma mark - Observer Response

- (void)addPlayerItemObservers:(AVPlayerItem *)playerItem
{
	[playerItem addObserver:self
				 forKeyPath:NSStringFromSelector(@selector(status))
					options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
					context:IGRMediaViewControllerContext];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem
{
	@try
	{
		[playerItem removeObserver:self
						forKeyPath:NSStringFromSelector(@selector(status))
						   context:IGRMediaViewControllerContext];
	}
	@catch (NSException *exception)
	{
		NSLog(@"Exception removing observer: %@", exception);
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if (context == IGRMediaViewControllerContext)
	{
		AVPlayerStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		AVPlayerStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
		
		if (newStatus != oldStatus)
		{
			__weak typeof(self) weak = self;
			void (^seekCompletionHandler)(BOOL) = ^void (BOOL finished) {
				
				AVPlayerItem *item = weak.playlist[weak.currentTrackPosition];
				[weak removePlayerItemObservers:item];
				
				weak.isBuffering = NO;
			};
			
			switch (newStatus)
			{
				case AVPlayerItemStatusUnknown:
				{
					NSLog(@"Video player Status Unknown");
					
					seekCompletionHandler(NO);
					
					break;
				}
				case AVPlayerItemStatusReadyToPlay:
				{
					IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
					Float64 lastPosition = MAX(0.0, self.currentTrack.position.floatValue - settings.seekBack.floatValue);
					
					if (lastPosition > 0.0)
					{
						CMTime time = CMTimeMakeWithSeconds(lastPosition, 1);
						
						[self.player seekToTime:time completionHandler:seekCompletionHandler];
					}
					else
					{
						seekCompletionHandler(YES);
					}
					
					break;
				}
				case AVPlayerItemStatusFailed:
				{
					NSLog(@"Video player Status Failed: player item error = %@", self.player.currentItem.error);
					NSLog(@"Video player Status Failed: player error = %@", self.player.error);
					
					seekCompletionHandler(NO);
					
					[self closePlayback];
					
					break;
				}
			}
		}
	}
}

@end
