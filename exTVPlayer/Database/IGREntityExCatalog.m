//
//  IGREntityExCatalog.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREntityExCatalog.h"
#import "IGREntityExChanel.h"
#import "IGREntityExTrack.h"
#import "IGREntityAppSettings.h"

@implementation IGREntityExCatalog

+ (NSArray *)getHistory
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"viewedTimestamp != nil"];
	NSArray *history = [IGREntityExCatalog MR_findAllSortedBy:@"viewedTimestamp" ascending:NO withPredicate:predicate];
	
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
	NSUInteger count = MIN(settings.historySize.integerValue, history.count);
	
	return [history subarrayWithRange:NSMakeRange(0, count)];
}

+ (NSArray *)getFavorites
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorit == YES"];
	NSArray *favorites = [IGREntityExCatalog MR_findAllSortedBy:@"orderId" ascending:NO withPredicate:predicate];
	
	return favorites;
}

@end
