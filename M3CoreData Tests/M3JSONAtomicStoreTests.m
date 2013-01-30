/*****************************************************************
 M3JSONAtomicStoreTests.m
 M3CoreData
 
 Created by Martin Pilkington on 27/04/2011.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import "M3JSONAtomicStoreTests.h"

#import <M3CoreData/M3CoreData.h>

@implementation M3JSONAtomicStoreTests {
	M3JSONAtomicStore *store;
	NSManagedObjectModel *managedObjectModel;
	NSURL *dataURL;
}

//- (void)setUp {
//	NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"com.mcubedsw.M3CoreData-Tests"];
//	
//	NSURL *dataTemplateURL = [testBundle URLForResource:@"JSONStore" withExtension:@"jsondata"];
//	dataURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"JSONStore.jsondata"]];
//	[self makeStoreUsingTemplate:dataTemplateURL];
//	
//	NSURL *testModelURL = [testBundle URLForResource:@"TestModel" withExtension:@"mom"];
//	
//	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:testModelURL];
//	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
//	
//	store = [[M3JSONAtomicStore alloc] initWithPersistentStoreCoordinator:coordinator configurationName:nil URL:dataURL options:nil];
//}
//
//
//- (void)makeStoreUsingTemplate:(NSURL *)aTemplateURL {
//	NSFileManager *fileManager = [NSFileManager new];
//	
//	if ([fileManager fileExistsAtPath:dataURL.path]) {
//		[fileManager removeItemAtURL:dataURL error:NULL];
//	}
//	
//	[fileManager copyItemAtURL:aTemplateURL toURL:dataURL error:NULL];
//}
//
//
//#pragma mark -
//#pragma mark Metadata
//
//- (void)test_loadsAndSetsMetadataWhenInitialised {
//	NSDictionary *metadata = store.metadata;
//	
//	assertThat(metadata, isNot(nilValue()));
//}
//
//- (void)test_returnsMetadataForStore {
//	NSDictionary *metadata = store.metadata;
//	
//	assertThat(metadata[@"M3TestMetadataNumber"], is(equalTo(@1)));
//	assertThat(metadata[@"M3TestMetadataString"], is(equalTo(@"foobar")));
//}
//
//- (void)test_returnsStoreUUIDInMetadataForStore {
//	NSDictionary *metadata = store.metadata;
//	
//	assertThat(metadata[NSStoreUUIDKey], is(equalTo(@"1234567890")));
//}
//
//- (void)test_returnsStoreTypeInMetadataForStore {
//	NSDictionary *metadata = store.metadata;
//	
//	assertThat(metadata[NSStoreTypeKey], is(equalTo(M3JSONStoreType)));
//}
//
//- (void)test_returnsMetadataForStoreAtGivenURL {
//	NSDictionary *metadata = [M3JSONAtomicStore metadataForPersistentStoreWithURL:dataURL error:NULL];
//	
//	assertThat(metadata[@"M3TestMetadataNumber"], is(equalTo(@1)));
//	assertThat(metadata[@"M3TestMetadataString"], is(equalTo(@"foobar")));
//}
//
//- (void)test_setsMetadataForStoreAtGivenURL {
//	NSDictionary *expectedMetadata = @{@"foobar": @"baz"};
//	[M3JSONAtomicStore setMetadata:expectedMetadata forPersistentStoreWithURL:dataURL error:NULL];
//	
//	NSData *metadata = [NSData dataWithContentsOfURL:[dataURL URLByAppendingPathComponent:@"_Metadata.json"] options:0 error:NULL];
//	NSDictionary *actualMetadata = [NSJSONSerialization JSONObjectWithData:metadata options:0 error:NULL];
//	
//	assertThat(actualMetadata, is(equalTo(expectedMetadata)));
//}
//
//
//
//
//#pragma mark -
//#pragma mark Miscellaneous
//
//- (void)test_returnsStoreIdentifier {
//	assertThat(store.identifier, is(equalTo(store.metadata[NSStoreUUIDKey])));
//}
//
//- (void)test_setsStoreIdentifier {
//	STFail(@"Causes exception"); return;
//	[store setIdentifier:@"abcde"];
//	
//	assertThat(store.identifier, is(equalTo(@"abcde")));
//	
//}
//
//- (void)test_returnsJSONStoreAsType {
//	assertThat(store.type, is(equalTo(M3JSONStoreType)));
//}
//
//
//
//
//
//#pragma mark -
//#pragma mark Loading
//
//- (void)test_createsNodesForEachObjectInDataStore {
//	NSSet *nodes = store.cacheNodes;
//	
//	assertThat(nodes, hasCountOf(5));
//}
//
//- (void)test_createsNodesWithCorrectEntities {
//	NSSet *peopleNodes = [store.cacheNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"objectID.entity.name = 'People'"]];
//	NSSet *companyNodes = [store.cacheNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"objectID.entity.name = 'Companies'"]];
//	
//	assertThat(peopleNodes, hasCountOf(3));
//	assertThat(companyNodes, hasCountOf(2));
//}
//
//- (void)test_setsAttributesOnNodes {
//	NSSet *companyNodes = [store.cacheNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"objectID.entity.name = 'Companies'"]];
//	NSSet *names = [companyNodes valueForKey:@"name"];
//	
//	assertThat(names, hasItems(@"Acme Inc", @"Tesco", nil));
//}
//
//- (void)test_setsRelationshipsOnNodes {
//	NSSet *peopleNodes = [store.cacheNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"objectID.entity.name = 'People'"]];
//	NSArray *companyNames = [peopleNodes.allObjects valueForKey:@"company.name"];
//	
//	assertThat(companyNames, containsInAnyOrder(@"Tesco", @"Acme Inc", @"Acme Inc", nil));
//}
//
//- (void)test_returnsErrorIfLoadingFailed {
//	
//}
//
//
//
//
//
//
//#pragma mark -
//#pragma mark Saving
//
////Cannot be bothered implementing these yet as they're difficult
//- (void)test_savesCacheNodesToStore {
//	NSMutableDictionary *propertyCache = [@{@"name": @"bob"} mutableCopy];
//	
//	NSEntityDescription *peopleEntity = managedObjectModel.entitiesByName[@"People"];
//	NSManagedObjectID *objectID = [store objectIDForEntity:peopleEntity referenceObject:@"foobar"];
//	NSAtomicStoreCacheNode *cacheNode = [[NSAtomicStoreCacheNode alloc] initWithObjectID:objectID];
//	[cacheNode setPropertyCache:[NSMutableDictionary dictionary]];
//	
//	[store addCacheNodes:[NSSet setWithObject:cacheNode]];
//	
//	[store save:NULL];
//	
//	
////	NSURL *dataURL = [dataURL URLByAppendingPathComponent:@"People.json"];
//}
//
//- (void)test_savesObjectsInCorrectEntity {
//	
//}
//
//- (void)test_returnsErrorIfSavingFails {
//	
//}
//
//- (void)test_doesntSaveNodesWithNilPropertyCache {
//	
//}
//
//
//
//
//
//#pragma mark -
//#pragma mark Updating Cache Nodes
//
//- (void)test_returnsEntityNamePlusUUIDAsReferenceObjectForManagedObject {
//	NSEntityDescription *peopleEntity = managedObjectModel.entitiesByName[@"People"];
//	NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:peopleEntity insertIntoManagedObjectContext:nil];
//	
//	NSString *referenceObject = [store newReferenceObjectForManagedObject:object];
//	NSArray *components = [referenceObject componentsSeparatedByString:@"."];
//	NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:components[1]];
//	
//	assertThat(components[0], is(equalTo(@"People")));
//	assertThat(UUID, isNot(nilValue()));
//}
//
//- (void)test_cacheNodesAreUpdatedWithNewValuesFromManagedObject {
//	NSEntityDescription *peopleEntity = managedObjectModel.entitiesByName[@"People"];
////	NSManagedObjectID *objectID = [store objectIDForEntity:peopleEntity referenceObject:@"foobar"];
//	NSAtomicStoreCacheNode *cacheNode = [[NSAtomicStoreCacheNode alloc] initWithObjectID:nil];
//	
//	NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:peopleEntity insertIntoManagedObjectContext:nil];
//	[object setValue:@"bob" forKey:@"name"];
//	
//	[store updateCacheNode:cacheNode fromManagedObject:object];
//	
//	assertThat([cacheNode valueForKey:@"name"], is(equalTo(@"bob")));
//}
//
//- (void)test_willRemoveCacheNodesSetsPropertyCacheOfSuppliedNodesToNil {
//	NSEntityDescription *peopleEntity = managedObjectModel.entitiesByName[@"People"];
//	NSManagedObjectID *objectID = [store objectIDForEntity:peopleEntity referenceObject:@"foobar"];
//	NSAtomicStoreCacheNode *cacheNode = [[NSAtomicStoreCacheNode alloc] initWithObjectID:objectID];
//	[cacheNode setPropertyCache:[NSMutableDictionary dictionary]];
//	
//	[store willRemoveCacheNodes:[NSSet setWithObject:cacheNode]];
//	
//	assertThat(cacheNode.propertyCache, is(nilValue()));
//}

@end
