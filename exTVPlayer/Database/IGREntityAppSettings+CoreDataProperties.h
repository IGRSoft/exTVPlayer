//
//  IGREntityAppSettings+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityAppSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityAppSettings (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *lastPlayedCatalog;
@property (nullable, nonatomic, retain) NSNumber *videoLanguageId;

@end

NS_ASSUME_NONNULL_END
