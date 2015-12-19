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

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kApplicationWillResignActive object:nil];
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
