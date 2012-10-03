/*****************************************************************
 M3JSONAtomicStore.m
 M3CoreData
 
 Created by Martin Pilkington on 25/02/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3JSONAtomicStore.h"
#import "M3JSONStore.h"
#import "_CJSONSerializer.h"
#import "_CJSONDeserializer.h"



NSString *M3AttributesKey = @"attributes";
NSString *M3RelationshipsKey = @"relationships";
NSString *M3ObjectIdKey = @"objectID";

@interface M3JSONAtomicStore ()

- (NSDictionary *)p_cacheNodeAttributesFromJSONAttributes:(NSDictionary *)aJSONAttributes inEntity:(NSEntityDescription *)aEntity;
- (NSDictionary *)p_objectIDRelationshipsFromJSONRelationships:(NSDictionary *)aJSONRelationships inEntity:(NSEntityDescription *)aEntity;
- (NSArray *)p_nodeDataForEntities:(NSArray *)aEntities atURL:(NSURL *)aBaseURL error:(NSError **)aError;
- (NSMutableDictionary *)p_propertyDataFromNodeData:(NSDictionary *)aData usingNodeMap:(NSDictionary *)aNodeMap;
- (NSArray *)p_objectsInEntity:(NSEntityDescription *)aEntity withDictionary:(NSDictionary *)aEntityDictionary lastIndex:(NSInteger *)aIndex;

@end



@implementation M3JSONAtomicStore {
	M3JSONStore *jsonStore;
	NSMutableDictionary *entityLastIndexes;
}

/***************************
 Set up the store
 **************************/
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)aCoordinator configurationName:(NSString *)aConfigurationName URL:(NSURL*)aURL options:(NSDictionary *)aOptions {
	BOOL isDirectory;
	BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath:aURL.path isDirectory:&isDirectory];
	BOOL isBundle = !isDirectory && storeExists;
	if (!aURL.isFileURL || isBundle) {
		return nil;
	}
		
	if ((self = [super initWithPersistentStoreCoordinator:aCoordinator configurationName:aConfigurationName URL:aURL options:aOptions])) {
		//Create the store if it doesn't exist
		if (!storeExists) {
			if (![[NSFileManager defaultManager] createDirectoryAtPath:aURL.path withIntermediateDirectories:YES attributes:nil error:NULL]) {
				return nil;
			}
		}
		entityLastIndexes = [NSMutableDictionary new];
		jsonStore = [[M3JSONStore alloc] initWithModel:aCoordinator.managedObjectModel];
		[self setMetadata:@{ NSStoreTypeKey:self.type }];
	}
	return self;
}


/***************************
 Return the type string
 **************************/
- (NSString *)type {
	return M3JSONStoreType;
}





#pragma mark -
#pragma mark Metadata

/***************************
 Get the metadata from the file
 **************************/
+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL *)aURL error:(NSError **)aError {
	NSData *data = [NSData dataWithContentsOfURL:[aURL URLByAppendingPathComponent:@"_Metadata.json"]];
	NSMutableDictionary *metadata = [[[_CJSONDeserializer deserializer] deserializeAsDictionary:data error:aError] mutableCopy];
	metadata[NSStoreModelVersionIdentifiersKey] = @[ @"1" ];
	return metadata;
}

/***************************
 Set the metadata on the file
 **************************/
+ (BOOL)setMetadata:(NSDictionary *)aMetadata forPersistentStoreWithURL:(NSURL*)aURL error:(NSError **)aError {
	NSString *json = [[_CJSONSerializer serializer] serializeDictionary:aMetadata];
	return [json writeToURL:[aURL URLByAppendingPathComponent:@"_Metadata.json"] atomically:YES encoding:NSUTF8StringEncoding error:aError];
}





#pragma mark -
#pragma mark Converting from JSON

//*****//
- (NSDictionary *)p_cacheNodeAttributesFromJSONAttributes:(NSDictionary *)aJSONAttributes inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *cacheNodeAttributes = [NSMutableDictionary dictionary];
	
	[aEntity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeDescription, BOOL *stop) {
		//Look for a value for our attribute
		id attribute = aJSONAttributes[attributeName];
		if (!attribute) return;
		
		//Handle dates
		if (attributeDescription.attributeType == NSDateAttributeType) {
			attribute = [NSDate dateWithString:attribute];
		}
		
		cacheNodeAttributes[attributeName] = attribute;
	}];
	
	return cacheNodeAttributes;
}


