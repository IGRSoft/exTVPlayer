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
static AFURLSessionManager *__imageManager = nil;

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
	
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/playlist/%@.xspf", kMainServer, aCatalogId];
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(RXMLElement *xmlDocument)
	 {
		 NSParameterAssert(xmlDocument.isValid);
		 
		 if (xmlDocument)
		 {
			 NSString *title = [xmlDocument child:@"title"].text;
			 catalog.name = title;
			 
			 __block NSUInteger orderId = 0;
			 [xmlDocument iterate:@"trackList.track" usingBlock:^(RXMLElement *node) {
				 
				 NSString *title = [node child:@"title"].text;
				 NSString *webPath = [node child:@"location"].text;
				 
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
			 
			 if (!catalog.imgUrl)
			 {
				 NSString *rrsUrl = [NSString stringWithFormat:@"%@/rss/%@", kMainServer, aCatalogId];
				 [self downloadImageXMLFrom:rrsUrl
						compleateBlock:^(RXMLElement *xmlDocument)
				  {
					  NSParameterAssert(xmlDocument.isValid);
					  
					  if (xmlDocument)
					  {
						  [xmlDocument iterate:@"channel.image.url" usingBlock:^(RXMLElement *node) {
							  
							  NSString *imgUrl = node.text;
							  imgUrl = [imgUrl componentsSeparatedByString:@"?"].firstObject;
							  catalog.imgUrl = imgUrl;
						  }];
						  
						  if (MR_DEFAULT_CONTEXT.hasChanges)
						  {
							  [MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
						  }
					  }
				  }];
			 }
			 
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
				 
				 [items addObject:node];
			 }];
			 
			 NSInteger itemsCount = items.count - 1;
			 
			 NSNumber *lastId = [IGREntityExCatalog MR_findLargestValueForAttribute:@"orderId"];
			 __block NSUInteger orderId = lastId.integerValue;
			 
			 for (RXMLElement *node in [items reverseObjectEnumerator])
			 {
				 NSString *title = [node child:@"title"].text;
				 NSString *itemId = [node child:@"guid"].text;
				 
				 IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId" withValue:itemId];
				 
				 if (catalog.orderId.integerValue == (orderId - itemsCount--))
				 {
					 continue; //same position;
				 }
				 
				 if (!catalog.imgUrl)
				 {
					 NSString *rrsUrl = [NSString stringWithFormat:@"%@/rss/%@", kMainServer, itemId];
					 [self downloadImageXMLFrom:rrsUrl
								 compleateBlock:^(RXMLElement *xmlDocument)
					  {
						  NSParameterAssert(xmlDocument.isValid);
						  
						  if (xmlDocument)
						  {
							  [xmlDocument iterate:@"channel.image.url" usingBlock:^(RXMLElement *node) {
								  
								  NSString *imgUrl = node.text;
								  imgUrl = [imgUrl componentsSeparatedByString:@"?"].firstObject;
								  catalog.imgUrl = imgUrl;
							  }];
							  
							  if (MR_DEFAULT_CONTEXT.hasChanges)
							  {
								  [MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
							  }
						  }
					  }];
				 }
				 catalog.name = title;
				 catalog.chanel = chanel;
				 
				 catalog.orderId = @(orderId++);
			 }
			 
			 chanel.timestamp = [NSDate date];
			 
			 if (MR_DEFAULT_CONTEXT.hasChanges)
			 {
				 [MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
			 }
			 
			 aCompleateBlock(@[chanel]);
		 }
	 }];
}

+ (void)parseLiveSearchContent:(nonnull NSString *)aSearchText
						  page:(NSUInteger)aPage
					   catalog:(NSInteger)aCatalog
				compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/r_video_search?s=%@&p=%@", kAdditionalServer, aSearchText, @(aPage)];
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
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/r_video_search?original_id=%@&p=%@", kAdditionalServer, aCatalog, @(aPage)];
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

+ (void)downloadImageXMLFrom:(nonnull NSString *)aUrl
			  compleateBlock:(nonnull IGREXParserDownloadCompleateBlock)aCompleateBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aUrl]];
	
	if (!__imageManager)
	{
		NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:NSStringFromClass([IGREXParser class])];
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 10;
		
		__imageManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
		
		AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
		serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/rss+xml",
											 @"application/xspf+xml", @"text/xml", nil];
		[__imageManager setResponseSerializer:serializer];
	}
	
	[[__imageManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		
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
