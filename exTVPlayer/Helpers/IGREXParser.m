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
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/playlist/%@.xspf", aCatalogId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[xmlDocument child:@"title"] text];
	
	IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																			withValue:aCatalogId];
	catalog.name = title;
	
	[catalog.tracks enumerateObjectsUsingBlock:^(IGREntityExTrack * _Nonnull obj, BOOL * _Nonnull stop) {
		
		[obj MR_deleteEntity];
	}];
	
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
	
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

+ (void)parseVideoCatalogContent:(NSString *)aVideoCatalogId
{
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", aVideoCatalogId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[[xmlDocument child:@"channel"] child:@"title"] text];
	
	IGREntityExVideoCatalog *videoCatalog = [IGREntityExVideoCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																						   withValue:aVideoCatalogId];
	videoCatalog.name = title;
	
	[xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *itemId = [[node child:@"guid"] text];
		
		IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
		chanel.name = title;
		chanel.videoCatalog = videoCatalog;
	}];
	
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

+ (void)parseChanelContent:(NSString *)aChanelId
{
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *rrsUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", aChanelId];
	NSString *rrsString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:rrsUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:rrsString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[[xmlDocument child:@"channel"] child:@"title"] text];
	
	IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																		 withValue:aChanelId];
	chanel.name = title;
	
	NSSet<IGREntityExCatalog *> *catalogs = chanel.catalogs;
	
	[catalogs enumerateObjectsUsingBlock:^(IGREntityExCatalog * _Nonnull obj, BOOL * _Nonnull stop) {
		
		obj.orderId = @(obj.orderId.integerValue * -1);
	}];
	
	__block NSUInteger orderId = 0;
	[xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *itemId = [[node child:@"guid"] text];
		
		IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
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
				[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			}];
		}
		catalog.name = title;
		catalog.chanel = chanel;
		
		catalog.orderId = @(orderId++);
		
	}];
	
	NSArray *newCatalogs = [IGREntityExCatalog MR_findByAttribute:@"chanel"
												   withValue:chanel
												  andOrderBy:@"orderId"
												   ascending:NO];
	
	[newCatalogs enumerateObjectsUsingBlock:^(IGREntityExCatalog * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		if (obj.orderId.integerValue < 0)
		{
			obj.orderId = @(orderId++);
		}
	}];
	
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

@end
