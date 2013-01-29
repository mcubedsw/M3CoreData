//
//  M3CoreDataManagerTests.m
//  M3CoreData
//
//  Created by Martin Pilkington on 10/10/2012.
//
//

#import "M3CoreDataManagerTests.h"
#import "M3CoreDataManager.h"

@implementation M3CoreDataManagerTests {
	NSURL *testModelURL;
	NSURL *updatedModelURL;
	NSURL *testStoreURL;
}

- (void)setUp {
	NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"com.mcubedsw.M3CoreData-Tests"];
	testModelURL = [testBundle URLForResource:@"TestModel" withExtension:@"mom"];
	testStoreURL = [testBundle URLForResource:@"TestStore" withExtension:@"storedata"];
}

- (void)test_storesSuppliedInitialiserArguments {
	NSString *initialType = @"type";
	NSURL *modelURL = [NSURL URLWithString:@"http://modelurl"];
	NSURL *dataStoreURL = [NSURL URLWithString:@"http://datastoreurl"];
	
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:initialType modelURL:modelURL dataStoreURL:dataStoreURL];
	
	assertThat(manager.dataStoreURL, is(equalTo(dataStoreURL)));
	assertThat(manager.modelURL, is(equalTo(modelURL)));
	assertThat(manager.storeType, is(equalTo(initialType)));
}

- (void)test_createsModelWithSuppliedURL {
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:nil modelURL:testModelURL dataStoreURL:nil];
	assertThat(manager.managedObjectModel, isNot(nilValue()));
	assertThat(manager.managedObjectModel.entitiesByName.allKeys, hasItems(@"People", @"Companies", nil));
}

- (void)test_createsPersistantStoreCoordinator {
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:NSXMLStoreType modelURL:testModelURL dataStoreURL:testStoreURL];
	assertThat(manager.persistentStoreCoordinator, isNot(nilValue()));
}

- (void)test_createsPersistentStoreWithSuppliedTypeURLAndOptions {
	NSDictionary *options = @{
		NSMigratePersistentStoresAutomaticallyOption : @NO
	};
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:NSXMLStoreType modelURL:testModelURL dataStoreURL:testStoreURL storeOptions:options];
	
	NSPersistentStoreCoordinator *coordinator = manager.persistentStoreCoordinator;
	NSPersistentStore *store = coordinator.persistentStores[0];
	
	assertThat(store, isNot(nilValue()));
	
	assertThat(store.URL, is(equalTo(testStoreURL)));
	assertThat(store.options, is(equalTo(options)));
	assertThat(store.type, is(equalTo(NSXMLStoreType)));
}

- (void)test_returnsErrorIfPersistentStoreCouldNotBeMade {
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:NSSQLiteStoreType modelURL:testModelURL dataStoreURL:testStoreURL];
	
	NSError *error = nil;
	assertThat([manager persistentStoreCoordinatorWithError:&error], is(nilValue()));
	assertThat(error, isNot(nilValue()));
}

- (void)test_returnsManagedObjectContextWithPersistentStoreCoordinator {
	M3CoreDataManager *manager = [[M3CoreDataManager alloc] initWithStoreType:NSXMLStoreType modelURL:testModelURL dataStoreURL:testStoreURL];

	assertThat(manager.managedObjectContext, isNot(nilValue()));
	assertThat(manager.managedObjectContext.persistentStoreCoordinator, is(equalTo(manager.persistentStoreCoordinator)));
}

@end
