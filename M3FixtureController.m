/*****************************************************************
 M3FixtureController.m
 M3CoreData
 
 Created by Martin Pilkington on 28/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3FixtureController.h"
#import "M3JSONStore.h"
#import "_CJSONDeserializer.h"

@interface M3FixtureController () {
	M3JSONStore *jsonStore;
	NSDictionary *dataCache;
	NSMutableDictionary *objectCache;
}
@end

@implementation M3FixtureController

+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *)aModel andDataAtURL:(NSURL *)aURL {
	return [[[self alloc] initWithModel:aModel andDataAtURL:aURL] autorelease];
}

- (id)initWithModel:(NSManagedObjectModel *)aModel andDataAtURL:(NSURL *)aURL {
	if ((self = [super init])) {
		jsonStore = [[M3JSONStore alloc] initWithModel:aModel];
		objectCache = [[NSMutableDictionary alloc] init];
		dataCache = [[jsonStore loadFromURL:aURL] copy];
	}
	return self;
}

- (void)dealloc {
	[jsonStore release];
	[dataCache release];
	[objectCache release];
	[super dealloc];
}

- (void)clearObjectCache {
	[objectCache release];
	objectCache = [[NSMutableDictionary alloc] init];
}

- (NSArray *)objectsForEntityWithName:(NSString *)aName {
	NSArray *objectKeys = [[dataCache allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH %@", aName]];
	NSMutableArray *returnArray = [NSMutableArray array];
	for (NSString *objectId in objectKeys) {
		[returnArray addObject:[self objectForId:objectId]];
	}
	return [[returnArray copy] autorelease];
}

- (id)objectForId:(NSString *)aId {
	id object = [jsonStore objectFromDictionary:dataCache 
									withId:aId 
								  usingMap:objectCache 
							 creationBlock:^(NSEntityDescription *entity, NSString *jsonId) 
	{
		 return [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
	}];
	return object;
}

@end
