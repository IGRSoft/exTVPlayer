//
//  IGREXParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGREXParser.h"
#import "IGRCountryParser.h"

#import <Ono/Ono.h>
#import <AFNetworking/AFNetworking.h>

#import "IGREntityExVideoCatalog.h"
#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityExTrack.h"

#if (PROXY_ENABLED)
#import <CFNetwork/CFNetwork.h>
#endif

static const NSInteger kUpdatedLimitMinutes = 5;
static BOOL _isLocked = YES;

const NSUInteger kPrefixLength = 7;
unichar kPrefix[kPrefixLength] =	{0x68, 0x74, 0x74, 0x70, 0x3A,
									 0x2F, 0x2F};

const NSUInteger kServerLength = 5;
unichar kServer[kServerLength] = {0x65, 0x78, 0x2E, 0x75, 0x61};

const NSUInteger kRSSLength = 3;
unichar kRSS[kRSSLength] = {0x72, 0x73, 0x73};

const NSUInteger kViewLength = 12;
unichar kView[kViewLength] =	{0x72, 0x5F, 0x76, 0x69, 0x64,
								 0x65, 0x6F, 0x5F, 0x76, 0x69,
								 0x65, 0x77};

const NSUInteger kMainCatalogLength = 13;
unichar kMainCatalog[kMainCatalogLength] = {0x72, 0x5F, 0x76, 0x69, 0x64,
											0x65, 0x6F, 0x5F, 0x69, 0x6E,
											0x64, 0x65, 0x78};

const NSUInteger kSearchLength = 14;
unichar kSearch[kSearchLength] =	{0x72, 0x5F, 0x76, 0x69, 0x64,
									 0x65, 0x6F, 0x5F, 0x73, 0x65,
									 0x61, 0x72, 0x63, 0x68};

static AFURLSessionManager *__xmlManager = nil;

typedef void (^IGREXParserDownloadCompleateBlock)(ONOXMLElement *xmlDocument);

@implementation IGREXParser

+ (void)initialize
{
#if (APP_STORE)
	{
		if ([IGRCountryParser currentCountry] == IGRVideoCategory_Ukr)
		{
			_isLocked = NO;
		}
		else
		{
			if ([AFNetworkReachabilityManager sharedManager].isReachable)
			{
				_isLocked = [NSData dataWithContentsOfURL:[NSURL URLWithString:kIGRLock]].bytes > 0;
			}
		}
	}
#else
	{
		_isLocked = NO;
	}
#endif
}

