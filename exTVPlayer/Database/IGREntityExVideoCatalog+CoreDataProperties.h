//
//  IGREntityExVideoCatalog+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityExVideoCatalog.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityExVideoCatalog (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *itemId;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet<IGREntityExChanel *> *chanels;

@end

@interface IGREntityExVideoCatalog (CoreDataGeneratedAccessors)

- (void)addChanelsObject:(IGREntityExChanel *)value;
- (void)removeChanelsObject:(IGREntityExChanel *)value;
- (void)addChanels:(NSSet<IGREntityExChanel *> *)values;
- (void)removeChanels:(NSSet<IGREntityExChanel *> *)values;

@end

NS_ASSUME_NONNULL_END
