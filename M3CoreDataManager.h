/*****************************************************************
 M3CoreDataManager.h
 M3CoreData

 Created by Martin Pilkington on 15/07/2009.

 Please read the LICENCE.txt for licensing information

*****************************************************************/

#import <Cocoa/Cocoa.h>


/**
 @class M3CoreDataManager
 Encapsulates all the usual CoreData management code for library apps, moving it out of your sight.
 */
@interface M3CoreDataManager : NSObject {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	NSString *initialType;
	NSString *appSupportName;
	NSURL *modelURL;
	NSURL *dataStoreURL;
	
	id delegate;
}

/**
 @property delegate
 The manager's delegate
 @since Available in M3CoreData 1.0 and later
 */
@property (assign) id delegate;

/**
 Initialises the manager with the supplied data
 <b>Discussion</b>
 This method does not create any of the core data object, these are created as needed upon their access
 @param type The store type for the persistent store
 @param subName The name of the application support folder
 @result mName The name of the model to use
 @result storeName The name of the data store to load
 @since Available in M3CoreData 1.0 and later
 */
- (id)initWithInitialType:(NSString *)type modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)storeURL;

/**
 Returns the persistent store coordinator, creating it if necessary
 @result Returns the persistent store coordinator
 @since Available in M3CoreData 1.0 and later
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

/**
 Returns the managed object model, creating it if necessary
 @result Returns the managed object model
 @since Available in M3CoreData 1.0 and later
 */
- (NSManagedObjectModel *)managedObjectModel;

/**
 Returns the managed object context, creating it if necessary
 @result Returns the managed object context
 @since Available in M3CoreData 1.0 and later
 */
- (NSManagedObjectContext *)managedObjectContext;

/**
 Attempts to save the data to disk, presenting an error if it fails
 @result Returns NSTerminateNow if successful, NSTerminateCancel if not
 @since Available in M3CoreData 1.0 and later
 */
- (NSApplicationTerminateReply)save;

@end


/**
 @category M3CoreDataManager(DelegateMethods)
 Delegate methods for M3CoreDataManager
 */
@interface M3CoreDataManager(DelegateMethods) 

/**
 Calls the delegate when the manager encounters a data store which doesn't match the correct model
 @param manager The core data manager
 @param idents A set of version identifiers for the store
 @since Available in M3CoreData 1.0 and later
 */
- (void)coreDataManager:(M3CoreDataManager *)manager encounteredIncorrectModelWithVersionIdentifiers:(NSSet *)idents;

@end