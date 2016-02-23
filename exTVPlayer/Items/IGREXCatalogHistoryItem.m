//
//  IGREXCatalogHistoryItem.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/23/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGREXCatalogHistoryItem.h"

@implementation IGREXCatalogHistoryItem

- (void)encodeWithCoder:(NSCoder *)encoder
{
	if (self.itemId)
	{
		[encoder encodeObject:self.itemId forKey:@"itemId"];
	}
	if (self.name)
	{
		[encoder encodeObject:self.name forKey:@"name"];
	}
	if (self.imgUrl)
	{
		[encoder encodeObject:self.imgUrl forKey:@"imgUrl"];
	}
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		_itemId = [decoder decodeObjectForKey:@"itemId"];
		_name = [decoder decodeObjectForKey:@"name"];
		_imgUrl = [decoder decodeObjectForKey:@"imgUrl"];
	}
	
	return self;
}

@end
