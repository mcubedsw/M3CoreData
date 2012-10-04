/*****************************************************************
 NSManagedObjectContext+M3Extensions.h
 M3CoreData
 
 Created by Martin Pilkington on 12/12/2010.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

/**
 @category NSManagedObjectContext(M3Extensions)
 This category provides a simpler interface to the more common functions in Core Data,
 handling the mundane tasks like creating fetch requests and letting you focus on deciding what
 data you want and how you want it
 */
@interface NSManagedObjectContext(M3Extensions)

/**
 @brief Returns objects in the entity with the supplied name, filtered by the predicate and sorted with the descriptors
 @param aName The name of the entity to return objects from
 @param aPredicate The predicate with which to filter the objects
 @param aDescriptors An array of NSSortDescriptors
 @return An array of NSManagedObjects matching the predicate in the enitty with the supplied name
 */
- (NSArray *)m3_objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors;

/**
 @brief Returns objects in the entity with the supplied name, filtered by the predicate and sorted with the descriptors
 @param aName The name of the entity to return objects from
 @param aPredicate The predicate with which to filter the objects
 @param aDescriptors An array of NSSortDescriptors
 @param aSetup A block to preform any extra setup on the fetchrequest
 @param aError A pointer to an NSError object
 @return An array of NSManagedObjects matching the predicate in the enitty with the supplied name
 */
- (NSArray *)m3_objectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate sortedWithDescriptors:(NSArray *)aDescriptors extraRequestSetup:(void (^)(NSFetchRequest *request))aSetup error:(NSError **)aError;

/**
 @brief Creates and returns a new managed object in the entity with the supplied name with default values from the supplied dictionary
 @param aName The name of the entity in which to create the object
 @param aInsert YES if the new value should be inserted into the managed object context, otherwise NO.
 @param aError A pointer to an NSError object
 @return The newly created NSMangagedObject
 */
- (id)m3_createObjectInEntityWithName:(NSString *)aName shouldInsert:(BOOL)aInsert error:(NSError **)aError;

/**
 @brief Returns the number of objects in the entity with the supplied name, filtered by the predicate
 @param aName The name of the entity to return objects from
 @param aPredicate The predicate with which to filter the objects
 @return The number of objects in the supplied entity
 */
- (NSUInteger)m3_numberOfObjectsInEntityWithName:(NSString *)aName predicate:(NSPredicate *)aPredicate;

@end
