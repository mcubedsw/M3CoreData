#M3CoreData

M3CoreData adds a series of extensions to the CoreData framework. It consists of 4 items:

- **M3CoreDataManager** Hides away all the usual CoreData setup code into a separate class
- **M3JSONAtomicStore** Adds support for JSON based data stores
- **M3FixtureController** Adds support quickly generating fixture objects for testing from a JSON store
- **NSManagedObjectContext+M3Extensions** Adds some methods to simplify adding/retrieving objects

M3CoreData is licensed under the MIT licence

**Please consider this a 1.0 alpha of the framework.** While the method signatures are unlikely to change, I am not yet ready to mark this as final, so source compatibility isn't guaranteed between source checkins (ie methods may be added/removed/changed without any sort of deprecation warning). I will hopefully have a version I'm ready to declare 1.0 final in the near future.


##JSON Store Format

The JSON Store and Fixtures Controller requires a specific structure on disk. Stores are folders, which contain the following:

- A **_Metadata.json** file for storing store metadata
- A JSON file for each entity called ‹‹entity name››.json

Each entity JSON file has a root dictionary. This dictionary contains the ID (an integer) as the key and the object data (another dictionary) as the value. The object data contains the key-value pairs for the stored object. To many relationships should be represented as an array of IDs. Dates should be strings in the format yyyy-mm-dd hh:mm:ss ±hhmm.

Relationships are defined with simple IDs, in the format "‹‹entity name››.‹‹object id››".

While this store can potentially be used in production code, I would urge caution as it hasn't been extensively tested. It's primary aim is to seed test data into a Core Data store.

##Changes Log


###1.0 alpha 2
* Tidied up the source
* Completed comments
* No longer supports Garbage Collection, instead uses ARC

####API changes
_NSManagedObjectContext+M3Extensions_
**Changed**
Old: `- (NSArray *)objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)`
New: `- (NSArray *)m3_objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)`

Old: `- (NSArray *)objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)extraRequestSetup:(void (^)(NSFetchRequest *request))`
New: `- (NSArray *)m3_objectsinEntityWithName:(NSString *) predicate:(NSPredicate *) sortedWithDescriptors:(NSArray *)extraRequestSetup:(void (^)(NSFetchRequest *request)) error:(NSError **)`

Old: `- (id)createObjectInEntityWithName:(NSString *) shouldInsert:(BOOL)`
New: `- (id)m3_createObjectInEntityWithName:(NSString *) shouldInsert:(BOOL) error:(NSError **)`

<hr/>

_M3CoreDataManager_

**Added**
`@property (readonly) NSURL *dataStoreURL`
`@property (readonly) NSURL *modelURL`
`@property (readonly) NSURL *initialType`

**Changed**
Old: `@property (assign) id delegate`
New: `@property (weak) id<M3CoreDataManagerDelegate> delegate`
	
Old: `- (NSPersistentStoreCoordinator *)persistentStoreCoordinator`
New: `@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator`

Old: `- (NSManagedObjectModel *)managedObjectModel`
New: `@property (readonly) NSManagedObjectModel *managedObjectModel`

Old: `- (NSManagedObjectContext *)managedObjectContext`
New: `@property (readonly) NSManagedObjectContext *managedObjectContext`

