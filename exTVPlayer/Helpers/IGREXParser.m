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
		}
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
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/rss/%@", aChanelId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[[xmlDocument child:@"channel"] child:@"title"] text];
	
	IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																		 withValue:aChanelId];
	chanel.name = title;
	
	[xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *itemId = [[node child:@"guid"] text];
		
		IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
		catalog.name = title;
		catalog.chanel = chanel;
	}];
	
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

@end
