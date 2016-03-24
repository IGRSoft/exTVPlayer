//
//  IGRSettingsViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRSettingsViewController.h"
#import "IGRAppDelegate.h"
#import "IGREntityExTrack.h"

@interface IGRSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *sourceButton;
@property (weak, nonatomic) IBOutlet UIButton *languageCategoryButton;
@property (weak, nonatomic) IBOutlet UIButton *historySizeButton;
@property (weak, nonatomic) IBOutlet UIButton *removePlayedSavedTracksButton;
@property (weak, nonatomic) IBOutlet UIButton *seekBackButton;

@property (strong, nonatomic) NSArray *sources;
@property (strong, nonatomic) NSArray *languagesCategory;
@property (strong, nonatomic) NSArray *caches;
@property (strong, nonatomic) NSArray *history;
@property (strong, nonatomic) NSArray *savedTrackOptions;
@property (strong, nonatomic) NSArray *seekBack;

@end

typedef NS_ENUM(NSUInteger, IGRSettingsType)
{
	IGRSettingsType_Source	= 0,
	IGRSettingsType_LanguageCategory,
	IGRSettingsType_History,
	IGRSettingsType_RemovePlayedSavedTracks,
	IGRSettingsType_SeekBack
};

@implementation IGRSettingsViewController

- (void)viewDidLoad
{
	self.sources = @[
					@{@"value": @(IGRSourceType_RSS),	@"name": NSLocalizedString(@"SourceType_RSS", nil)},
					@{@"value": @(IGRSourceType_Live),	@"name": NSLocalizedString(@"SourceType_Live", nil)}
					];
	
	self.languagesCategory = @[
					   @{@"value": @(IGRVideoCategory_Rus), @"name": @"Русский"},
					   @{@"value": @(IGRVideoCategory_Ukr), @"name": @"Укрїнський"},
					   @{@"value": @(IGRVideoCategory_Eng), @"name": @"English"},
					   @{@"value": @(IGRVideoCategory_Esp), @"name": @"Española"},
					   @{@"value": @(IGRVideoCategory_De),  @"name": @"Deutsch"},
					   @{@"value": @(IGRVideoCategory_Pl),  @"name": @"Polskie"}
					   ];
	
	self.history = @[@{@"value": @(IGRHistorySize_5),	@"name": @(IGRHistorySize_5).stringValue},
					 @{@"value": @(IGRHistorySize_10),	@"name": @(IGRHistorySize_10).stringValue},
					 @{@"value": @(IGRHistorySize_20),	@"name": @(IGRHistorySize_20).stringValue},
					 @{@"value": @(IGRHistorySize_50),	@"name": @(IGRHistorySize_50).stringValue}
					];
	
	self.savedTrackOptions = @[
					 @{@"value": @YES,	@"name": NSLocalizedString(@"YES", nil)},
					 @{@"value": @NO,	@"name": NSLocalizedString(@"NO", nil)}
					 ];
	
	self.seekBack = @[@{@"value": @(IGRSeekBack_0),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_0), NSLocalizedString(@"Sec", nil)]},
					  @{@"value": @(IGRSeekBack_5),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_5), NSLocalizedString(@"Sec", nil)]},
					  @{@"value": @(IGRSeekBack_10),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_10), NSLocalizedString(@"Sec", nil)]},
					  @{@"value": @(IGRSeekBack_15),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_15), NSLocalizedString(@"Sec", nil)]},
					  @{@"value": @(IGRSeekBack_30),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_30), NSLocalizedString(@"Sec", nil)]},
					  @{@"value": @(IGRSeekBack_60),
						@"name": [NSString stringWithFormat:@"%@%@", @(IGRSeekBack_60), NSLocalizedString(@"Sec", nil)]},
					 ];
	
	[self updateViews];
	
	[super viewDidLoad];
}

- (void)updateViews
{
	[self updateViewForSettings:IGRSettingsType_Source from:self.sourceButton];
	[self updateViewForSettings:IGRSettingsType_LanguageCategory from:self.languageCategoryButton];
	[self updateViewForSettings:IGRSettingsType_History from:self.historySizeButton];
	[self updateViewForSettings:IGRSettingsType_RemovePlayedSavedTracks from:self.removePlayedSavedTracksButton];
	[self updateViewForSettings:IGRSettingsType_SeekBack from:self.seekBackButton];
}

