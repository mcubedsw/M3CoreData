/*****************************************************************
 M3FixtureController.m
 M3CoreData
 
 Created by Martin Pilkington on 28/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3FixtureController.h"
#import "M3JSONStore.h"
#import "M3ManagedObjectFactory.h"
#import "_CJSONDeserializer.h"

@implementation M3FixtureController {
	M3JSONStore *jsonStore;
	NSDictionary *dataCache;
	NSMutableDictionary *objectCache;
}


+ (M3FixtureController *)fixtureControllerWithModel:(NSManagedObjectModel *)aModel dataURL:(NSURL *)aURL {
	return [[self alloc] initWithModel:aModel dataURL:aURL];
}


- (id)initWithModel:(NSManagedObjectModel *)aModel dataURL:(NSURL *)aURL {
	if ((self = [super init])) {
		_managedObjectModel = aModel;
		_dataURL = aURL;
		
		
		jsonStore = [[M3JSONStore alloc] initWithManagedObjectModel:aModel dataURL:aURL objectFactory:[M3ManagedObjectFactory new]];
		
	}
	return self;
}


- (NSDictionary *)dataCache {
	if (!dataCache) {
		NSError *error = nil;
		if (!(dataCache = [jsonStore loadObjects:&error])) {
			NSLog(@"Error loading data store: %@", error);
		}
	}
	return dataCache;
}


- (void)clearObjectCache {
	dataCache = nil;
}


- (NSArray *)objectsForEntityWithName:(NSString *)aEntityName {
	NSDictionary *entity = self.dataCache[aEntityName];
	if (!entity) {
		NSLog(@"Error: entity with name '%@' does not exist", aEntityName);
		return nil;
	}
	return [entity allValues];
}


- (id)objectWithID:(NSString *)aObjectID inEntityWithName:(NSString *)aEntityName {
	NSDictionary *entity = self.dataCache[aEntityName];
	
	if (!entity) {
		NSLog(@"Error: entity with name '%@' does not exist", aEntityName);
		return nil;
	}
	
	id object = entity[aObjectID];
	
	if (!object) {
		NSLog(@"Error: object with ID '%@' does not exist", aObjectID);
	}
	
	return object;
}

@end
