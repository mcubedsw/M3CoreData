/*****************************************************************
 M3JSONAtomicStoreTests.m
 M3CoreData
 
 Created by Martin Pilkington on 27/04/2011.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import "M3JSONAtomicStoreTests.h"
#import "M3JSONAtomicStore.h"

@implementation M3JSONAtomicStoreTests {
	M3JSONAtomicStore *store;
	NSURL *dataURL;
}

- (void)setUp {
	NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"com.mcubedsw.M3CoreData-Tests"];
	
	dataURL = [testBundle URLForResource:@"JSONStore" withExtension:@"jsondata"];
	NSURL *testModelURL = [testBundle URLForResource:@"TestModel" withExtension:@"mom"];
	
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:testModelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	
	store = [[M3JSONAtomicStore alloc] initWithPersistentStoreCoordinator:coordinator configurationName:nil URL:dataURL options:nil];
}


#pragma mark -
#pragma mark Metadata

- (void)test_loadsAndSetsMetadataWhenInitialised {
	
}

- (void)test_returnsMetadataForStore {
	
}

- (void)test_returnsStoreUUIDInMetadataForStore {
	
}

- (void)test_returnsStoreTypeInMetadataForStore {
	
}

- (void)test_returnsMetadataForStoreAtGivenURL {
	
}

- (void)test_setsMetadataForStoreAtGivenURL {
	
}




#pragma mark -
#pragma mark Miscellaneous

- (void)test_returnsStoreIdentifier {
	
}

- (void)test_setsStoreIdentifier {
	
}

- (void)test_returnsJSONStoreAsType {
	
}





#pragma mark -
#pragma mark Loading

- (void)test_loadsDataAtURLIntoCachNodes {
	
}

- (void)test_returnsErrorIfLoadingFailed {
	
}






#pragma mark -
#pragma mark Saving

- (void)test_savesCacheNodesToStore {
	
}

- (void)test_savesObjectsInCorrectEntity {
	
}

- (void)test_returnsErrorIfSavingFails {
	
}

- (void)test_doesntSaveNodesWithNilPropertyCache {
	
}





#pragma mark -
#pragma mark Updating Cache Nodes

- (void)test_returnsEntityNamePlusUUIDAsReferenceObjectForManagedObject {
	
}

- (void)test_cacheNodesAreUpdatedWithNewValuesFromManagedObject {
	
}

- (void)test_willRemoveCacheNodesSetsPropertyCacheOfSuppliedNodesToNil {
	
}

@end
