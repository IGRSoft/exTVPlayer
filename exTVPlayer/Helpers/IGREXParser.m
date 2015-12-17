//
//  IGREXParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREXParser.h"
#import "RXMLElement.h"
#import "IGRExTrack.h"

@implementation IGREXParser

+ (NSDictionary *)catalogContent:(NSString *)aCatalogId
{
	NSMutableArray *tracks = [NSMutableArray array];
	
	NSError *error = nil;
	NSStringEncoding encoding;
	NSString *xspfUrl = [NSString stringWithFormat:@"http://www.ex.ua/playlist/%@.xspf", aCatalogId];
	NSString *xspfString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:xspfUrl]
													  usedEncoding:&encoding
															 error:&error];
	
	RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLString:xspfString encoding:NSUTF8StringEncoding];
	
	NSParameterAssert(xmlDocument.isValid);
	
	NSString *title = [[xmlDocument child:@"title"] text];
	
	[xmlDocument iterate:@"trackList.track" usingBlock:^(RXMLElement *node) {
		NSString *title = [[node child:@"title"] text];
		NSString *location = [[node child:@"location"] text];
		
		IGRExTrack *track = [[IGRExTrack alloc] init];
		track.title = title;
		track.location = location;
		
		[tracks addObject:track];
	}];
	
	return @{@"title": title, @"tracks": tracks};
}

@end
