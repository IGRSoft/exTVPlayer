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

@property (strong, nonatomic) NSArray *sources;
@property (strong, nonatomic) NSArray *languagesCategory;
@property (strong, nonatomic) NSArray *caches;
@property (strong, nonatomic) NSArray *history;

@end

typedef NS_ENUM(NSUInteger, IGRSettingsType)
{
	IGRSettingsType_Source	= 0,
	IGRSettingsType_LanguageCategory,
	IGRSettingsType_History
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
	
	[super viewDidLoad];
	
	[self updateViewForSettings:IGRSettingsType_Source from:self.sourceButton];
	[self updateViewForSettings:IGRSettingsType_LanguageCategory from:self.languageCategoryButton];
	[self updateViewForSettings:IGRSettingsType_History from:self.historySizeButton];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
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
	}
	
	[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
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

- (IBAction)onCleenAllSavedTracks:(id)sender
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localName != ''"];
	NSArray *tracks = [IGREntityExTrack MR_findAllWithPredicate:predicate];
	
	for (IGREntityExTrack *track in tracks)
	{
		[IGRSettingsViewController removeSavedTrack:track];
	}
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
	[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
}

@end