+ (void)parseCatalogContent:(nonnull NSString *)aCatalogId
			 compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	IGREntityExCatalog *catalog = [IGREntityExCatalog MR_findFirstOrCreateByAttribute:@"itemId"
																			withValue:aCatalogId];
	
	if (catalog.timestamp)
	{
		if ([[self class] hoursBetweenCurrwntDate:catalog.timestamp] < kUpdatedLimitMinutes)
		{
			aCompleateBlock(@[catalog]);
			return; //skip update
		}
	}
	
	NSString *command = [NSString stringWithCharacters:kView length:kViewLength];
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/%@/%@", [self serverAddress], command, aCatalogId];
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 catalog.name = [xmlDocument firstChildWithTag:@"title"].stringValue;
			 catalog.imgUrl = [[xmlDocument firstChildWithTag:@"picture"] valueForAttribute:@"url"];
			 __block NSUInteger orderId = 0;
			 
			 [xmlDocument enumerateElementsWithXPath:@"//file_list/file"
										  usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop)
			  {
				  
				  NSString *title = [element valueForAttribute:@"name"];
				  NSString *webPath = [element valueForAttribute:@"url"];
				  NSInteger duration = [[element valueForAttribute:@"duration"] integerValue];
				  
				  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ AND catalog = %@", title, catalog];
				  IGREntityExTrack *track = [IGREntityExTrack MR_findFirstWithPredicate:predicate];
				  
				  if (!track)
				  {
					  track = [IGREntityExTrack MR_createEntity];
					  track.name = title;
					  track.status = @(IGRTrackState_New);
					  track.dataStatus = @(IGRTrackDataStatus_Web);
					  track.position = @(0.0);
					  track.catalog = catalog;
					  track.orderId = @(orderId);
					  track.duration = @(duration);
				  }
				  track.webPath = webPath;
				  
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
		if ([[self class] hoursBetweenCurrwntDate:videoCatalog.timestamp] < kUpdatedLimitMinutes)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *command = [NSString stringWithCharacters:kRSS length:kRSSLength];
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/%@/%@", [self serverAddress], command, aVideoCatalogId];
	
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 NSString *title = [[xmlDocument firstChildWithTag:@"channel"] firstChildWithTag:@"title"].stringValue;
			 videoCatalog.name = title;
			 
			 [xmlDocument enumerateElementsWithXPath:@"//channel/item"
										  usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop)
			  {
				  
				  NSString *title = [element firstChildWithTag:@"title"].stringValue;
				  NSString *itemId = [element firstChildWithTag:@"guid"].stringValue;
				  
				  if (_isLocked && [[self blockedIDs] containsObject:itemId])
				  {
					  return;
				  }
				  
				  IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																					   withValue:itemId];
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
		if ([[self class] hoursBetweenCurrwntDate:chanel.timestamp] < kUpdatedLimitMinutes)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *command = [NSString stringWithCharacters:kRSS length:kRSSLength];
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/%@/%@", [self serverAddress], command, aChanelId];
	
	[self downloadXMLFrom:rrsUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 chanel.name = [[xmlDocument firstChildWithTag:@"channel"] firstChildWithTag:@"title"].stringValue;
			 
			 NSMutableArray *items = [NSMutableArray array];
			 
			 [xmlDocument enumerateElementsWithXPath:@"//channel/item"
										  usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
											  
											  [items addObject:[element firstChildWithTag:@"guid"].stringValue];
										  }];
			 
			 chanel.timestamp = [NSDate date];
			 
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
		if ([[self class] hoursBetweenCurrwntDate:videoCatalog.timestamp] < kUpdatedLimitMinutes)
		{
			aCompleateBlock(nil);
			return; //skip update
		}
	}
	
	NSString *lang = @"en";
	BOOL useRSSForVideoCatalog = NO;
	switch (aVideoCatalogId.integerValue)
	{
		case IGRVideoCategory_Rus:
			lang = @"ru";
			break;
		case IGRVideoCategory_Ukr:
			lang = @"uk";
			break;
		case IGRVideoCategory_Eng:
			lang = @"uk";
			break;
		default:
			useRSSForVideoCatalog = YES;
			break;
	}
	
	if (useRSSForVideoCatalog)
	{
		[[self class] parseVideoCatalogContent:aVideoCatalogId compleateBlock:aCompleateBlock];
		
		return;
	}
	
	NSString *command = [NSString stringWithCharacters:kMainCatalog length:kMainCatalogLength];
	NSString *xspfUrl = [NSString stringWithFormat:@"%@/%@?lang=%@", [self serverAddress], command, lang];
	
	[self downloadXMLFrom:xspfUrl
		   compleateBlock:^(ONOXMLElement *xmlDocument)
	 {
		 if (xmlDocument)
		 {
			 videoCatalog.name = aVideoCatalogId;
			 
			 void (^parseXml)(ONOXMLElement *) = ^void (ONOXMLElement * xml)
			 {
				 [xml enumerateElementsWithXPath:@"//object"
									  usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop)
				  {
					  
					  NSString *title = [element  valueForAttribute:@"title"];
					  NSString *itemId = [element valueForAttribute:@"id"];
					  
					  if (_isLocked && [[self blockedIDs] containsObject:itemId])
					  {
						  return;
					  }
					  
					  IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstOrCreateByAttribute:@"itemId"
																						   withValue:itemId];
					  chanel.name = title;
					  chanel.videoCatalog = videoCatalog;
				  }];
			 };

			 parseXml(xmlDocument);
			 
			 if (aVideoCatalogId.integerValue == IGRVideoCategory_Rus)
			 {
				 NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ru_rss" ofType:@"xml"]];
				 ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:nil];
				 
				 parseXml(document.rootElement);
			 }
			 
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
						chanel:(nullable NSString *)aChanel
				compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	if (aPage == 0)
	{
		NSBatchUpdateRequest *req = [[NSBatchUpdateRequest alloc] initWithEntityName:@"ExCatalog"];
		NSDate *now = [NSDate date];
		NSDate *minutesAgo = [now dateByAddingTimeInterval:-(kUpdatedLimitMinutes * 60)];
		req.predicate = [NSPredicate predicateWithFormat:@"chanel == nil AND timestamp <= %@", minutesAgo];
		req.propertiesToUpdate = @{@"orderId" : @(0)};
		req.resultType = NSUpdatedObjectsCountResultType;
		NSBatchUpdateResult *res = (NSBatchUpdateResult *)[MR_DEFAULT_CONTEXT executeRequest:req error:nil];
		NSLog(@"%@ objects updated", res.result);
	}
	
	NSString *command = [NSString stringWithCharacters:kSearch length:kSearchLength];
	NSString *rrsUrl = [NSString stringWithFormat:@"%@/%@?p=%@&per=50", [self serverAddress], command, @(aPage)];
	if (aChanel.length > 0)
	{
		rrsUrl = [rrsUrl stringByAppendingFormat:@"&original_id=%@", aChanel];
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
			 [xmlDocument enumerateElementsWithXPath:@"//object"
										  usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
											  
											  NSString *catalogId = [element valueForAttribute:@"id"];
											  [items addObject:catalogId];
										  }];
		 }
		 
		 aCompleateBlock(items);
	 }];
}

