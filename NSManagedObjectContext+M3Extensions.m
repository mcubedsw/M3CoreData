/*****************************************************************
 NSManagedObjectContext+M3Extensions.m
 M3CoreData
 
 Created by Martin Pilkington on 12/12/2010.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "NSManagedObjectContext+M3Extensions.h"

@interface NSManagedObjectContext (M3ExtensionsPrivate)

- (NSError *)p_entityNotFoundErrorWithName:(NSString *)aName;

@end


@implementation NSManagedObjectContext (M3Extensions)

//*****//
- (NSArray *)m3_objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors {
	return [self m3_objectsInEntityWithName:aName predicate:aPredicate sortedWithDescriptors:aDescriptors extraRequestSetup:nil error:NULL];
}


//*****//
- (NSArray *)m3_objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors extraRequestSetup:(void (^)(NSFetchRequest *aRequest))aSetup error:(NSError **)aError {
	NSManagedObjectModel *mom = self.persistentStoreCoordinator.managedObjectModel;
	//Check the required variables are set
	if (!mom || !aName) {
		if (aError != NULL) {
			*aError = [self p_entityNotFoundErrorWithName:aName];
		}
		return nil;
	}
	
	NSEntityDescription *entity = mom.entitiesByName[aName];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		if (aError != NULL) {
			*aError = [self p_entityNotFoundErrorWithName:aName];
		}
		return nil;
	}
	
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];
	[request setPredicate:aPredicate];

	[request setSortDescriptors:aDescriptors];
	if (aSetup) {
		aSetup(request);
	}

	return [self executeFetchRequest:request error:aError];
}


//*****//
- (id)m3_createObjectInEntityWithName:(NSString *)aName shouldInsert:(BOOL)aInsert error:(NSError **)aError {
	NSManagedObjectModel *mom = self.persistentStoreCoordinator.managedObjectModel;
	//Check the required variables are set
	if (!mom || !aName) {
		if (aError != NULL) {
			*aError = [self p_entityNotFoundErrorWithName:aName];
		}
		return nil;
	}
	
	NSEntityDescription *entity = mom.entitiesByName[aName];
	
	//If our entity doesn't exist return nil
	if (!entity) {
		if (aError != NULL) {
			*aError = [self p_entityNotFoundErrorWithName:aName];
		}
		return nil;
	}
	
	Class managedObjectClass = NSClassFromString(entity.managedObjectClassName);
	
	return [[managedObjectClass alloc] initWithEntity:entity insertIntoManagedObjectContext:aInsert ? self : nil];
}


//*****//
- (NSUInteger)m3_numberOfObjectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate {
	NSManagedObjectModel *mom = self.persistentStoreCoordinator.managedObjectModel;
	//Check the required variables are set
	if (!mom || !aName) 
		return NSNotFound;
	
	NSEntityDescription *entity = mom.entitiesByName[aName];
	
	//If our entity doesn't exist return nil
	if (!entity) 
		return NSNotFound;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:aPredicate];

	return [self countForFetchRequest:request error:NULL];
}





#pragma mark -
#pragma mark Errors

//*****//
- (NSError *)p_entityNotFoundErrorWithName:(NSString *)aName {
	return [NSError errorWithDomain:M3CoreDataErrorDomain code:M3EntityNotFoundError userInfo:@{
		NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not find the entity with name:%@",aName]
	}];
}

@end
