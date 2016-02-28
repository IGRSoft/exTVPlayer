//
//  ServiceProvider.m
//  TopShelf
//
//  Created by Vitalii Parovishnyk on 2/23/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "ServiceProvider.h"
#import "IGRUserDefaults.h"
#import "IGREXCatalogTopShelfItem.h"
@import TVServices;

typedef void (^TVContentItemCompletionBlock)(NSArray *contentItems, NSError *error);

@interface ServiceProvider ()

@property (nonatomic) IGRUserDefaults *userSettings;

@end

@implementation ServiceProvider


#pragma mark - TVTopShelfProvider protocol

- (TVTopShelfContentStyle)topShelfStyle
{
    // Return desired Top Shelf style.
    return TVTopShelfContentStyleSectioned;
}

- (NSArray <TVContentItem *> *)topShelfItems
{
	NSArray *items = [self loadItems];
	
	return items;
}

- (NSArray *)loadItems
{
	self.userSettings = [[IGRUserDefaults alloc] init];
	
	TVContentItem *favorites = [self sectionFromIdentifier:@"Favorites" withItems:self.userSettings.favorites];
	TVContentItem *history = [self sectionFromIdentifier:@"History" withItems:self.userSettings.history];
	
	NSMutableArray *contentItems = [[NSMutableArray alloc] initWithCapacity:2];
	if (favorites)
	{
		[contentItems addObject:favorites];
	}
	if (history)
	{
		[contentItems addObject:history];
	}
	
	return [contentItems copy];
}

- (TVContentItem *)sectionFromIdentifier:(NSString *)anIdentifier withItems:(NSArray *)anItems
{
	NSMutableArray *tmpContentItems = [[NSMutableArray alloc] initWithCapacity:anItems.count];
	for (NSData *itemData in anItems)
	{
		IGREXCatalogTopShelfItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
		
		TVContentIdentifier *contentID = [[TVContentIdentifier alloc] initWithIdentifier:item.itemId container:nil];
		TVContentItem *contentItem = [[TVContentItem alloc] initWithContentIdentifier:contentID];
		contentItem.imageURL = [NSURL URLWithString:item.imgUrl];
		contentItem.title = item.name;
		contentItem.displayURL = [self urlItemId:item.itemId];
		contentItem.imageShape = TVContentItemImageShapePoster;
		
		[tmpContentItems addObject:contentItem];
	}
	
	TVContentItem *sectionItem = nil;
	
	if (tmpContentItems.count > 0)
	{
		NSString *identifier = [NSString stringWithFormat:@"com.igrsoft.exTVPlayer.%@", anIdentifier];
		TVContentIdentifier *sectionID = [[TVContentIdentifier alloc] initWithIdentifier:identifier container:nil];
		sectionItem = [[TVContentItem alloc] initWithContentIdentifier:sectionID];
		sectionItem.topShelfItems = tmpContentItems;
		sectionItem.title = NSLocalizedString(anIdentifier, @"");
	}

	return sectionItem;
}

- (NSURL *)urlItemId:(NSString *)anItemId
{
	NSURLComponents *component = [[NSURLComponents alloc] init];
	component.scheme = @"excatalog";
	component.queryItems = @[[NSURLQueryItem queryItemWithName:@"itemId" value:anItemId]];
	
	return component.URL;
}

@end
