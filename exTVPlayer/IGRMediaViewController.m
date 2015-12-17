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

#import "IGRExTrack.h"

@interface IGRMediaViewController () <UIGestureRecognizerDelegate, VLCMediaPlayerDelegate>
{
	VLCMediaPlayer *_mediaplayer;
	BOOL _setPosition;
	BOOL _displayRemainingTime;
	int _currentAspectRatioMask;
	NSArray *_aspectRatios;
//	UIActionSheet *_audiotrackActionSheet;
//	UIActionSheet *_subtitleActionSheet;
	NSURL *_url;
	NSTimer *_idleTimer;
}

@property (weak, nonatomic) IBOutlet UIView *movieView;

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
	[self.movieView addGestureRecognizer:tapRecognizer];
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
	
	/* create a media object and give it to the player */
	_mediaplayer.media = [VLCMedia mediaWithURL:_url];
	
	[_mediaplayer play];
	
//	if (self.controllerPanel.hidden)
//		[self toggleControlsVisible];
//	
//	[self _resetIdleTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition
{
	self.currentTrack = aPosition;
	self.playlist = aPlayList;
	
	IGRExTrack *track = self.playlist[self.currentTrack];
	
	_url = [NSURL URLWithString:track.location];
}

- (void)toggleControlsVisible
{
//	BOOL controlsHidden = !self.controllerPanel.hidden;
//	self.controllerPanel.hidden = controlsHidden;
//	self.toolbar.hidden = controlsHidden;
//	[[UIApplication sharedApplication] setStatusBarHidden:controlsHidden withAnimation:UIStatusBarAnimationFade];
}

@end
