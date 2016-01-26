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
#import <AFNetworking/AFNetworking.h>

static NSString * const kMainServer = @"http://www.ex.ua";
static NSString * const kAdditionalServer = @"http://rover.info";

static AFURLSessionManager *__xmlManager = nil;

typedef void (^IGREXParserDownloadCompleateBlock)(RXMLElement *xmlDocument);

@implementation IGREXParser

+ (void)parseCatalogContent:(nonnull NSString *)aCatalogId
			 compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																			withValue:aCatalogId];
	
	if (catalog.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:catalog.timestamp] < 15)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/r_video_view/%@", kMainServer, aCatalogId];
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 if (xmlDocument)
		 {
			 catalog.name = [xmlDocument child:@"title"].text;
			 catalog.imgUrl = [[xmlDocument child:@"picture"] attribute:@"url"];
			 __block NSUInteger orderId = 0;
			 [xmlDocument iterate:@"file_list.file" usingBlock:^(RXMLElement *node) {
				 
				 NSString *title = [node attribute:@"name"];
				 NSString *webPath = [node attribute:@"url"];
				 
				 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"webPath == %@ AND catalog = %@", webPath, catalog];
				 IGREntityExTrack *track = [IGREntityExTrack MR_findFirstWithPredicate:predicate];
				 
				 if (!track)
				 {
					 IGREntityExTrack *track = [IGREntityExTrack MR_createEntity];
					 track.webPath = webPath;
					 track.name = title;
					 track.status = @(IGRTrackState_New);
					 track.dataStatus = @(IGRTrackDataStatus_Web);
					 track.position = @(0.0);
					 track.catalog = catalog;
					 track.orderId = @(orderId);
				 }
				 ++orderId;
			 }];
			 
			 catalog.timestamp = [NSDate date];
			 if ([catalog.orderId isEqualToNumber:@0])
			 {
				 NSInteger orderId = [[IGREntityExCatalog MR_findLargestValueForAttribute:@"orderId"] integerValue];
				 catalog.orderId = @(++orderId);
			 }
			 
			 if (MR_DEFAULT_CONTEXT.hasChanges)
			 {
				 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			 }
			 
			 aCompleateBlock(@[catalog]);
		 }
	 }];
}

+ (void)parseVideoCatalogContent:(nonnull NSString *)aVideoCatalogId
				  compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	IGREntityExVideoCatalog *videoCatalog = [IGREntityExVideoCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																						   withValue:aVideoCatalogId];
	if (videoCatalog.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:videoCatalog.timestamp] < 15)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/rss/%@", kMainServer, aVideoCatalogId];
	
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 if (xmlDocument)
		 {
			 NSString *title = [[xmlDocument child:@"channel"] child:@"title"].text;
			 videoCatalog.name = title;
			 
			 [xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
				 
				 NSString *title = [node child:@"title"].text;
				 NSString *itemId = [node child:@"guid"].text;
				 
				 IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
				 chanel.name = title;
				 chanel.videoCatalog = videoCatalog;
			 }];
			 
			 videoCatalog.timestamp = [NSDate date];
			 
			 if (MR_DEFAULT_CONTEXT.hasChanges)
			 {
				 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			 }
			 
			 aCompleateBlock(@[videoCatalog]);
		 }
	 }];
}

+ (void)parseChanelContent:(nonnull NSString *)aChanelId
			compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																		 withValue:aChanelId];
	if (chanel.timestamp)
	{
		if ([IGREXParser hoursBetweenCurrwntDate:chanel.timestamp] < 15)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/rss/%@", kMainServer, aChanelId];
	[self downloadXMLFrom:rrsUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 if (xmlDocument)
		 {
			 NSString *title = [[xmlDocument child:@"channel"] child:@"title"].text;
			 chanel.name = title;
			 
			 NSMutableArray *items = [NSMutableArray array];
			 [xmlDocument iterate:@"channel.item" usingBlock:^(RXMLElement *node) {
				 
				 [items addObject:[node child:@"guid"].text];
			 }];
			 
			 chanel.timestamp = [NSDate date];
			 
			 //    return_type (^blockName)(var_type) = ^return_type (var_type varName)
			 void (^exitBlock)(IGREntityExChanel *) = ^void (IGREntityExChanel *chanel) {
				 
				 if (MR_DEFAULT_CONTEXT.hasChanges)
				 {
					 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
				 }
				 
				 aCompleateBlock(@[chanel]);
			 };

			 if (items.count)
			 {
				 __block NSUInteger count = items.count;
				 for (NSString *catalogId in items)
				 {
					 [IGREXParser parseCatalogContent:catalogId compleateBlock:^(NSArray * _Nullable items) {
						 
						 IGREntityExCatalog *catalog = items.firstObject;
						 if (catalog)
						 {
							 catalog.chanel = chanel;
						 }
						 
						 if (--count == 0)
						 {
							 exitBlock(chanel);
						 }
					 }];
				 }
			 }
			 else
			 {
				 exitBlock(chanel);
			 }
		 }
	 }];
}

+ (void)parseLiveSearchContent:(nonnull NSString *)aSearchText
						  page:(NSUInteger)aPage
					   catalog:(NSInteger)aCatalog
				compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/r_video_search?s=%@&p=%@", kMainServer, aSearchText, @(aPage)];
	if (aCatalog > 0)
	{
		rrsUrl = [rrsUrl stringByAppendingFormat:@"&original_id=%@", @(aCatalog)];
	}
	rrsUrl = [rrsUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	
	[self downloadXMLFrom:rrsUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 NSMutableArray *items = [NSMutableArray array];
		 if (xmlDocument)
		 {
			 [xmlDocument iterate:@"object" usingBlock:^(RXMLElement *node) {
				 
				 NSString *catalogId = [node attribute:@"id"];
				 [items addObject:catalogId];
			 }];
		 }
		 
		 aCompleateBlock(items);
	 }];
}

+ (void)parseLiveCatalog:(nonnull NSString *)aCatalog
					page:(NSUInteger)aPage
		  compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/r_video_search?original_id=%@&p=%@", kMainServer, aCatalog, @(aPage)];
	rrsUrl = [rrsUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	
	[self downloadXMLFrom:rrsUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 NSMutableArray *items = [NSMutableArray array];
		 if (xmlDocument)
		 {
			 [xmlDocument iterate:@"object" usingBlock:^(RXMLElement *node) {
				 
				 NSString *catalogId = [node attribute:@"id"];
				 [items addObject:catalogId];
			 }];
		 }
		 
		 aCompleateBlock(items);
	 }];
}

+ (void)downloadXMLFrom:(nonnull NSString *)aUrl
		 compleateBlock:(nonnull IGREXParserDownloadCompleateBlock)aCompleateBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aUrl]];
	
	if (!__xmlManager)
	{
		NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 20;
		
		__xmlManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
		
		AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
		serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/rss+xml",
											 @"application/xspf+xml", @"text/xml", nil];
		[__xmlManager setResponseSerializer:serializer];
	}
	
	[[__xmlManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		
		if(!error)
		{
			RXMLElement *xmlDocument = [[RXMLElement alloc] initFromXMLData:responseObject];
			aCompleateBlock(xmlDocument);
		}
		else
		{
			NSString *errorStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			NSLog(@"%@", errorStr);
			
			aCompleateBlock(nil);
		}
		
	}] resume];
}

+ (NSInteger)hoursBetweenCurrwntDate:(NSDate *)aDate
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute
																   fromDate:aDate
																	 toDate:[NSDate date]
																	options:0];
	
	return components.minute;
}

@end
