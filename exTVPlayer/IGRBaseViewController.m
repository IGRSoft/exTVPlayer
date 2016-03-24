//
//  IGRBaseViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRBaseViewController.h"
#import "IGRCountryParser.h"

@interface IGRBaseViewController ()

@property (weak, nonatomic) UITabBarController *tabBar;

@end

@implementation IGRBaseViewController

- (IGREntityAppSettings*)appSettings
{
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
	if (!settings)
	{
		settings = [IGREntityAppSettings MR_createEntity];
		settings.videoLanguageId		= @([IGRCountryParser currentCountry]);
		settings.historySize			= @(IGRHistorySize_10);
		settings.sourceType				= @(IGRSourceType_RSS);
		settings.removPlayedSavedTracks	= @(YES);
		settings.seekBack				= @(IGRSeekBack_10);
		
		MR_DEFAULT_CONTEXT_SAVEONLY;
	}
	
	// migration to v2
	if (settings.seekBack == nil)
	{
		settings.seekBack	= @(IGRSeekBack_10);
		MR_DEFAULT_CONTEXT_SAVEONLY;
	}
	
	if (settings.removPlayedSavedTracks == nil)
	{
		settings.removPlayedSavedTracks	= @(YES);
		MR_DEFAULT_CONTEXT_SAVEONLY;
	}
	
	return settings;
}

@end
