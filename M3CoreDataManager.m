/*****************************************************************
 M3CoreDataManager.m
 M3CoreData
 
 Created by Martin Pilkington on 15/07/2009.
  
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3CoreDataManager.h"

@implementation M3CoreDataManager

@synthesize delegate;

- (id)initWithInitialType:(NSString *)type modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)storeURL {
	if ((self = [super init])) {
		initialType = type;
		if (!type) {
			initialType = NSXMLStoreType;
		}
		modelURL = aModelURL;
		dataStoreURL = storeURL;
	}
	return self;
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSError *error;

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    if (![persistentStoreCoordinator addPersistentStoreWithType:initialType configuration:nil URL:dataStoreURL options:options error:&error]){
		if ([error code] == 134100) {
			//If we failed with an incorrect data model error then pass the version identifiers of the store to the delegate to decide what to do next
			if ([[self delegate] respondsToSelector:@selector(coreDataManager:encounteredIncorrectModelWithVersionIdentifiers:)]) {
				persistentStoreCoordinator = nil;
				NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:initialType URL:dataStoreURL error:&error];
				[[self delegate] coreDataManager:self encounteredIncorrectModelWithVersionIdentifiers:[metadata objectForKey:NSStoreModelVersionIdentifiersKey]];
			}
		} else {
			[[NSApplication sharedApplication] presentError:error];
		}
    }    
	
    return persistentStoreCoordinator;
}


/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
    if (!managedObjectContext) {
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator: coordinator];
		}
	}
    
    return managedObjectContext;
}



- (NSApplicationTerminateReply)save {
	NSError *error = nil;
	NSInteger reply = NSTerminateNow;
	NSManagedObjectContext *moc = [self managedObjectContext];
	if (moc != nil) {
		if ([moc commitEditing]) {
			if ([moc hasChanges] && ![moc save:&error]) {
				BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES) {
					reply = NSTerminateCancel;
				} else {
					NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
					if (alertReturn == NSAlertAlternateReturn) {
						reply = NSTerminateCancel;	
					}
				}
			}
		} else {
			reply = NSTerminateCancel;
		}
	}
	return reply;
}

@end
