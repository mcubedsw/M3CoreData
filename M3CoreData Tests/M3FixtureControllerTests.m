/*****************************************************************
 M3FixtureControllerTests.m
 M3CoreData
 
 Created by Martin Pilkington on 10/10/2012.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import "M3FixtureControllerTests.h"
#import "M3FixtureController.h"

@implementation M3FixtureControllerTests {
	NSManagedObjectModel *managedObjectModel;
	NSURL *dataURL;
	M3FixtureController *controller;
}

- (void)setUp {
	[super setUp];
	
	NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"com.mcubedsw.M3CoreData-Tests"];
	NSURL *testModelURL = [testBundle URLForResource:@"TestModel" withExtension:@"mom"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:testModelURL];
	dataURL = [testBundle URLForResource:@"JSONStore" withExtension:@"jsondata"];
	
	controller = [[M3FixtureController alloc] initWithModel:managedObjectModel dataURL:dataURL];
}

- (void)test_storesTheObjectsPassedInToTheInitialiser {
	assertThat(controller.managedObjectModel, is(equalTo(managedObjectModel)));
	assertThat(controller.dataURL, is(equalTo(dataURL)));
}

- (void)test_returnsAllObjectsForSuppliedEntity {
	NSArray *objects = [controller objectsForEntityWithName:@"Companies"];
	
	assertThat(objects, hasCountOf(2));
	assertThat([objects valueForKey:@"name"], hasItems(@"Acme Inc", @"Tesco", nil));
}

- (void)test_returnsCorrectObjectForSuppliedID {
	id object = [controller objectWithID:@"jane" inEntityWithName:@"People"];
	assertThat([object valueForKey:@"name"], is(equalTo(@"Jane Doe")));
}

- (void)test_returnedObjectsAreNSManagedObjects {
	id object = [controller objectWithID:@"john" inEntityWithName:@"People"];
	assertThatBool([object isKindOfClass:[NSManagedObject class]], is(equalToBool(YES)));
}

- (void)test_clearingTheCacheRecreatesAllObjects {
	id object = [controller objectWithID:@"joe" inEntityWithName:@"People"];
	[controller clearObjectCache];
	id freshObject = [controller objectWithID:@"joe" inEntityWithName:@"People"];
	
	assertThat(object, isNot(sameInstance(freshObject)));
}

@end
