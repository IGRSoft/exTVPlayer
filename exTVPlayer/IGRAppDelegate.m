//
//  IGRAppDelegate.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRAppDelegate.h"
#import "IGREntityExTrack.h"
#import "IGREntityExCatalog.h"
#import "IGREXCatalogHistoryItem.h"
#import "IGRUserDefaults.h"
#import "IGRCChanelViewController.h"

@interface IGRAppDelegate ()

@property (nonatomic) IGRUserDefaults *userSettings;

@end

@implementation IGRAppDelegate

static NSString * const kStoreMomdName = @"exTVPlayer.momd";
static NSString * const kStoreName = @"exTVPlayer.sqlite";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.userSettings = [[IGRUserDefaults alloc] init];
	
	NSString *storeURL = [self copyDefaultStoreIfNecessary];
	[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
	MagicalRecordStack *stack = [[AutoMigratingMagicalRecordStack alloc] initWithStoreAtPath:storeURL];
	[MagicalRecordStack setDefaultStack:stack];
	
	[self resetNotDownloadedTracks];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kApplicationWillResignActive object:nil];
	
	NSArray *entityHistory = [IGREntityExCatalog getHistory];
	NSMutableArray *history = [[NSMutableArray alloc] initWithCapacity:entityHistory.count];
	
	for (IGREntityExCatalog *historyEntity in entityHistory)
	{
		IGREXCatalogHistoryItem *item = [[IGREXCatalogHistoryItem alloc] init];
		item.itemId = historyEntity.itemId;
		item.name = historyEntity.name;
		item.imgUrl = historyEntity.imgUrl;
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
		[history addObject:data];
	}
	
	self.userSettings.history = history;
	[self.userSettings saveUserSettings];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kapplicationDidBecomeActive object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
	NSURLComponents *component = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	if ([component.scheme isEqualToString:@"excatalog"])
	{
		NSString *itemId = [[[component queryItems] firstObject] value];
		UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
		[tabBar.selectedViewController dismissViewControllerAnimated:NO completion:nil];
		
		tabBar.selectedIndex = 3;
		IGRCChanelViewController *chanelView = tabBar.selectedViewController;
		[chanelView selectCatalogId:itemId];
		
		return YES;
	}
	
	return NO;
}

- (NSString *)copyDefaultStoreIfNecessary
{
	NSSearchPathDirectory dic = NSCachesDirectory;
#if	TARGET_OS_IOS
	dic = NSDocumentDirectory;
#endif
	
	NSString *documentPath = NSSearchPathForDirectoriesInDomains(dic, NSUserDomainMask, YES).firstObject;
#if	TARGET_OS_TV
	documentPath = [documentPath stringByAppendingPathComponent:@"Documents"];
#endif
	
	NSString *storePath = [documentPath stringByAppendingPathComponent:kStoreName];
	
	// If the expected store doesn't exist, copy the default store.
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	if (![defaultManager fileExistsAtPath:storePath])
	{
		NSError *error = nil;
		if (![defaultManager fileExistsAtPath:documentPath])
		{
			[defaultManager createDirectoryAtPath:documentPath
					  withIntermediateDirectories:YES
									   attributes:nil error:&error];
		}
		
		if (!error)
		{
			NSManagedObjectModel *model = [NSManagedObjectModel MR_managedObjectModelNamed:kStoreMomdName];
			NSPersistentStoreCoordinator *_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
			NSURL *storeURL = [[NSURL alloc] initFileURLWithPath:storePath];
			
			NSString *failureReason = @"There was an error creating or loading the application's saved data.";
			if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
				// Report any error we got.
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
				dict[NSLocalizedFailureReasonErrorKey] = failureReason;
				dict[NSUnderlyingErrorKey] = error;
				error = [NSError errorWithDomain:@"com.igrsoft.extvplayer.database" code:9999 userInfo:dict];
				// Replace this with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				NSLog(@"Unresolved error %@, %@", error, error.userInfo);
				abort();
			}
		}
	}
	
	return storePath;
}

- (void)resetNotDownloadedTracks
{
	NSArray *tracks = [IGREntityExTrack MR_findByAttribute:@"dataStatus" withValue:@(IGRTrackDataStatus_Downloading)];
	
	if (tracks.count)
	{
		for (IGREntityExTrack *track in tracks)
		{
			track.dataStatus = @(IGRTrackDataStatus_Web);
		}
		
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

+ (NSURL *)videoFolder
{
	NSURL *destURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
															inDomain:NSUserDomainMask
												   appropriateForURL:nil
															  create:NO
															   error:nil];
	destURL = [destURL URLByAppendingPathComponent:@"SavedVideo"];
	
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	if (![defaultManager fileExistsAtPath:destURL.path])
	{
		[defaultManager createDirectoryAtPath:destURL.path
				  withIntermediateDirectories:YES
								   attributes:nil
										error:NULL];
	}
	
	return destURL;
}

@end
