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
#import "IGREXCatalogTopShelfItem.h"
#import "IGRUserDefaults.h"
#import "IGRCatalogViewController.h"
#import "IGRSearchViewController.h"
#import "IGRChanelViewController.h"

@interface IGRAppDelegate ()

@property (nonatomic) IGRUserDefaults *userSettings;

@end

@implementation IGRAppDelegate

static NSString * const kStoreMomdName = @"exTVPlayer.momd";
static NSString * const kStoreName = @"exTVPlayer.sqlite";

static NSString * const kLaunchItemSearch = @"com.igrsoft.exTVPlayer.search";
static NSString * const kLaunchItemFavorit = @"com.igrsoft.exTVPlayer.favorit";
static NSString * const kLaunchItemHistory = @"com.igrsoft.exTVPlayer.history";
static NSString * const kLaunchItemLastViewed = @"com.igrsoft.exTVPlayer.lastviewed";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.userSettings = [[IGRUserDefaults alloc] init];
	
	NSString *storeURL = [self copyDefaultStoreIfNecessary];
	[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
	AutoMigratingMagicalRecordStack *stack = [[AutoMigratingMagicalRecordStack alloc] initWithStoreAtPath:storeURL];
#if	TARGET_OS_IOS
	NSURL *iCloudPath = [self cloudDirectory];
	if (iCloudPath.absoluteString.length)
	{
		stack.storeOptions = @{
							   NSPersistentStoreUbiquitousContentNameKey : @"exTVPlayerUbiquityStore",
							   NSPersistentStoreUbiquitousContentURLKey : iCloudPath
								   };
		[stack.context MR_observeiCloudChangesInCoordinator:stack.coordinator];
	}
#endif
	[MagicalRecordStack setDefaultStack:stack];
	
	[self resetNotDownloadedTracks];

	[self createDynamicShortcutItems];
	
#if	TARGET_OS_IOS
	if (NSClassFromString(@"UIApplicationShortcutItem"))
	{
		UIApplicationShortcutItem *item = [launchOptions valueForKey:UIApplicationLaunchOptionsShortcutItemKey];
		[self performActionForShortcutItem:item];
	}
#endif
	
	return YES;
}

#if	TARGET_OS_IOS
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	
	[self performActionForShortcutItem:shortcutItem];
	
	completionHandler(YES);
}

- (void)performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
	if (shortcutItem)
	{
		NSLog(@"We've launched from shortcut item: %@", shortcutItem.localizedTitle);
	} else
	{
		NSLog(@"We've launched properly.");
	}
	
	if ([shortcutItem.type isEqualToString:kLaunchItemSearch])
	{
		[self openSearch];
	}
	else if ([shortcutItem.type isEqualToString:kLaunchItemFavorit])
	{
		[self openFavorites];
	}
	else if ([shortcutItem.type isEqualToString:kLaunchItemHistory])
	{
		[self openHistory];
	}
	else if ([shortcutItem.type isEqualToString:kLaunchItemLastViewed])
	{
		NSDictionary *catalogInfo = shortcutItem.userInfo;
		[self openCatalogId:catalogInfo[@"itemId"] force:NO];
	}
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application
{
	if (MR_DEFAULT_CONTEXT.hasChanges)
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
	
	[self createDynamicShortcutItems];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kApplicationWillResignActive object:nil];
	
	NSArray *entityHistory = [IGREntityExCatalog history];
	NSMutableArray *history = [[NSMutableArray alloc] initWithCapacity:entityHistory.count];
	
	for (IGREntityExCatalog *catalogEntity in entityHistory)
	{
		IGREXCatalogTopShelfItem *item = [[IGREXCatalogTopShelfItem alloc] init];
		item.itemId = catalogEntity.itemId;
		item.name = catalogEntity.name;
		item.imgUrl = catalogEntity.imgUrl;
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
		[history addObject:data];
	}
	
	NSArray *entityFavorites = [IGREntityExCatalog favorites];
	NSMutableArray *favorites = [[NSMutableArray alloc] initWithCapacity:entityFavorites.count];
	
	for (IGREntityExCatalog *catalogEntity in entityFavorites)
	{
		IGREXCatalogTopShelfItem *item = [[IGREXCatalogTopShelfItem alloc] init];
		item.itemId = catalogEntity.itemId;
		item.name = catalogEntity.name;
		item.imgUrl = catalogEntity.imgUrl;
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
		[favorites addObject:data];
	}
	
	self.userSettings.history = history;
	self.userSettings.favorites = favorites;
	
	[self.userSettings saveUserSettings];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
