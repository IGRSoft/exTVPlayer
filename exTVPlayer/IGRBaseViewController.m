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
		settings.videoLanguageId	= @(IGRVideoCategory_Rus);
		settings.historySize		= @(IGRHistorySize_10);
		settings.sourceType			= @(IGRSourceType_RSS);
		
		[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
	}
	
	return settings;
}

- (void)callCustomAction
{

}

@end
