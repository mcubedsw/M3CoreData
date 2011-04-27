/*****************************************************************
 NSManagedObjectContext+M3Extensions.m
 M3CoreData
 
 Created by Martin Pilkington on 12/12/2010.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "NSManagedObjectContext+M3Extensions.h"


@implementation NSManagedObjectContext (M3Extensions)

- (NSArray *)objectsInEntityWithName:(NSString *)name predicate:(NSPredicate *)pred sortedWithDescriptors:(NSArray *)descriptors {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !name) {
		return nil;
	}
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:name];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		NSLog(@"entity doesn't exist in entities:%@", [mom entitiesByName]);
		return nil;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	[request setEntity:entity];
	[request setPredicate:pred];
	[request setSortDescriptors:descriptors];
	
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	[request release];
	
	//If there was an error then return nothing
	if (error) {
		NSLog(@"error:%@", error);
		return nil;
	}
	
	return results;
}

- (id)createObjectInEntityWithName:(NSString *)name shouldInsert:(BOOL)aInsert {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !name) {
		return nil;
	}
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:name];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		return nil;
	}
	
	Class managedObjectClass = NSClassFromString([entity managedObjectClassName]);
	
	return [[[managedObjectClass alloc] initWithEntity:entity insertIntoManagedObjectContext:aInsert ? self : nil] autorelease];
}

- (NSUInteger)numberOfObjectsInEntityWithName:(NSString *)name predicate:(NSPredicate *)pred {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !name) 
		return NSNotFound;
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:name];
	
	//If our entity doesn't exist return nil
	if (!entity) 
		return NSNotFound;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:pred];
	
	NSError *error = nil;
	NSUInteger count = [self countForFetchRequest:request error:&error];
	[request release];
	if (error) {
		return NSNotFound;
	}
	return count;
}

@end