#if	TARGET_OS_IOS
	AutoMigratingMagicalRecordStack *stack = [AutoMigratingMagicalRecordStack defaultStack];
	[stack.context MR_stopObservingiCloudChangesInCoordinator:stack.coordinator];
#endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
#if	TARGET_OS_IOS
	AutoMigratingMagicalRecordStack *stack = [AutoMigratingMagicalRecordStack defaultStack];
	[stack.context MR_observeiCloudChangesInCoordinator:stack.coordinator];
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kapplicationDidBecomeActive object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
#if	TARGET_OS_IOS
	AutoMigratingMagicalRecordStack *stack = [AutoMigratingMagicalRecordStack defaultStack];
	[stack.context MR_stopObservingiCloudChangesInCoordinator:stack.coordinator];
#endif
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
	NSURLComponents *component = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
	if ([component.scheme isEqualToString:@"excatalog"])
	{
		NSString *catalogId = [[[component queryItems] firstObject] value];
		[self openCatalogId:catalogId force:YES];
		
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

- (NSURL *)cloudDirectory
{
	NSFileManager *fileManager=[NSFileManager defaultManager];
	NSString *teamID = @"iCloud";
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSString *cloudRoot = [NSString stringWithFormat:@"%@.%@", teamID, bundleID];
	NSURL *cloudRootURL = [fileManager URLForUbiquityContainerIdentifier:cloudRoot];
	NSLog (@"cloudRootURL = %@", cloudRootURL);
	
	return cloudRootURL;
}

- (void)openCatalogId:(NSString *)aCatalogId force:(BOOL)aForce
{
	UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
	[tabBar.selectedViewController dismissViewControllerAnimated:NO completion:nil];
	
	if (aForce)
	{
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
		IGRCatalogViewController *cvc = [storyboard instantiateViewControllerWithIdentifier:@"IGRCatalogViewController"];
		[cvc setCatalogId:aCatalogId];
		
		[tabBar presentViewController:cvc animated:YES completion:nil];
	}
	else
	{
		tabBar.selectedIndex = 3;
		IGRChanelViewController *cvc = tabBar.selectedViewController;
		[cvc performSegueWithIdentifier:@"openCatalog" sender:cvc];
	}
}

- (void)openSearch
{
	UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
	[tabBar.selectedViewController dismissViewControllerAnimated:NO completion:nil];
	
	tabBar.selectedIndex = 2;
	
	IGRSearchViewController *svc = tabBar.selectedViewController;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[svc activateSearchField];
	});
}

- (void)openFavorites
{
	UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
	[tabBar.selectedViewController dismissViewControllerAnimated:NO completion:nil];
	
	tabBar.selectedIndex = 1;
}

- (void)openHistory
{
	UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
	[tabBar.selectedViewController dismissViewControllerAnimated:NO completion:nil];
	
	tabBar.selectedIndex = 3;
	
}

- (void)createDynamicShortcutItems
{
#if	TARGET_OS_IOS
	id shortcutItemClass = NSClassFromString(@"UIApplicationShortcutItem");
	if (shortcutItemClass)
	{
		IGREntityExCatalog *catalogEntity = [IGREntityExCatalog lastViewed];
		
		if (catalogEntity)
		{
			NSDictionary *catalog = @{@"itemId": catalogEntity.itemId};
			
			UIApplicationShortcutItem *catalogItem = [[UIApplicationShortcutItem alloc]initWithType:kLaunchItemLastViewed
																					 localizedTitle:catalogEntity.name
																				  localizedSubtitle:@""
																							   icon:nil
																						   userInfo:catalog];
			[UIApplication sharedApplication].shortcutItems = @[catalogItem];
		}
	}
#endif
}

@end
