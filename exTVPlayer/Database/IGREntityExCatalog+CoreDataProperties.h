//
//  IGREntityExCatalog+CoreDataProperties.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IGREntityExCatalog.h"

NS_ASSUME_NONNULL_BEGIN

@interface IGREntityExCatalog (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *itemId;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet<IGREntityExTrack *> *tracks;
@property (nullable, nonatomic, retain) IGREntityExChanel *chanel;

@end

@interface IGREntityExCatalog (CoreDataGeneratedAccessors)

- (void)addTracksObject:(IGREntityExTrack *)value;
- (void)removeTracksObject:(IGREntityExTrack *)value;
- (void)addTracks:(NSSet<IGREntityExTrack *> *)values;
- (void)removeTracks:(NSSet<IGREntityExTrack *> *)values;

@end

NS_ASSUME_NONNULL_END
