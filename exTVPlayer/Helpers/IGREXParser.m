//
//  IGREXParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREXParser.h"
#import "RXMLElement.h"
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
			track.status = 0;
			track.stopTime = 0;
			track.catalog = catalog;
		}
	}];
	
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

@end