//*****//
- (NSDictionary *)p_objectIDRelationshipsFromJSONRelationships:(NSDictionary *)aJSONRelationships inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *objectIDRelationships = [NSMutableDictionary dictionary];
	
	[aEntity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
		//Look for values for our relationship
		id relationship = aJSONRelationships[relationshipName];
		if (!relationship) return;
		
		//If it's to many then loop through and get all the ids for the relationship
		if (relationshipDescription.isToMany) {
			NSMutableSet *relationshipIDs = [NSMutableSet set];
			for (NSString *JSONRelationship in relationship) {
				[relationshipIDs addObject:[self objectIDForEntity:relationshipDescription.destinationEntity referenceObject:JSONRelationship]];
			}
			objectIDRelationships[relationshipName] = relationshipIDs;
		//Else get the single id
		} else {
			NSManagedObjectID *objectID = [self objectIDForEntity:relationshipDescription.destinationEntity referenceObject:relationship];
			objectIDRelationships[relationshipName] = objectID;
		}
	}];
	
	return objectIDRelationships;
}


//*****//
- (NSArray *)p_nodeDataForEntities:(NSArray *)aEntities atURL:(NSURL *)aBaseURL error:(NSError **)aError {
	NSMutableArray *returnArray = [NSMutableArray array];
	
	for (NSEntityDescription *entity in aEntities) {
		//Parse our entity JSON to a dictionary
		NSString *entityFileName = [NSString stringWithFormat:@"%@.json", entity.name];
		NSData *data = [NSData dataWithContentsOfURL:[self.URL URLByAppendingPathComponent:entityFileName]];

		NSDictionary *entityDictionary = [[_CJSONDeserializer deserializer] deserializeAsDictionary:data error:aError];
		if (!entityDictionary) {
			return nil;
		}

		NSInteger lastIndex = 0;
		[returnArray addObjectsFromArray:[self p_objectsInEntity:entity withDictionary:entityDictionary lastIndex:&lastIndex]];
		entityLastIndexes[entity.name] = [NSNumber numberWithInteger:lastIndex];
	}
	
	return [returnArray copy];
}


//*****//
- (NSArray *)p_objectsInEntity:(NSEntityDescription *)aEntity withDictionary:(NSDictionary *)aEntityDictionary lastIndex:(NSInteger *)aIndex {
	NSMutableArray *returnArray = [NSMutableArray array];
	//Loop our objects, loading the attributes, relationships and id
	NSInteger lastIndex = 0;
	for (NSString *objectID in aEntityDictionary) {
		NSDictionary *objectValues = [aEntityDictionary objectForKey:objectID];
		
		NSDictionary *attributes = [self p_cacheNodeAttributesFromJSONAttributes:objectValues inEntity:aEntity];
		NSDictionary *relationships = [self p_objectIDRelationshipsFromJSONRelationships:objectValues inEntity:aEntity];
		
		NSString *referenceId = [NSString stringWithFormat:@"%@.%@", aEntity.name, objectID];
		NSManagedObjectID *managedObjectID = [self objectIDForEntity:aEntity referenceObject:referenceId];
		
		[returnArray addObject:@{ M3AttributesKey:attributes, M3RelationshipsKey:relationships, M3ObjectIdKey:managedObjectID }];
		
		//Update the last index
		if (objectID.integerValue > lastIndex) {
			lastIndex = objectID.integerValue;
		}
	}
	*aIndex = lastIndex;
	return [returnArray copy];
}


