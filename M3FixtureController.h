/*****************************************************************
 M3FixtureController.h
 M3CoreData
 
 Created by Martin Pilkington on 28/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import <Foundation/Foundation.h>

/**
 @class M3FixtureController
 Support for text fixtures using NSManagedObjects, based upon data in a JSON store
 @since Available in M3CoreData 1.0 and later
 */
@interface M3FixtureController : NSObject {
	
}

/**
 @brief Create a new fixture controller
 @param aModel The NSManagedObjectModel to use for fixtures
 @param aURL The URL of the JSON Data Store
 @result A newly initialised fixture controller
 @since Available in M3CoreData 1.0 and later
 */
+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *)aModel andDataAtURL:(NSURL *)aURL;

/**
 @brief Create a new fixture controller
 @param aModel The NSManagedObjectModel to use for fixtures
 @param aURL The URL of the JSON Data Store
 @result A newly initialised fixture controller
 @since Available in M3CoreData 1.0 and later
 */
- (id)initWithModel:(NSManagedObjectModel *)aModel andDataAtURL:(NSURL *)aURL;

/**
 @brief Clears the internal object cache
 M3FixtureController keeps a cache of objects it creates. As long as you are only reading objects then you shouldn't need to clear the cache, but if you ever edit objects it is advised you clear the cache so you get a clean object next time
 @since Available in M3CoreData 1.0 and later
 */
- (void)clearObjectCache;

/**
 @brief Returns all the objects in the entity with the supplied name
 @param aName The name of the entity whos objects you want returning
 @result An array of NSManagedObjects
 @since Available in M3CoreData 1.0 and later
 */
- (NSArray *)objectsForEntityWithName:(NSString *)aName;

/**
 @brief Returns the object matching the supplied ID
 This method will create and fulfill all relationships required
 @param aString The ID of the object to generate, in the format ‹‹EntityName››.‹‹ObjectNumber››
 @result An NSManagedObject representing the data for the required object
 @since Available in M3CoreData 1.0 and later
 */
- (id)objectForId:(NSString *)aString;

@end
