/*****************************************************************
 M3CoreDataManager.m
 M3CoreData
 
 Created by Martin Pilkington on 15/07/2009.
  
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3CoreDataManager.h"

@implementation M3CoreDataManager {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSDictionary *storeOptions;
}


//*****//
- (id)initWithStoreType:(NSString *)aType modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)aStoreURL {
	return [self initWithStoreType:aType modelURL:aModelURL dataStoreURL:aStoreURL storeOptions:@{ 
		NSMigratePersistentStoresAutomaticallyOption : @YES, 
		NSInferMappingModelAutomaticallyOption : @YES
	}];
}

//*****//
- (id)initWithStoreType:(NSString *)aType modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)aStoreURL storeOptions:(NSDictionary *)aOptions {
	if ((self = [super init])) {
		_storeType = [aType ?: NSXMLStoreType copy];
		_modelURL = aModelURL;
		_dataStoreURL = aStoreURL;
		storeOptions = [aOptions copy];
	}
	return self;
}





#pragma mark -
#pragma mark Core Properties

//*****//
- (NSManagedObjectModel *)managedObjectModel {
    if (!managedObjectModel) {
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    }    
    return managedObjectModel;
}

//*****//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [self persistentStoreCoordinatorWithError:NULL];
}

//*****//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithError:(NSError **)aError {
	if(!persistentStoreCoordinator) {
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
		if (![persistentStoreCoordinator addPersistentStoreWithType:self.storeType
													  configuration:nil
																URL:self.dataStoreURL
															options:storeOptions
															  error:aError]) {
			persistentStoreCoordinator = nil;
		}
	}
    return persistentStoreCoordinator;
}

//*****//
- (NSManagedObjectContext *)managedObjectContext {
    if (!managedObjectContext) {
		NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
		if (coordinator) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
    return managedObjectContext;
}





#pragma mark -
#pragma mark Saving

//*****//
- (BOOL)save {
	return [self saveWithError:NULL];
}

//*****//
- (BOOL)saveWithError:(NSError **)aError {
	NSError *error = nil;
	NSManagedObjectContext *moc = self.managedObjectContext;
	if (!moc) {
		return YES;
	}

	//We don't want to quit if the user is still editing
	if (![moc commitEditing]) {
#warning Add error here
		return NO;
	}

	//If we've got changes but can't save show the error and offer whether to quit anyway
	if (moc.hasChanges && ![moc save:&error]) {
		if (aError != NULL) {
			*aError = error;
		}
		return NO;
	}
	return YES;
}

@end
