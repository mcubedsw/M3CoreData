/*****************************************************************
 M3CoreDataManager.m
 M3CoreData
 
 Created by Martin Pilkington on 15/07/2009.
  
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3CoreDataManager.h"

@interface M3CoreDataManager ()

- (void)p_setupPersistentStoreCoordinator;

@end


@implementation M3CoreDataManager {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}


//*****//
- (id)initWithInitialType:(NSString *)aType modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)aStoreURL {
	if ((self = [super init])) {
		_initialType = [aType ?: NSXMLStoreType copy];
		_modelURL = aModelURL;
		_dataStoreURL = aStoreURL;
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
	if(!persistentStoreCoordinator) {
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
		[self p_setupPersistentStoreCoordinator];
	}
    return persistentStoreCoordinator;
}


//*****//
- (void)p_setupPersistentStoreCoordinator {
	NSError *error = nil;
	NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption:@YES };
	NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:self.initialType
																		configuration:nil
																				  URL:self.dataStoreURL
																			  options:options
																				error:&error];
	if (!store) {
		if (error.code != NSPersistentStoreIncompatibleVersionHashError) {
			[[NSApplication sharedApplication] presentError:error];
			return;
		}
		
		//If we failed with an incorrect data model error then pass the version identifiers of the store to the delegate to decide what to do next
		if ([self.delegate respondsToSelector:@selector(coreDataManager:encounteredIncorrectModelWithVersionIdentifiers:)]) {
			persistentStoreCoordinator = nil;
			NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:self.initialType URL:self.dataStoreURL error:&error];
			[self.delegate coreDataManager:self encounteredIncorrectModelWithVersionIdentifiers:metadata[NSStoreModelVersionIdentifiersKey]];
		}
	}
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
- (NSApplicationTerminateReply)save {
	NSError *error = nil;
	NSManagedObjectContext *moc = self.managedObjectContext;
	if (!moc) {
		return NSTerminateNow;
	}

	//We don't want to quit if the user is still editing
	if (![moc commitEditing]) {
		return NSTerminateCancel;
	}

	//If we've got changes but can't save show the error and offer whether to quit anyway
	if (moc.hasChanges && ![moc save:&error]) {
		BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
		
		if (errorResult == YES) {
			return NSTerminateCancel;
		}

		NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
		if (alertReturn == NSAlertAlternateReturn) {
			return NSTerminateCancel;
		}
	}
	return NSTerminateNow;
}

@end
