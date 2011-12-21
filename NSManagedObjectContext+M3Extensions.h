/*****************************************************************
 NSManagedObjectContext+M3Extensions.h
 M3CoreData
 
 Created by Martin Pilkington on 12/12/2010.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import <Cocoa/Cocoa.h>

/**
 @category NSManagedObjectContext(M3Extensions)
 This category provides a simpler interface to the more common functions in Core Data,
 handling the mundane tasks like creating fetch requests and letting you focus on deciding what
 data you want and how you want it
 */
@interface NSManagedObjectContext(M3Extensions)

/**
 @brief Returns objects in the entity with the supplied name, filtered by the predicate and sorted with the descriptors
 @param name The name of the entity to return objects from
 @param pred The predicate with which to filter the objects
 @param descriptors An array of NSSortDescriptors
 @result An array of NSManagedObjects matching the predicate in the enitty with the supplied name
 */
- (NSArray *)objectsInEntityWithName:(NSString *)name predicate:(NSPredicate *)pred sortedWithDescriptors:(NSArray *)descriptors;

- (NSArray *)objectsInEntityWithName:(NSString *)name predicate:(NSPredicate *)pred sortedWithDescriptors:(NSArray *)descriptors extraRequestSetup:(void (^)(NSFetchRequest *request))aSetup;

/**
 @brief Creates and returns a new managed object in the entity with the supplied name with default values from the supplied dictionary
 @param name The name of the entity in which to create the object
 @param aInsert YES if the new value should be inserted into the managed object context, otherwise NO.
 @result The newly created NSMangagedObject
 */
- (id)createObjectInEntityWithName:(NSString *)name shouldInsert:(BOOL)aInsert;

/**
 @brief Returns the number of objects in the entity with the supplied name, filtered by the predicate
 @param name The name of the entity to return objects from
 @param pred The predicate with which to filter the objects
 @result The number of objects in the supplied entity
 */
- (NSUInteger)numberOfObjectsInEntityWithName:(NSString *)name predicate:(NSPredicate *)pred;

@end
