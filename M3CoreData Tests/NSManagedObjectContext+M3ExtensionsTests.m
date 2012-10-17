/*****************************************************************
 NSManagedObjectContext+M3ExtensionsTests.m
 M3CoreData
 
 Created by Martin Pilkington on 10/10/2012.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import "NSManagedObjectContext+M3ExtensionsTests.h"
#import "M3CoreData.h"
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





#pragma mark -
#pragma mark Fetching

//*****//
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

//*****//
- (void)test_executesFetchOfObjectsInEntityWithPredicate {
	__weak id weakSelf = self;
	id entity = simpleEntity;
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"foobar = 5"];
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		id blockSelf = weakSelf;
		blockAssertThat(blockSelf, aRequest.sortDescriptors, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.predicate, is(equalTo(predicate)));
		blockAssertThat(blockSelf, aRequest.entity, is(equalTo(entity)));
		
		return @[];
	}];
	
	[managedObjectContext m3_objectsInEntityWithName:@"Simple" predicate:predicate sortedWithDescriptors:nil];
}

//*****//
- (void)test_executesFetchOfObjectsInEntityWithSortDescriptor {
	__weak id weakSelf = self;
	id entity = simpleEntity;
	
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"foobar" ascending:YES];
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		id blockSelf = weakSelf;
		blockAssertThat(blockSelf, aRequest.sortDescriptors, is(equalTo(@[ descriptor ])));
		blockAssertThat(blockSelf, aRequest.predicate, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.entity, is(equalTo(entity)));
		
		return @[];
	}];
	
	[managedObjectContext m3_objectsInEntityWithName:@"Simple" predicate:nil sortedWithDescriptors:@[ descriptor ]];
}

//*****//
- (void)test_returnsErrorIfNoEntityNamePassedIn {
	NSError *error = nil;
	id result = [managedObjectContext m3_objectsInEntityWithName:nil predicate:nil sortedWithDescriptors:nil extraRequestSetup:nil error:&error];
	assertThat(result, is(nilValue()));
	assertThat(error.domain, is(equalTo(M3CoreDataErrorDomain)));
	assertThatInteger(error.code, is(equalToInteger(M3EntityNotFoundError)));
}

//*****//
- (void)test_returnsErrorIfInvalidEntityNamePassedIn {
	NSError *error = nil;
	id result = [managedObjectContext m3_objectsInEntityWithName:@"Foobar" predicate:nil sortedWithDescriptors:nil extraRequestSetup:nil error:&error];
	assertThat(result, is(nilValue()));
	assertThat(error.domain, is(equalTo(M3CoreDataErrorDomain)));
	assertThatInteger(error.code, is(equalToInteger(M3EntityNotFoundError)));
}

//*****//
- (void)test_callsExtraSetupBlockIfPassedIn {
	__block BOOL calledExtraSetupBlock = NO;
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		return @[];
	}];
	
	[managedObjectContext m3_objectsInEntityWithName:@"Simple" predicate:nil sortedWithDescriptors:nil extraRequestSetup:^(NSFetchRequest *request) {
		calledExtraSetupBlock = YES;
	} error:NULL];
	assertThatBool(calledExtraSetupBlock, is(equalToBool(YES)));
}

//*****//
- (void)test_returnsAnyErrorFromExecutingAFetchRequest {
	NSError *expectedError = [NSError errorWithDomain:@"foobar" code:1 userInfo:nil];
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		*aError = expectedError;
		return (NSArray *)nil;
	}];
	
	NSError *error = nil;
	id result = [managedObjectContext m3_objectsInEntityWithName:@"Simple" predicate:nil sortedWithDescriptors:nil extraRequestSetup:nil error:&error];
	assertThat(result, is(nilValue()));
	assertThat(error, is(equalTo(expectedError)));
}




#pragma mark -
#pragma mark Creating objects

//*****//
- (void)test_returnsCountForTheSuppliedEntity {
	id blockSelf = self;
	id entity = simpleEntity;
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		blockAssertThat(blockSelf, aRequest.sortDescriptors, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.predicate, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.entity, is(equalTo(entity)));
		return @[@"", @""];
	}];
	
	NSUInteger result = [managedObjectContext m3_numberOfObjectsInEntityWithName:@"Simple" predicate:nil];
	assertThatInteger(result, is(equalToInteger(2)));
}

//*****//
- (void)test_callsTheFetchRequestWithThePredicate {
	id blockSelf = self;
	id entity = simpleEntity;
	NSPredicate *predicate = [NSPredicate new];
	[managedObjectContext setFetchRequestBlock:^(NSFetchRequest *aRequest, NSError **aError) {
		blockAssertThat(blockSelf, aRequest.sortDescriptors, is(nilValue()));
		blockAssertThat(blockSelf, aRequest.predicate, is(equalTo(predicate)));
		blockAssertThat(blockSelf, aRequest.entity, is(equalTo(entity)));
		return @[];
	}];
	
	[managedObjectContext m3_numberOfObjectsInEntityWithName:@"Simple" predicate:predicate];
}

//*****//
- (void)test_returnsNSNotFoundIfNameIsNotSet {
	NSUInteger result = [managedObjectContext m3_numberOfObjectsInEntityWithName:nil predicate:nil];
	assertThatInteger(result, is(equalToInteger(NSNotFound)));
}

//*****//
- (void)test_returnsNSNotFoundIfInvalidNameIsPassedIn {
	NSUInteger result = [managedObjectContext m3_numberOfObjectsInEntityWithName:@"foobar" predicate:nil];
	assertThatInteger(result, is(equalToInteger(NSNotFound)));
}

@end
