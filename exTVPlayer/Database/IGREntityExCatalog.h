//
//  IGREntityExCatalog.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IGREntityExChanel, IGREntityExTrack;

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityExCatalog : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+ (NSArray *)getHistory;
+ (NSArray *)getFavorites;

@end

NS_ASSUME_NONNULL_END

#import "IGREntityExCatalog+CoreDataProperties.h"
