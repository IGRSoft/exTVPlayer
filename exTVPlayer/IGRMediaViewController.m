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
	
	AVPlayer *player = [[AVPlayer alloc] init];
	self.delegate = self;
	self.player = player;
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	/* listen for notifications from the application */
	[defaultCenter addObserver:self
					  selector:@selector(applicationWillResignActive:)
						  name:kApplicationWillResignActive
						object:nil];
	
	[defaultCenter addObserver:self
					  selector:@selector(applicationDidBecomeActive:)
						  name:kapplicationDidBecomeActive
						object:nil];
	
	/* listen for notifications from the player */
	[defaultCenter addObserver:self
					  selector:@selector(itemDidPlayToEndTime:)
						  name:AVPlayerItemDidPlayToEndTimeNotification
						object:nil];
	
	[defaultCenter addObserver:self
					  selector:@selector(itemFailedToPlayToEnd:)
						  name:AVPlayerItemFailedToPlayToEndTimeNotification
						object:nil];
	
	[self playCurrentTrack];
	
	UIGestureRecognizer *gr = self.gestureView.gestureRecognizers.firstObject;
	gr.allowedPressTypes = @[@(UIPressTypeLeftArrow), @(UIPressTypeRightArrow)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (self.isPlaying)
	{
		[self.player pause];
		
		Float64 currentTime = CMTimeGetSeconds(self.player.currentTime);
		if (currentTime > 60)
		{
			self.currentTrack.status = @(IGRTrackState_Half);
			self.currentTrack.position = @(currentTime);
		}
		
		self.currentTrack.catalog.latestViewedTrack = @(self.currentTrackPosition);
		[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
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
	
	Float64 lastPosition = MIN(0, self.currentTrack.position.floatValue - 10.0); //run back 10 sec
	CMTime time = CMTimeMakeWithSeconds(lastPosition, 1);
	[self.player seekToTime:time];
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

#pragma mark - NSNotificationCenter

- (void)itemDidPlayToEndTime:(NSNotification*)nstification
{
	self.currentTrack.status = @(IGRTrackState_Done);
	self.currentTrack.position = @(0.0);
	
	[self playNextTrack:nil];
}

- (void)itemFailedToPlayToEnd:(NSNotification*)nstification
{
	[self playNextTrack:nil];
}

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

@end
