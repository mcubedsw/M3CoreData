//
//  M3ManagedObjectFactory.m
//  M3CoreData
//
//  Created by Martin Pilkington on 28/01/2013.
//  Copyright (c) 2013 M Cubed Software. All rights reserved.
//

#import "M3ManagedObjectFactory.h"

@implementation M3ManagedObjectFactory

- (id)createObjectWithEntity:(NSEntityDescription *)aEntity JSONID:(NSString *)aJSONID {
	return [[NSManagedObject alloc] initWithEntity:aEntity insertIntoManagedObjectContext:nil];
}

@end