- (void)viewWillAppear:(BOOL)animated
{
#if	TARGET_OS_IOS
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	/* listen for notifications from the player */
	[defaultCenter addObserver:self
					  selector:@selector(didMergeChangesFromiCloud:)
						  name:MagicalRecordDidMergeChangesFromiCloudNotification
						object:nil];
#endif
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateSettingsFor:(IGRSettingsType)aSettingsType
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *settingsId = nil;
	NSArray *settingsData = nil;
	
	switch (aSettingsType)
	{
		case IGRSettingsType_Source:
		{
			settingsId = settings.sourceType;
			settingsData = self.sources;
		}
			break;
		case IGRSettingsType_LanguageCategory:
		{
			settingsId = settings.videoLanguageId;
			settingsData = self.languagesCategory;
		}
			break;
		case IGRSettingsType_History:
		{
			settingsId = settings.historySize;
			settingsData = self.history;
		}
			break;
		case IGRSettingsType_RemovePlayedSavedTracks:
		{
			settingsId = settings.removPlayedSavedTracks;
			settingsData = self.savedTrackOptions;
		}
			break;
		case IGRSettingsType_SeekBack:
		{
			settingsId = settings.seekBack;
			settingsData = self.seekBack;
		}
			break;
	}
	
	NSUInteger pos = [settingsData indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		BOOL result = [obj[@"value"] isEqualToNumber:settingsId];
		*stop = result;
		
		return result;
	}];
	
	pos = ((pos + 1) == settingsData.count) ? 0 : ++pos;
	
	NSDictionary *newSettings = settingsData[pos];
	
	switch (aSettingsType)
	{
		case IGRSettingsType_Source:
		{
			settings.sourceType = newSettings[@"value"];
		}
			break;
		case IGRSettingsType_LanguageCategory:
		{
			settings.videoLanguageId = newSettings[@"value"];
		}
			break;
		case IGRSettingsType_History:
		{
			settings.historySize = newSettings[@"value"];
		}
			break;
		case IGRSettingsType_RemovePlayedSavedTracks:
		{
			settings.removPlayedSavedTracks = newSettings[@"value"];
		}
			break;
		case IGRSettingsType_SeekBack:
		{
			settings.seekBack = newSettings[@"value"];
		}
			break;
	}
	
	MR_DEFAULT_CONTEXT_SAVEONLY;
}

- (void)updateViewForSettings:(IGRSettingsType)aSettingsType from:(UIButton *)sender
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *settingsId = nil;
	NSArray *settingsData = nil;
	
	switch (aSettingsType)
	{
		case IGRSettingsType_Source:
		{
			settingsId = settings.sourceType;
			settingsData = self.sources;
		}
			break;
		case IGRSettingsType_LanguageCategory:
		{
			settingsId = settings.videoLanguageId;
			settingsData = self.languagesCategory;
		}
			break;
		case IGRSettingsType_History:
		{
			settingsId = settings.historySize;
			settingsData = self.history;
		}
			break;
		case IGRSettingsType_RemovePlayedSavedTracks:
		{
			settingsId = settings.removPlayedSavedTracks;
			settingsData = self.savedTrackOptions;
		}
			break;
		case IGRSettingsType_SeekBack:
		{
			settingsId = settings.seekBack;
			settingsData = self.seekBack;
		}
			break;
	}
	
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		
		return [evaluatedObject[@"value"] isEqualToNumber:settingsId];
	}];
	
	NSString *settingsString = [settingsData filteredArrayUsingPredicate:predicate].firstObject[@"name"];
	
	[sender setTitle:settingsString forState:UIControlStateNormal];
}

- (IBAction)onChangeSource:(id)sender
{
	[self updateSettingsFor:IGRSettingsType_Source];
	[self updateViewForSettings:IGRSettingsType_Source from:sender];
}

- (IBAction)onChangeLanguage:(id)sender
{
	[self updateSettingsFor:IGRSettingsType_LanguageCategory];
	[self updateViewForSettings:IGRSettingsType_LanguageCategory from:sender];
}

- (IBAction)onChangeHistorySize:(id)sender
{
	[self updateSettingsFor:IGRSettingsType_History];
	[self updateViewForSettings:IGRSettingsType_History from:sender];
}

- (IBAction)onChangeSeekBack:(id)sender
{
	[self updateSettingsFor:IGRSettingsType_SeekBack];
	[self updateViewForSettings:IGRSettingsType_SeekBack from:sender];
}

- (IBAction)onCleenAllSavedTracks:(id)sender
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localName != ''"];
	NSArray *tracks = [IGREntityExTrack MR_findAllWithPredicate:predicate];
	
	for (IGREntityExTrack *track in tracks)
	{
		[IGRSettingsViewController removeSavedTrack:track];
	}
}

- (IBAction)onRemovePlayedSavedTracks:(id)sender
{
	[self updateSettingsFor:IGRSettingsType_RemovePlayedSavedTracks];
	[self updateViewForSettings:IGRSettingsType_RemovePlayedSavedTracks from:sender];
}

+ (void)removeSavedTrack:(IGREntityExTrack *)aTrack
{
	if (aTrack.localName)
	{
		NSURL *url = [[IGRAppDelegate videoFolder] URLByAppendingPathComponent:aTrack.localName];
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		
		if ([defaultManager fileExistsAtPath:url.path])
		{
			[defaultManager removeItemAtURL:url error:nil];
		}
	}
	
	aTrack.localName = nil;
	aTrack.dataStatus = @(IGRTrackDataStatus_Web);
	MR_DEFAULT_CONTEXT_SAVEONLY;
}

#pragma mark - NSNotificationCenter

- (void)didMergeChangesFromiCloud:(NSNotification*)aNotification
{
	[self updateViews];
}

@end
