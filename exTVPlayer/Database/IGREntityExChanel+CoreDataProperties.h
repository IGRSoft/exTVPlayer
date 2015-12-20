//
//  IGREntityExChanel+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/20/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityExChanel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityExChanel (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *itemId;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) NSSet<IGREntityExCatalog *> *catalogs;
@property (nullable, nonatomic, retain) IGREntityExVideoCatalog *videoCatalog;

@end

@interface IGREntityExChanel (CoreDataGeneratedAccessors)

- (void)addCatalogsObject:(IGREntityExCatalog *)value;
- (void)removeCatalogsObject:(IGREntityExCatalog *)value;
- (void)addCatalogs:(NSSet<IGREntityExCatalog *> *)values;
- (void)removeCatalogs:(NSSet<IGREntityExCatalog *> *)values;

@end

NS_ASSUME_NONNULL_END
