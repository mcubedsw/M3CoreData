/*****************************************************************
 NSManagedObjectContext+M3ExtensionsTests.m
 M3CoreData
 
 Created by Martin Pilkington on 10/10/2012.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import "NSManagedObjectContext+M3ExtensionsTests.h"
#import "NSManagedObjectContext+M3Extensions.h"
#import "M3TestManagedObjectContext.h"

@implementation NSManagedObjectContext_M3ExtensionsTests {
	M3TestManagedObjectContext *managedObjectContext;
	
	NSEntityDescription *simpleEntity;
	NSEntityDescription *complexEntity;
	NSManagedObjectModel *mom;
}

- (void)setUp {
	[super setUp];
	mom = [NSManagedObjectModel new];
	
	simpleEntity = [NSEntityDescription new];
	[simpleEntity setName:@"Simple"];
	
	complexEntity = [NSEntityDescription new];
	[complexEntity setName:@"Complex"];
	[complexEntity setManagedObjectClassName:@"M3CustomManagedObject"];
	
	[mom setEntities:@[ simpleEntity, complexEntity ]];
	
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	
	managedObjectContext = [M3TestManagedObjectContext new];
	[managedObjectContext setPersistentStoreCoordinator:coordinator];
}


- (void)test_executesFetchOfAllObjectsInEntityCorrectly {
	__weak id weakSelf = self;
	id entity = simpleEntity;
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		id blockSelf = weakSelf;
		blockAssertThat(blockSelf, aRequest.sortDescriptors, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.predicate, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.entity, is(equalTo(entity)));
		
		return @[];
	}];
	
	NSArray *result = [managedObjectContext m3_objectsInEntityWithName:@"Simple" predicate:nil sortedWithDescriptors:nil];
	assertThat(result, is(equalTo(@[])));
}

@end
