//
//  IGRBaseViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRBaseViewController.h"

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
		settings.videoLanguageId		= @([self currentCountry]);
		settings.historySize			= @(IGRHistorySize_10);
		settings.sourceType				= @(IGRSourceType_RSS);
		settings.removPlayedSavedTracks	= @(YES);
		
		[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
	}
	
	return settings;
}

- (void)callCustomAction
{

}

- (IGRVideoCategory)currentCountry
{
	NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
	NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
	
	IGRVideoCategory currentCountry = IGRVideoCategory_Eng;
	if ([countryCode isEqualToString:@"UA"])
	{
		currentCountry = IGRVideoCategory_Ukr;
	}
	else if ([countryCode isEqualToString:@"RU"])
	{
		currentCountry = IGRVideoCategory_Rus;
	}
	else if ([countryCode isEqualToString:@"PL"])
	{
		currentCountry = IGRVideoCategory_Pl;
	}
	else if ([countryCode isEqualToString:@"ES"])
	{
		currentCountry = IGRVideoCategory_Esp;
	}
	else if ([countryCode isEqualToString:@"DE"])
	{
		currentCountry = IGRVideoCategory_De;
	}
	
	return currentCountry;
}

@end
