/*****************************************************************
 M3FixtureController.m
 M3CoreData
 
 Created by Martin Pilkington on 28/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3FixtureController.h"
#import "M3JSONStore.h"
#import "_CJSONDeserializer.h"

@implementation M3FixtureController {
	M3JSONStore *jsonStore;
	NSDictionary *dataCache;
	NSMutableDictionary *objectCache;
}

//*****//
+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *)aModel dataURL:(NSURL *)aURL {
	return [[self alloc] initWithModel:aModel dataURL:aURL];
}


//*****//
- (id)initWithModel:(NSManagedObjectModel *)aModel dataURL:(NSURL *)aURL {
	if ((self = [super init])) {
		_managedObjectModel = aModel;
		_dataURL = aURL;
		jsonStore = [[M3JSONStore alloc] initWithModel:aModel];
		objectCache = [NSMutableDictionary new];
		dataCache = [[jsonStore loadFromURL:aURL] copy];
	}
	return self;
}


//*****//
- (void)clearObjectCache {
	objectCache = [NSMutableDictionary new];
}


//*****//
- (NSArray *)objectsForEntityWithName:(NSString *)aName {
	NSArray *objectKeys = [dataCache.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH %@", aName]];
	NSMutableArray *returnArray = [NSMutableArray array];
	for (NSString *objectId in objectKeys) {
		[returnArray addObject:[self objectForId:objectId]];
	}
	return [returnArray copy];
}

//*****//
- (id)objectForId:(NSString *)aId {
	id object = [jsonStore objectFromDictionary:dataCache withId:aId usingMap:objectCache creationBlock:^(NSEntityDescription *entity, NSString *jsonId) {
		 return [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
	}];
	return object;
}

@end
