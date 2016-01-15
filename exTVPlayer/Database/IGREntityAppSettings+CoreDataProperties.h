//
//  IGREntityAppSettings+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/15/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityAppSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityAppSettings (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *videoBufferSize;
@property (nullable, nonatomic, retain) NSNumber *historySize;
@property (nullable, nonatomic, retain) NSString *lastPlayedCatalog;
@property (nullable, nonatomic, retain) NSNumber *videoLanguageId;
@property (nullable, nonatomic, retain) NSNumber *sourceType;

@end

NS_ASSUME_NONNULL_END
