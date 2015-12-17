//
//  NSManagedObject+MRExtensions.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "NSManagedObject+MRExtensions.h"
#include <objc/runtime.h>

static NSString * const kPCTableEntityPrefix = @"IGREntity";

@implementation NSManagedObject (MRExtensions)

+ (NSString *)entityName
{
	NSString *className = [NSString stringWithUTF8String:class_getName([self class])];
	NSParameterAssert([className length] != 0);
	NSString *entityName = [className stringByReplacingOccurrencesOfString:kPCTableEntityPrefix withString:@""];
	return entityName;
}

+ (NSManagedObject *)insertInManagedObjectContext:(NSManagedObjectContext *)context
{
	NSString *className = [NSString stringWithUTF8String:class_getName([self class])];
	NSParameterAssert([className length] != 0);
	NSString *entityName = [className stringByReplacingOccurrencesOfString:kPCTableEntityPrefix withString:@""];
	NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
	return entity;
}

@end
