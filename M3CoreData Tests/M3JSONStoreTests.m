/*****************************************************************
 M3JSONStoreTests.m
 M3CoreData
 
 Created by Martin Pilkington on 28/05/2012.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3JSONStoreTests.h"

#import "M3JSONStore.h"
#import "M3StoreObjectFactory.h"


@implementation M3JSONStoreTests {
	NSManagedObjectModel *managedObjectModel;
	NSURL *dataURL;
	id mockFactory;
	
	M3JSONStore *store;
}

- (void)setUp {
	[super setUp];
	NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"com.mcubedsw.M3CoreData-Tests"];
	
	NSURL *testModelURL = [testBundle URLForResource:@"JSONModel" withExtension:@"momd"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:testModelURL];
	
	mockFactory = [OCMockObject niceMockForProtocol:@protocol(M3StoreObjectFactory)];
	
	dataURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"TemporaryStore.jsonStore"]];
	[self clearTestStore];
	[[NSFileManager new] createDirectoryAtURL:dataURL withIntermediateDirectories:YES attributes:nil error:nil];
	
	store = [[M3JSONStore alloc] initWithManagedObjectModel:managedObjectModel dataURL:dataURL objectFactory:mockFactory];
}

- (void)test_storesAndReturnsValuesSuppliedInInitMethod {
	
	assertThat(store.managedObjectModel, is(equalTo(managedObjectModel)));
	assertThat(store.dataURL, is(equalTo(dataURL)));
	assertThat(store.objectFactory, is(equalTo(mockFactory)));
}





#pragma mark -
#pragma mark Loading

- (void)test_loadsAllEntitiesFromStore {
	[self writeObjectsToTestStore:@{@"Entity1" : @{}, @"Entity2" : @{}}];
	
	NSDictionary *entities = [store loadObjects:nil];
	
	assertThat(entities.allKeys, hasItems(@"Entity1", @"Entity2", nil));
}

- (void)test_loadsAllObjectsFromStore {
	[self setupBasicMockFactory];
	
	[self writeObjectsToTestStore:@{
		@"Entity1": @{@"1": @{}, @"2": @{}, @"3": @{}},
		@"Entity2": @{@"1": @{}}
	}];
	
	NSDictionary *entities = [store loadObjects:nil];
	
	assertThat(entities[@"Entity1"], hasCountOf(3));
	assertThat(entities[@"Entity2"], hasCountOf(1));
}

- (void)test_loadsIfStoreDoesNotExistAtURL {
	NSDictionary *expectedDictionary = @{@"Entity1": @{}, @"Entity2": @{}};
	assertThat([store loadObjects:nil], is(equalTo(expectedDictionary)));
}

- (void)test_failsAndReturnsErrorIfLoadingURLIsNotADirectory {
	[self clearTestStore];
	[@"" writeToURL:dataURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
	
	NSError *error = nil;
	assertThat([store loadObjects:&error], is(nilValue()));
	assertThat(error, isNot(nilValue()));
}

- (void)test_failsAndReturnsErrorIfJSONIsCorrupt {
	[@"{" writeToURL:[dataURL URLByAppendingPathComponent:@"Entity1.json"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	
	NSError *error = nil;
	assertThat([store loadObjects:&error], is(nilValue()));
	assertThat(error, isNot(nilValue()));
}

- (void)test_createsObjectsUsingObjectFactory {
	[self writeObjectsToTestStore:@{
		@"Entity1":@{@"1":@{}}
	}];
	
	NSEntityDescription *entity = managedObjectModel.entitiesByName[@"Entity1"];
	
	[[[mockFactory expect] andReturn:[NSMutableDictionary dictionary]] createObjectWithEntity:entity JSONID:@"1"];
	
	[store loadObjects:NULL];
	
	[mockFactory verify];
}

- (void)test_loadsDataIntoObjects {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1":@{
	 		@"1":@{
				@"string":@"foobar"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSDate *actualString = objects[@"Entity1"][@"1"][@"string"];
	
	assertThat(actualString, is(equalTo(@"foobar")));
}

- (void)test_transformsJSONDateToNSDate {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1":@{
	 		@"1":@{
				@"date":@"2013-04-01 01:02:03 +0000"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSDate *expectedDate = [NSDate dateWithString:@"2013-04-01 01:02:03 +0000"];
	NSDate *actualDate = objects[@"Entity1"][@"1"][@"date"];
	
	assertThat(actualDate, is(equalTo(expectedDate)));
}

- (void)test_runsValueTransformerIfOneExists {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1" : @{
	 		@"1" : @{
	 			@"transformed" : @"string"
	 		}
	 	}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSString *actualValue = objects[@"Entity1"][@"1"][@"transformed"];
	
	assertThat(actualValue, is(equalTo(@"stringabc123")));
}

- (void)test_transformsJSONColourToNSColor {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1": @{
	 		@"1": @{
				@"color": @"@rgba(128, 128, 128, 0.5)"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSColor *expectedColor = [NSColor colorWithCalibratedRed:(128.0/255) green:(128.0/255) blue:(128.0/255) alpha:0.5];
	NSColor *actualColor = objects[@"Entity1"][@"1"][@"color"];
	
	assertThat(actualColor, is(equalTo(expectedColor)));
}

- (void)test_transformsJSONURLToNSURL {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1": @{
	 		@"1": @{
	 			@"url": @"http://www.apple.com"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSURL *expectedURL = [NSURL URLWithString:@"http://www.apple.com"];
	NSURL *actualURL = objects[@"Entity1"][@"1"][@"url"];
	
	assertThat(actualURL, is(equalTo(expectedURL)));
}

- (void)test_createsOneToOneRelationshipObject {
	[self setupBasicMockFactory];
	[self writeObjectsToTestStore:@{
		@"Entity1": @{
	 		@"1": @{
	 			@"oneToOne": @"Entity2.42"
			}
		},
		@"Entity2": @{
	 		@"42": @{
	 			@"inverseOneToOne": @"Entity1.1"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSDictionary *entity1Object = objects[@"Entity1"][@"1"];
	NSDictionary *entity2Object = objects[@"Entity2"][@"42"];
	
	assertThat(entity1Object[@"oneToOne"], is(sameInstance(entity2Object)));
	assertThat(entity2Object[@"inverseOneToOne"], is(sameInstance(entity1Object)));
}

- (void)test_createsOneToManyRelationshipObjects {
	NSDictionary *entities = managedObjectModel.entitiesByName;
	[[[mockFactory stub] andReturn:[NSMutableDictionary dictionary]] createObjectWithEntity:entities[@"Entity1"] JSONID:@"1"];
	[[[mockFactory stub] andReturn:[NSMutableDictionary dictionary]] createObjectWithEntity:entities[@"Entity2"] JSONID:@"42"];
	[[[mockFactory stub] andReturn:[NSMutableDictionary dictionary]] createObjectWithEntity:entities[@"Entity2"] JSONID:@"1"];
	
	[self writeObjectsToTestStore:@{
		@"Entity1":@{
	 		@"1":@{
	 			@"oneToMany":@[@"Entity2.42", @"Entity2.1"]
			}
		},
		@"Entity2":@{
	 		@"42":@{
	 			@"inverseOneToMany":@"Entity1.1"
			},
	 		@"1":@{
	 			@"inverseOneToMany":@"Entity1.1"
			}
		}
	}];
	
	NSDictionary *objects = [store loadObjects:NULL];
	
	NSDictionary *entity1Object = objects[@"Entity1"][@"1"];
	NSDictionary *entity2Object42 = objects[@"Entity2"][@"42"];
	NSDictionary *entity2Object1 = objects[@"Entity2"][@"1"];
	
	assertThat(entity1Object[@"oneToMany"], hasItems(entity2Object1, entity2Object42, nil));
	assertThat(entity2Object42[@"inverseOneToMany"], is(sameInstance(entity1Object)));
	assertThat(entity2Object1[@"inverseOneToMany"], is(sameInstance(entity1Object)));
}





#pragma mark -
#pragma mark Saving

- (void)test_savesAllEntitiesToStore {
	NSDictionary *expectedDictionary = @{@"Entity1" : @{}, @"Entity2" : @{}};
	assertThatBool([store saveObjects:expectedDictionary error:NULL], is(equalToBool(YES)));
	
	NSDictionary *actualDictionary = self.JSONTestStoreObjects;
	
	assertThat(actualDictionary, is(equalTo(expectedDictionary)));
}

- (void)test_savesAllObjectsToStore {
	NSDictionary *expectedDictionary = @{@"Entity1" : @{@"1":@{}}, @"Entity2" : @{@"42":@{}, @"1":@{}}};
	assertThatBool([store saveObjects:expectedDictionary error:NULL], is(equalToBool(YES)));
	
	NSDictionary *actualDictionary = self.JSONTestStoreObjects;
	
	assertThat(actualDictionary, is(equalTo(expectedDictionary)));
}

- (void)test_createsDirectoryIfOneDoesntExist {
	[self clearTestStore];
	
	assertThatBool([store saveObjects:nil error:NULL], is(equalToBool(YES)));
	
	NSFileManager *fileManager = [NSFileManager new];
	BOOL isDirectory = NO;
	
	assertThatBool([fileManager fileExistsAtPath:dataURL.path isDirectory:&isDirectory], is(equalToBool(YES)));
	assertThatBool(isDirectory, is(equalToBool(YES)));
}

- (void)test_failsAndReturnsErrorIfSavingURLExistsAndIsNotADirectory {
	[self clearTestStore];
	[@"" writeToURL:dataURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	
	NSError *error = nil;
	assertThatBool([store saveObjects:@{@"Entity1" : @{}} error:&error], is(equalToBool(NO)));
	assertThat(error, isNot(nilValue()));
}

- (void)test_writesDataFromObjects {
	NSDictionary *inputDictionary = @{
		@"Entity1": @{
	 		@"1": @{
				@"string": @"foobar"
			}
		}
	};
	
	[store saveObjects:inputDictionary error:NULL];
	
	NSString *string = self.JSONTestStoreObjects[@"Entity1"][@"1"][@"string"];
	
	assertThat(string, is(equalTo(@"foobar")));
}

- (void)test_transformsNSDateToJSONDate {
	NSDictionary *inputDictionary = @{
		@"Entity1": @{
	 		@"1": @{
				@"date": [NSDate dateWithString:@"2013-04-01 01:02:03 +0000"]
			}
		}
	};
	
	[store saveObjects:inputDictionary error:NULL];
	
	NSString *dateString = self.JSONTestStoreObjects[@"Entity1"][@"1"][@"date"];
	
	assertThat(dateString, is(equalTo(@"2013-04-01 01:02:03 +0000")));
}

- (void)test_runsReverseValueTransformerIfOneExists {
	NSDictionary *inputDictionary = @{
		@"Entity1": @{
	 		@"1": @{
				@"transformed": @"stringabc123"
			}
		}
	};
	
	[store saveObjects:inputDictionary error:NULL];
	
	NSString *string = self.JSONTestStoreObjects[@"Entity1"][@"1"][@"transformed"];
	
	assertThat(string, is(equalTo(@"string")));
}

- (void)test_transformsNSColorToJSONColor {
	NSDictionary *inputDictionary = @{
		@"Entity1": @{
	 		@"1": @{
				@"color": [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.5]
			}
		}
	};
	
	[store saveObjects:inputDictionary error:NULL];
	
	NSString *string = self.JSONTestStoreObjects[@"Entity1"][@"1"][@"color"];
	
	assertThat(string, is(equalTo(@"@rgba(127,127,127,0.50)")));
}

- (void)test_transformsNSURLToJSONURL {
	NSDictionary *inputDictionary = @{
		@"Entity1": @{
	 		@"1": @{
				@"url": [NSURL URLWithString:@"http://www.apple.com"]
			}
		}
	};
	
	[store saveObjects:inputDictionary error:NULL];
	
	NSString *string = self.JSONTestStoreObjects[@"Entity1"][@"1"][@"url"];
	
	assertThat(string, is(equalTo(@"http://www.apple.com")));
}

- (void)test_transformsOneToOneRelationshipsToIDs {
	return;
	NSMutableDictionary *entity1Object = [NSMutableDictionary dictionary];
	NSMutableDictionary *entity2Object = [NSMutableDictionary dictionary];
	
	entity1Object[@"oneToOne"] = entity2Object;
	entity2Object[@"inverseOneToOne"] = entity1Object;
	
	[store saveObjects:@{
		@"Entity1": @{
			@"1": entity1Object
		},
		@"Entity2": @{
			@"42": entity2Object
		}
	} error:NULL];
	
	NSDictionary *testObjects = self.JSONTestStoreObjects;
	NSString *entity1Relationship = testObjects[@"Entity1"][@"1"][@"oneToOne"];
	NSString *entity2Relationship = testObjects[@"Entity2"][@"42"][@"inverseOneToOne"];
	
	assertThat(entity1Relationship, is(equalTo(@"Entity2.42")));
	assertThat(entity2Relationship, is(equalTo(@"Entity1.1")));
}

- (void)test_transformsOneToManyRelationshipsToArraysOfIDs {
	return;
	NSMutableDictionary *entity1Object = [NSMutableDictionary dictionary];
	NSMutableDictionary *entity2Object42 = [NSMutableDictionary dictionary];
	NSMutableDictionary *entity2Object1 = [NSMutableDictionary dictionary];
	
	entity1Object[@"oneToMany"] = @[entity2Object42, entity2Object1];
	entity2Object42[@"inverseOneToMany"] = entity1Object;
	entity2Object1[@"inverseOneToMany"] = entity1Object;
	
	[store saveObjects:@{
		@"Entity1": @{
			@"1": entity1Object
		},
		@"Entity2": @{
			@"42": entity2Object42,
	 		@"1": entity2Object1
		}
	} error:NULL];
	
	NSDictionary *testObjects = self.JSONTestStoreObjects;
	NSArray *entity1Relationship = testObjects[@"Entity1"][@"1"][@"oneToMany"];
	NSString *entity2Relationship42 = testObjects[@"Entity2"][@"42"][@"inverseOneToMany"];
	NSString *entity2Relationship1 = testObjects[@"Entity2"][@"1"][@"inverseOneToMany"];
	
	assertThat(entity1Relationship, hasItems(@"Entity2.1", @"Entity2.42", nil));
	assertThat(entity2Relationship42, is(equalTo(@"Entity1.1")));
	assertThat(entity2Relationship1, is(equalTo(@"Entity1.1")));
}





#pragma mark -
#pragma mark Helpers

- (void)setupBasicMockFactory {
	[[[mockFactory stub] andReturn:[NSMutableDictionary dictionary]] createObjectWithEntity:[OCMArg any] JSONID:[OCMArg any]];
}

- (void)clearTestStore {
	NSFileManager *fileManager = [NSFileManager new];
	[fileManager removeItemAtURL:dataURL error:NULL];
}

- (void)writeObjectsToTestStore:(NSDictionary *)aObjects {
	[aObjects enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
		NSError *error = nil;
		NSData *JSONData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
		if (!JSONData) {
			NSLog(@"Error:%@", error);
			return;
		}
		
		NSString *entityFileName = [key stringByAppendingPathExtension:@"json"];
		if (![JSONData writeToURL:[dataURL URLByAppendingPathComponent:entityFileName] options:NSDataWritingAtomic error:&error]) {
			NSLog(@"Error:%@", error);
			return;
		}
	}];
}

- (NSDictionary *)JSONTestStoreObjects {
	NSFileManager *fileManager = [NSFileManager new];
	NSError *error = nil;
	
	NSMutableDictionary *storeObjects = [NSMutableDictionary dictionary];
	
	//Load entity
	NSArray *entityFiles = [fileManager contentsOfDirectoryAtURL:dataURL includingPropertiesForKeys:nil options:0 error:&error];
	if (!entityFiles) {
		NSLog(@"Error:%@", error);
		return nil;
	}
	
	//Enumerate through entities and load
	for (NSURL *fileURL in entityFiles) {
		NSString *filename = fileURL.lastPathComponent.stringByDeletingPathExtension;
		
		NSData *entityData = [NSData dataWithContentsOfURL:fileURL];
		NSDictionary *entityJSON = [NSJSONSerialization JSONObjectWithData:entityData options:0 error:&error];
		if (!entityJSON) {
			NSLog(@"Error:%@", error);
			return nil;
		}
		storeObjects[filename] = entityJSON;
	}
	return [storeObjects copy];
}

@end
