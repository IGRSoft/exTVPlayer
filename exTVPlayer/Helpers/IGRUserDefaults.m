//
//  IGRUserDefaults.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/23/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRUserDefaults.h"

static NSString *kUDHistory   = @"excataloghistory";

@interface IGRUserDefaults ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation IGRUserDefaults

- (void)initialize
{
	// Create a dictionary
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// Register the dictionary of defaults
	[self.defaults registerDefaults: defaultValues];
	//DBNSLog(@"registered defaults: %@", defaultValues);
}

- (instancetype)init
{
	if (self = [super init])
	{
		NSString *bundleIdentifier = @"group.com.igrsoft.exTVPlayer.shared";
		
		self.defaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
		[self initialize];
		[self loadUserSettings];
	}
	
	return self;
}

- (void)loadUserSettings
{
	_history = [self.defaults objectForKey:kUDHistory];
}

- (void)saveUserSettings
{
	[self.defaults setObject:_history forKey:kUDHistory];
	
	[self.defaults synchronize];
}

@end