//*****//
- (NSMutableDictionary *)p_propertyDataFromNodeData:(NSDictionary *)aData usingNodeMap:(NSDictionary *)aNodeMap {
	NSMutableDictionary *propertyData = [NSMutableDictionary dictionaryWithDictionary:aData[M3AttributesKey]];
	
	//Handle relationships
	[aData[M3RelationshipsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, id relationship, BOOL *stop) {
		//To many relationship
		if ([relationship isKindOfClass:[NSSet class]]) {
			NSMutableSet *relationshipSet = [NSMutableSet set];
			
			for (NSManagedObjectID *relationshipID in relationship) {
				[relationshipSet addObject:aNodeMap[relationshipID]];
			}
			
			propertyData[relationshipName] = relationshipSet;
		//To one relationship
		} else {
			propertyData[relationshipName] = aNodeMap[relationship];
		}
	}];
	
	return propertyData;
}





#pragma mark -
#pragma mark NSAtomicStore methods

//*****//
- (BOOL)load:(NSError **)aError {
	//If we can't get our metadata then fail
	NSDictionary *metadataDict = [self.class metadataForPersistentStoreWithURL:self.URL error:aError];
	if (!metadataDict) {
		return NO;
	}
	
	[self setMetadata:metadataDict];
	
	NSDictionary *objectData = [jsonStore loadFromURL:self.URL];
	
	NSMutableDictionary *nodemap = [NSMutableDictionary dictionary];
	for (NSString *jsonId in objectData) {
		//Ignore any non-numeric objects, our stores are 1 indexed
		if (jsonId.integerValue == 0) continue;

		[jsonStore objectFromDictionary:objectData withId:jsonId usingMap:nodemap creationBlock:^(NSEntityDescription *entity, NSString *jsonId) {
			NSManagedObjectID *objectId = [self objectIDForEntity:entity referenceObject:jsonId];
			return [[NSAtomicStoreCacheNode alloc] initWithObjectID:objectId];									  
		}];
		
		//Look for highest index
		NSString *entityName = [jsonId componentsSeparatedByString:@"."][0];
		NSInteger entityId = [[jsonId componentsSeparatedByString:@"."][1] integerValue];
		NSNumber *lastIndex = entityLastIndexes[entityName] ?: @1;
		if (lastIndex.integerValue < entityId) {
			entityLastIndexes[entityName] = [NSNumber numberWithInteger:entityId];
		}
	}
	
	[self addCacheNodes:[NSSet setWithArray:nodemap.allValues]];
	
	return YES;
}


//*****//
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)aManagedObject {
	NSAtomicStoreCacheNode *node = [[NSAtomicStoreCacheNode alloc] initWithObjectID:aManagedObject.objectID];
	[self updateCacheNode:node fromManagedObject:aManagedObject];
	return node;
}


//*****//
- (id)newReferenceObjectForManagedObject:(NSManagedObject *)aManagedObject {
	NSString *entityName = aManagedObject.entity.name;
	
	//Increment the last index for the entity
	NSInteger lastIndex = [entityLastIndexes[entityName] integerValue];
	lastIndex++;
	entityLastIndexes[entityName] = [NSNumber numberWithInteger:lastIndex];
	
	return [NSString stringWithFormat:@"%@.%ld", entityName, lastIndex];
}


//*****//
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)aNode fromManagedObject:(NSManagedObject *)aManagedObject {
	NSMutableDictionary *propertyCacheDict = [NSMutableDictionary dictionary];
	
	for (NSPropertyDescription *description in aManagedObject.entity) {
		id value = [aManagedObject valueForKey:description.name];
		if (value) {
			propertyCacheDict[description.name] = value;
		}
	}
	
	[aNode setPropertyCache:propertyCacheDict];
}





#pragma mark -
#pragma mark Save

//*****//
- (BOOL)save:(NSError **)aError {
	//If we can't update the metadata, fail
	if (![self.class setMetadata:self.metadata forPersistentStoreWithURL:self.URL error:aError]) {
		return NO;
	}
	
	NSMutableDictionary *nodes = [NSMutableDictionary dictionary];
	for (NSAtomicStoreCacheNode *node in self.cacheNodes) {
		nodes[[self referenceObjectForObjectID:node.objectID]] = node;
	}
	
	return [jsonStore saveObjects:nodes toURL:self.URL error:aError];
}


//*****//
- (void)willRemoveCacheNodes:(NSSet *)aCacheNodes {
	[aCacheNodes makeObjectsPerformSelector:@selector(setPropertyCache:) withObject:nil];
}

@end
