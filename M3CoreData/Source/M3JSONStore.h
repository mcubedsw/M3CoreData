/*****************************************************************
 M3JSONStore.h
 M3CoreData
 
 Created by Martin Pilkington on 30/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

/**
This is a private class used by M3FixtureController and M3JSONAtomicStore.
 It is used for reading and writing a json store
 */
@interface M3JSONStore : NSObject

- (id)initWithModel:(NSManagedObjectModel *)aModel;

@property (readonly) NSManagedObjectModel *managedObjectModel;

- (NSDictionary *)loadFromURL:(NSURL *)aURL;
- (BOOL)saveObjects:(NSDictionary *)aObjects toURL:(NSURL *)aURL error:(NSError **)aError;

- (id)objectFromDictionary:(NSDictionary *)aDict withId:(NSString *)aId usingMap:(NSMutableDictionary *)aMap creationBlock:(id (^)(NSEntityDescription *entity, NSString *jsonId))aBlock;

@end
