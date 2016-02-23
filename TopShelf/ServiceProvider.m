//
//  ServiceProvider.m
//  TopShelf
//
//  Created by Vitalii Parovishnyk on 2/23/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "ServiceProvider.h"
#import "IGRUserDefaults.h"
#import "IGREXCatalogHistoryItem.h"
@import TVServices;

typedef void (^TVContentItemCompletionBlock)(NSArray *contentItems, NSError *error);

@interface ServiceProvider ()

@property (nonatomic, copy) NSArray *items;
@property (nonatomic) IGRUserDefaults *userSettings;

@end

@implementation ServiceProvider


- (instancetype)init
{
    self = [super init];
    if (self)
	{
		self.items = @[];
		[self loadSectionedItemsWithCompletion:^(NSArray *contentItems, NSError *error) {
			
			if (contentItems.count > 0)
			{
				self.items = [contentItems copy];
				[[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification
																	object:nil];
			}
		}];
    }
	
    return self;
}

#pragma mark - TVTopShelfProvider protocol

- (TVTopShelfContentStyle)topShelfStyle
{
    // Return desired Top Shelf style.
    return TVTopShelfContentStyleSectioned;
}

- (NSArray <TVContentItem *> *)topShelfItems
{
    return [self.items copy];
}

- (void)loadSectionedItemsWithCompletion:(TVContentItemCompletionBlock)completionBlock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		self.userSettings = [[IGRUserDefaults alloc] init];
		
		NSArray *history = self.userSettings.history;
		
		TVContentIdentifier *sectionID = [[TVContentIdentifier alloc] initWithIdentifier:@"com.igrsoft.exTVPlayer.history" container:nil];

		NSArray *contentItems = @[];
		NSMutableArray *tmpContentItems = [[NSMutableArray alloc] initWithCapacity:history.count];
		for (NSData *itemData in history)
		{
			IGREXCatalogHistoryItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
			
			TVContentIdentifier *contentID = [[TVContentIdentifier alloc] initWithIdentifier:item.itemId container:nil];
			TVContentItem *contentItem = [[TVContentItem alloc] initWithContentIdentifier:contentID];
			contentItem.imageURL = [NSURL URLWithString:item.imgUrl];
			contentItem.title = item.name;
			contentItem.displayURL = [self urlItemId:item.itemId];
			contentItem.imageShape = TVContentItemImageShapePoster;
			
			[tmpContentItems addObject:contentItem];
		}
		
		if (tmpContentItems.count > 0)
		{
			TVContentItem *sectionItem = [[TVContentItem alloc] initWithContentIdentifier:sectionID];
			sectionItem.topShelfItems = tmpContentItems;
			sectionItem.title = @"History";
			
			contentItems = @[sectionItem];
		}
		
		if (completionBlock)
		{
			completionBlock(contentItems, nil);
		}
	});
}

- (NSURL *)urlItemId:(NSString *)anItemId
{
	NSURLComponents *component = [[NSURLComponents alloc] init];
	component.scheme = @"excatalog";
	component.queryItems = @[[NSURLQueryItem queryItemWithName:@"itemId" value:anItemId]];
	
	return component.URL;
}

@end