+ (void)parseLiveChanel:(nonnull NSString *)aChanel
				   page:(NSUInteger)aPage
		 compleateBlock:(nonnull IGREXParserCompleateBlock)aCompleateBlock
{
	return [self parseLiveSearchContent:nil
								   page:aPage
								 chanel:aChanel
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
	
	[[__xmlManager dataTaskWithRequest:request
					 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error)
	  {
		  
		  if(!error)
		  {
			  ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:responseObject error:&error];
#if DEBUG
			  //NSLog(@"%@", document.rootElement);
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

+ (NSString *)serverAddress
{
	NSString *prefix = [NSString stringWithCharacters:kPrefix length:kPrefixLength];
	NSString *server = [NSString stringWithCharacters:kServer length:kServerLength];
	NSString *mainServer = [NSString stringWithFormat:@"%@%@", prefix, server];
	
	return mainServer;
}

+ (NSInteger)hoursBetweenCurrwntDate:(NSDate *)aDate
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute
																   fromDate:aDate
																	 toDate:[NSDate date]
																	options:0];
	
	return components.minute;
}

+ (NSArray *)blockedIDs
{
	return @[@"2", @"70538", @"1988", @"422546", @"1989", @"73427589", @"78103603", @"639512", @"7513588", @"607160", @"1991", @"69663", @"28713", @"23786", @"1987", @"70533", //RUS
			 @"82470", @"82473", @"82480", @"82484", @"82489", @"82493", @"82496", @"82476", @"82488", @"82490", //UA
			 @"82316", @"82325", @"82329", @"82333", @"82339", @"82348", @"82331", @"82318", @"82335", //EN
			 @"188005", @"188015", @"188029", @"188000", @"188012", @"188018", @"188001", //ESP
			 @"45234", @"45252", @"45256", @"45253", @"82500", @"82348", @"45254", @"45246", @"82498", @"82420", //DE
			 @"969014", @"969016", @"969022", @"969023" /*PL*/];
}

@end
