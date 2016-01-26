//
//  IGREntityExTrack+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/26/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityExTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityExTrack (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *dataStatus;
@property (nullable, nonatomic, retain) NSString *localName;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *orderId;
@property (nullable, nonatomic, retain) NSNumber *position;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSString *webPath;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) IGREntityExCatalog *catalog;

@end

NS_ASSUME_NONNULL_END
