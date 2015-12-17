//
//  NSManagedObject+MRExtensions.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

@interface NSManagedObject (MRExtensions)

+ (NSString *)entityName;
+ (NSManagedObject *)insertInManagedObjectContext:(NSManagedObjectContext *)context;

@end
