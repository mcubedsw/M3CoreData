#M3CoreData 1.0

M3CoreData adds a series of extensions to the CoreData framework. It consists of 3 items:

- **M3CoreDataManager** Hides away all the usual CoreData setup code into a separate class
- **M3FixtureController** Adds support quickly generating fixture objects for testing from a JSON store
- **NSManagedObjectContext+M3Extensions** Adds some methods to simplify adding/retrieving objects

M3CoreData is licensed under the MIT licence


##JSON Store Format

The Fixtures Controller requires a specific structure on disk. Stores are folders, which contain the following:

- A **_Metadata.json** file for storing a dictionary of store metadata
- A JSON file for each entity called ‹‹entity name››.json

Each entity JSON file has a root dictionary. This dictionary contains the ID (a string) as the key and the object data (another dictionary) as the value. The object data contains the key-value pairs for the stored object. To many relationships should be represented as an array of IDs. Dates should be strings in the format yyyy-mm-dd hh:mm:ss ±hhmm.

Relationships are defined with simple IDs, in the format "‹‹entity name››.‹‹object id››".

For an example, see JSONStore.jsondata in the M3CoreData Tests project


##Change Log

###1.0
* Tidied up the source
* Completed comments
* No longer supports Garbage Collection, instead uses ARC
* Removed many dependencies on AppKit in preparation for iOS version
* Added unit tests
* Removed M3JSONAtomicStore from framework

####API changes
_NSManagedObjectContext+M3Extensions_

**Added**
`- (NSArray *)m3_objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors extraRequestSetup:(void (^)(NSFetchRequest *request))aSetup error:(NSError **)aError`

**Changed**
Old: `- (NSArray *)objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)`
New: `- (NSArray *)m3_objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)`

Old: `- (NSArray *)objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *) extraRequestSetup:(void (^)(NSFetchRequest *request))`
New: `- (NSArray *)m3_objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *) extraRequestSetup:(void (^)(NSFetchRequest *request)) error:(NSError **)`

**Removed**
`- (id)createObjectInEntityWithName:(NSString *) shouldInsert:(BOOL)`

<hr/>

_M3CoreDataManager_

**Added**
`- (id)initWithInitialType:(NSString *) modelURL:(NSURL *) dataStoreURL:(NSURL *) storeOptions:(NSDictionary *)`
`@property (readonly) NSURL *dataStoreURL`
`@property (readonly) NSURL *modelURL`
`@property (readonly) NSURL *initialType`
`- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithError:(NSError **)`
`- (BOOL)saveWithError:(NSError **)`

**Changed**
Old: `@property (assign) id delegate`
New: `@property (weak) id<M3CoreDataManagerDelegate> delegate`
	
Old: `- (NSPersistentStoreCoordinator *)persistentStoreCoordinator`
New: `@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator`

Old: `- (NSManagedObjectModel *)managedObjectModel`
New: `@property (readonly) NSManagedObjectModel *managedObjectModel`

Old: `- (NSManagedObjectContext *)managedObjectContext`
New: `@property (readonly) NSManagedObjectContext *managedObjectContext`

Old: `- (NSApplicationTerminateReply)save`
New: `- (BOOL)save`

<hr/>

_M3FixtureController_

**Added**
`@property (readonly) NSManagedObjectModel *managedObjectModel`
`@property (readonly) NSURL *dataURL`

**Changed**
Old: `+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *) andDataAtURL:(NSURL *)`
New: `+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *) dataURL:(NSURL *)`

Old: `- (id)initWithModel:(NSManagedObjectModel *) andDataAtURL:(NSURL *)`
New: `- (id)initWithModel:(NSManagedObjectModel *) dataURL:(NSURL *)`

Old: `- (id)objectForID:(NSString *)`
New: `- (id)objectWithID:(NSString *) inEntityWithName:(NSString *)`

<hr/>