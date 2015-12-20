//
//  IGREXParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREXParser.h"
#import "RXMLElement.h"
#import "IGREntityExVideoCatalog.h"
#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityExTrack.h"

@implementation IGREXParser

+ (void)parseCatalogContent:(NSString *)aCatalogId
{
	IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																			withValue:aCatalogId];
	
	if (catalog.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:catalog.timestamp] < 1)
		{
			return; //skip update
		}
	}
	
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/playlist/%@.xspf", aCatalogId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[xmlDocument child:@"title"] text];
	catalog.name = title;
	
	__block NSUInteger orderId = 0;
	[xmlDocument iterate:@"trackList.track" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *location = [[node child:@"location"] text];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"location == %@ AND catalog = %@", location, catalog];
		IGREntityExTrack *track = [IGREntityExTrack MR_findFirstWithPredicate:predicate];
		
		if (!track)
		{
			track = [IGREntityExTrack MR_createEntity];
			track.location = location;
			track.name = title;
			track.status = @(IGRTrackState_New);
			track.position = @(0.0);
			track.catalog = catalog;
			track.orderId = @(orderId);
		}
		++orderId;
	}];
	
	catalog.timestamp = [NSDate date];
	
	[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
}

+ (void)parseVideoCatalogContent:(NSString *)aVideoCatalogId
{
	IGREntityExVideoCatalog *videoCatalog = [IGREntityExVideoCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																						   withValue:aVideoCatalogId];
	if (videoCatalog.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:videoCatalog.timestamp] < 1)
		{
			return; //skip update
		}
	}
	
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", aVideoCatalogId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[[xmlDocument child:@"channel"] child:@"title"] text];
	videoCatalog.name = title;
	
	[xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *itemId = [[node child:@"guid"] text];
		
		IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
		chanel.name = title;
		chanel.videoCatalog = videoCatalog;
	}];
	
	videoCatalog.timestamp = [NSDate date];
	
	[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];

}

+ (void)parseChanelContent:(NSString *)aChanelId
{
	IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																		 withValue:aChanelId];
	if (chanel.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:chanel.timestamp] < 1)
		{
			return; //skip update
		}
	}
	
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *rrsUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", aChanelId];
	NSString *rrsString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:rrsUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:rrsString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[[xmlDocument child:@"channel"] child:@"title"] text];
	chanel.name = title;
	
	NSMutableArray *items = [NSMutableArray array];
	[xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
		
		[items addObject:node];
	}];
	
	NSInteger itemsCount = items.count - 1;
	
	NSNumber *lastId = [IGREntityExCatalog MR_findLargestValueForAttribute:@"orderId"];
	__block NSUInteger orderId = lastId.integerValue;
	
	for (RXMLElement *node in [items reverseObjectEnumerator])
	{
		NSString *title = [[node child:@"title"] text];
		NSString *itemId = [[node child:@"guid"] text];
		
		IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
		
		if (catalog.orderId.integerValue == (orderId - itemsCount--))
		{
			continue; //same position;
		}
		
		if (!catalog.imgUrl)
		{
			NSError *error = nil;
			NSStringEncoding encoding;
			NSString *rrsUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", itemId];
			NSString *rrsString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:rrsUrl]
															 usedEncoding:&encoding
																	error:&error];
			
			RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:rrsString encoding:NSUTF8StringEncoding];
			
			NSParameterAssert(xmlDocument.isValid);
			
			[xmlDocument iterate:@"channel.image.url" usingBlock:^(RXMLElement *node) {
				NSString *imgUrl = [node text];
				imgUrl = [[imgUrl componentsSeparatedByString:@"?"] firstObject];
				catalog.imgUrl = imgUrl;
			}];
		}
		catalog.name = title;
		catalog.chanel = chanel;
		
		catalog.orderId = @(orderId++);
	}
	
	chanel.timestamp = [NSDate date];
	
	[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
}

+ (NSInteger)hoursBetweenCurrwntDate:(NSDate *)aDate
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour
																   fromDate:aDate
																	 toDate:[NSDate date]
																	options:0];
	
	return components.hour;
}

@end
