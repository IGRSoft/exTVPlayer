//
//  AppDelegate.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static NSString * const kStoreMomdName = @"exTVPlayer.momd";
static NSString * const kStoreName = @"exTVPlayer.sqlite";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSString *storeURL = [self copyDefaultStoreIfNecessary];
	[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
	MagicalRecordStack *stack = [[AutoMigratingMagicalRecordStack alloc] initWithStoreAtPath:storeURL];
	[MagicalRecordStack setDefaultStack:stack];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// Saves changes in the application's managed object context before the application terminates.
}

- (NSString *)copyDefaultStoreIfNecessary
{
	NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
	documentPath = [documentPath stringByAppendingPathComponent:@"Documents"];
	
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
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
		}
	}
	
	return storePath;
}

@end
