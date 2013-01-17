/*****************************************************************
 M3CoreDataManager.h
 M3CoreData

 Created by Martin Pilkington on 15/07/2009.

 Please read the LICENCE.txt for licensing information
*****************************************************************/

@protocol M3CoreDataManagerDelegate;

/**
 @class M3CoreDataManager
 Encapsulates all the usual CoreData management code for library apps, moving it out of your sight.
 */
@interface M3CoreDataManager : NSObject 

/**
 Initialises the manager with the supplied data
 <b>Discussion</b>
 This method does not create any of the core data object, these are created as needed upon their access. It sets the default store options to
 @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES }
 @param aType The initial store type for the persistent store
 @param aModelURL The URL location of the model file to use for the store
 @param aStoreURL The URL location of the store file
 @result A newly initialised M3CoreDataManager
 @since Available in M3CoreData 1.0 and later
 */
- (id)initWithStoreType:(NSString *)aType modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)aStoreURL;

/**
 Initialises the manager with the supplied data
 <b>Discussion</b>
 This method does not create any of the core data object, these are created as needed upon their access
 @param aType The initial store type for the persistent store
 @param aModelURL The URL location of the model file to use for the store
 @param aStoreURL The URL location of the store file
 @param aOptions The options to use when creating the persistent store
 @return A newly initialised M3CoreDataManager
 @since Available in M3CoreData 1.0 and later
 */
- (id)initWithStoreType:(NSString *)aType modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)aStoreURL storeOptions:(NSDictionary *)aOptions;

/**
 Returns the URL of the data store backing the managed object context
 @since M3CoreData 1.0 or later
 */
@property (readonly) NSURL *dataStoreURL;

/**
 Returns the URL of the managed object model file on disk
 @since M3CoreData 1.0 or later
 */
@property (readonly) NSURL *modelURL;

/**
 Returns the initial type for the persistent store
 @since M3CoreData 1.0 or later
 */
@property (readonly) NSString *storeType;

/**
 Returns the persistent store coordinator, creating it if necessary
 @since Available in M3CoreData 1.0 and later
 */
@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 Returns the managed object model, creating it if necessary
 @since Available in M3CoreData 1.0 and later
 */
@property (readonly) NSManagedObjectModel *managedObjectModel;

/**
 Returns the managed object context, creating it if necessary
 @since Available in M3CoreData 1.0 and later
 */
@property (readonly) NSManagedObjectContext *managedObjectContext;


/**
 Returns the persistent store coordinator, creating it if necessary
 @param aError An error pointer that will be filled with  any errors that occur during creation of the persistent store coordinator
 @return The manager's persistent store coordinator, or nil if it could not be created for any reason
 @since M3CoreData 1.0 or later
*/
- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithError:(NSError **)aError;

/**
 Saves the data to disk
 @return Returns YES if successful, NO if not
 @since PROJECT_NAME VERSION_NAME or later
*/
- (BOOL)save;

/**
 Saves the data to disk
 @param aError
 @return Returns YES if successful, NO if not
 @since Available in M3CoreData 1.0 and later
 */
- (BOOL)saveWithError:(NSError **)aError;

@end
