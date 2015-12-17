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
	[self copyDefaultStoreIfNecessary];
	[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
	MagicalRecordStack *stack = [[ManuallyMigratingMagicalRecordStack alloc] initWithStoreNamed:kStoreName];
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

- (void)copyDefaultStoreIfNecessary
{	
	NSURL *storeURL = [NSPersistentStore MR_fileURLForStoreNameIfExistsOnDisk:kStoreName];
	
	// If the expected store doesn't exist, copy the default store.
	if (!storeURL)
	{
		[NSManagedObjectModel MR_managedObjectModelNamed:kStoreMomdName];
	}
	
}

@end
