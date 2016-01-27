//
//  IGREXParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREXParser.h"
#import <Ono/Ono.h>
#import <AFNetworking/AFNetworking.h>

#import "IGREntityExVideoCatalog.h"
#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityExTrack.h"

#if (PROXY_ENABLED)
#import <CFNetwork/CFNetwork.h>
#endif

static NSString * const kMainServer = @"http://www.ex.ua";
static NSString * const kAdditionalServer = @"http://rover.info";

static AFURLSessionManager *__xmlManager = nil;

typedef void (^IGREXParserDownloadCompleateBlock)(ONOXMLElement *xmlDocument);

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
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 catalog.name = [xmlDocument firstChildWithTag:@"title"].stringValue;
			 catalog.imgUrl = [[xmlDocument firstChildWithTag:@"picture"] valueForAttribute:@"url"];
			 __block NSUInteger orderId = 0;
			 
			 [xmlDocument enumerateElementsWithXPath:@"//file_list/file" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
				 
				 NSString *title = [element valueForAttribute:@"name"];
				 NSString *webPath = [element valueForAttribute:@"url"];
				 NSInteger duration = [[element valueForAttribute:@"duration"] integerValue];
				 
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
					 track.duration = @(duration);
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
		 }
		 
		 aCompleateBlock(@[catalog]);
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
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 NSString *title = [[xmlDocument firstChildWithTag:@"channel"] firstChildWithTag:@"title"].stringValue;
			 videoCatalog.name = title;
			 
			 [xmlDocument enumerateElementsWithXPath:@"//channel/item" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
				 
				 NSString *title = [element firstChildWithTag:@"title"].stringValue;
				 NSString *itemId = [element firstChildWithTag:@"guid"].stringValue;
				 
				 IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
				 chanel.name = title;
				 chanel.videoCatalog = videoCatalog;
			 }];
			 
			 videoCatalog.timestamp = [NSDate date];
			 
			 if (MR_DEFAULT_CONTEXT.hasChanges)
			 {
				 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			 }
		 }
		 
		 aCompleateBlock(@[videoCatalog]);
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
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 chanel.name = [[xmlDocument firstChildWithTag:@"channel"] firstChildWithTag:@"title"].stringValue;
			 
			 NSMutableArray *items = [NSMutableArray array];
			 
			 [xmlDocument enumerateElementsWithXPath:@"//channel/item" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
				 
				 [items addObject:[element firstChildWithTag:@"guid"].stringValue];
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

+ (void)parseLiveVideoCatalogContent:(nonnull NSString *)aVideoCatalogId
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
	
	NSString *lang = @"en";
	switch (aVideoCatalogId.integerValue)
	{
		case IGRVideoCategory_Rus:
			lang = @"ru";
			break;
		case IGRVideoCategory_Ukr:
			lang = @"uk";
			break;
		default:
			lang = @"en";
			break;
	}
	
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/r_video_index?lang=%@", kMainServer, lang];
	
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 [xmlDocument enumerateElementsWithXPath:@"//object" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
				 
				 NSString *title = [element firstChildWithTag:@"title"].stringValue;
				 NSString *itemId = [element firstChildWithTag:@"id"].stringValue;
				 
				 IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
				 chanel.name = title;
				 chanel.videoCatalog = videoCatalog;
			 }];
			 
			 videoCatalog.timestamp = [NSDate date];
			 
			 if (MR_DEFAULT_CONTEXT.hasChanges)
			 {
				 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			 }
		 }
		 
		 aCompleateBlock(@[videoCatalog]);
	 }];
}

+ (void)parseLiveSearchContent:(nullable NSString *)aSearchText
						  page:(NSUInteger)aPage
					   catalog:(nullable NSString *)aCatalog
				compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/r_video_search?p=%@&per=20", kMainServer, @(aPage)];
	if (aCatalog.length > 0)
	{
		rrsUrl = [rrsUrl stringByAppendingFormat:@"&original_id=%@", aCatalog];
	}
	if (aSearchText.length > 0)
	{
		rrsUrl = [rrsUrl stringByAppendingFormat:@"&s=%@", aSearchText];
	}
	rrsUrl = [rrsUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	
	[self downloadXMLFrom:rrsUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 NSMutableArray *items = [NSMutableArray array];
		 if (xmlDocument)
		 {
			 [xmlDocument enumerateElementsWithXPath:@"//object" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
				 
				 NSString *catalogId = [element valueForAttribute:@"id"];
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
	return [self parseLiveSearchContent:nil
								   page:aPage
								catalog:aCatalog
						 compleateBlock:aCompleateBlock];
}

+ (void)downloadXMLFrom:(nonnull NSString *)aUrl
		 compleateBlock:(nonnull IGREXParserDownloadCompleateBlock)aCompleateBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aUrl]];
	
	if (!__xmlManager)
	{
		NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 20;

#if (PROXY_ENABLED)
		NSDictionary *proxyDict = @{[NSString stringWithFormat:@"HTTP%@Enable", kIGRProxyHTTPS ? @"S" : @""]: @YES,
									[NSString stringWithFormat:@"HTTP%@Proxy", kIGRProxyHTTPS ? @"S" : @""] : kIGRProxyAddres,
									[NSString stringWithFormat:@"HTTP%@Port", kIGRProxyHTTPS ? @"S" : @""] : @(kIGRProxyPort)};
		
		sessionConfiguration.connectionProxyDictionary = proxyDict;
#endif
		__xmlManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
		
		AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
		serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/rss+xml",
											 @"application/xspf+xml", @"text/xml", nil];
		[__xmlManager setResponseSerializer:serializer];
	}
	
	[[__xmlManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		
		if(!error)
		{
			ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:responseObject error:&error];
#if DEBUG
			NSLog(@"%@", document.rootElement);
#endif
			aCompleateBlock(document.rootElement);
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
