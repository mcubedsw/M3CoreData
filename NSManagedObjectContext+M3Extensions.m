/*****************************************************************
 NSManagedObjectContext+M3Extensions.m
 M3CoreData
 
 Created by Martin Pilkington on 12/12/2010.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "NSManagedObjectContext+M3Extensions.h"


@implementation NSManagedObjectContext (M3Extensions)

- (NSArray *)objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors {
	return [self objectsInEntityWithName:aName predicate:aPredicate sortedWithDescriptors:aDescriptors extraRequestSetup:nil];
}

- (NSArray *)objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors extraRequestSetup:(void (^)(NSFetchRequest *aRequest))aSetup {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !aName) {
		return nil;
	}
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:aName];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		NSLog(@"entity doesn't exist in entities:%@", [mom entitiesByName]);
		return nil;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	[request setEntity:entity];
	[request setPredicate:aPredicate];
	[request setSortDescriptors:aDescriptors];
	if (aSetup) {
		aSetup(request);
	}
	
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	
	//If there was an error then return nothing
	if (error) {
		NSLog(@"error:%@", error);
		return nil;
	}
	
	return results;
}

- (id)createObjectInEntityWithName:(NSString *)aName shouldInsert:(BOOL)aInsert {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !aName) {
		return nil;
	}
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:aName];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		return nil;
	}
	
	Class managedObjectClass = NSClassFromString([entity managedObjectClassName]);
	
	return [[managedObjectClass alloc] initWithEntity:entity insertIntoManagedObjectContext:aInsert ? self : nil];
}

- (NSUInteger)numberOfObjectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate {
	NSManagedObjectModel *mom = [[self persistentStoreCoordinator] managedObjectModel];
	//Check the required variables are set
	if (!mom || !aName) 
		return NSNotFound;
	
	NSEntityDescription *entity = [[mom entitiesByName] objectForKey:aName];
	
	//If our entity doesn't exist return nil
	if (!entity) 
		return NSNotFound;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:aPredicate];
	
	NSError *error = nil;
	NSUInteger count = [self countForFetchRequest:request error:&error];
	if (error) {
		return NSNotFound;
	}
	return count;
}

@end
