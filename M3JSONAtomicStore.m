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

NSString *M3JSONStoreType = @"M3JSONStoreType";

NSString *M3AttributesKey = @"attributes";
NSString *M3RelationshipsKey = @"relationships";
NSString *M3ObjectIdKey = @"objectID";


@implementation M3JSONAtomicStore {
	M3JSONStore *jsonStore;
}

/***************************
 Set up the store
 **************************/
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)aCoordinator configurationName:(NSString *)aConfigurationName URL:(NSURL*)aURL options:(NSDictionary *)aOptions {
	BOOL isDirectory;
	BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
	if (![url isFileURL] || (!isDirectory && storeExists)) {
		return nil;
	}
		
	if ((self = [super initWithPersistentStoreCoordinator:aCoordinator configurationName:aConfigurationName URL:url options:options])) {
		if (!storeExists) {
			if (![[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:NULL]) {
				return nil;
			}
		}
		entityLastIndexes = [[NSMutableDictionary alloc] init];
		jsonStore = [[M3JSONStore alloc] initWithModel:[aCoordinator managedObjectModel]];
		[self setMetadata:[NSDictionary dictionaryWithObjectsAndKeys:[self type], NSStoreTypeKey, nil]];
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
	[metadata setObject:[NSArray arrayWithObject:@"1"] forKey:NSStoreModelVersionIdentifiersKey];
	return metadata;
}

/***************************
 Set the metadata on the file
 **************************/
+ (BOOL)setMetadata:(NSDictionary *)aMetadata forPersistentStoreWithURL:(NSURL*)aURL error:(NSError **)aError {
	NSString *json = [[_CJSONSerializer serializer] serializeDictionary:aMetadata];
	return [json writeToURL:[aURL URLByAppendingPathComponent:@"_Metadata.json"] atomically:YES encoding:NSUTF8StringEncoding error:&*arror];
}





#pragma mark -
#pragma mark Converting from JSON

/***************************
 Convert the JSON attributes to the cache node attributes
 **************************/
- (NSDictionary *)_cacheNodeAttributesFromJSONAttributes:(NSDictionary *)aJSONAttributes inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *cacheNodeAttributes = [NSMutableDictionary dictionary];
	
	[[aEntity attributesByName] enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeDescription, BOOL *stop) {
		//Look for a value for our attribute
		id attribute = [aJSONAttributes objectForKey:attributeName];
		if (!attribute)
			return;
		
		//Handle dates
		if ([attributeDescription attributeType] == NSDateAttributeType) {
			attribute = [NSDate dateWithString:attribute];
		}
		
		[cacheNodeAttributes setObject:attribute forKey:attributeName];
	}];
	
	return cacheNodeAttributes;
}

/***************************
Convert the JSON relationships to object ID relationships
 **************************/
- (NSDictionary *)_objectIDRelationshipsFromJSONRelationships:(NSDictionary *)aJSONRelationships inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *objectIDRelationships = [NSMutableDictionary dictionary];
	
	[[aEntity relationshipsByName] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
		//Look for values for our relationship
		id relationship = [aJSONRelationships objectForKey:relationshipName];
		if (!relationship)
			return;
		
		//If it's to many then loop through and get all the ids for the relationship
		if ([relationshipDescription isToMany]) {
			NSMutableSet *relationshipIDs = [NSMutableSet set];
			for (NSString *JSONRelationship in relationship) {
				[relationshipIDs addObject:[self objectIDForEntity:[relationshipDescription destinationEntity] referenceObject:JSONRelationship]];
			}
			[objectIDRelationships setObject:relationshipIDs forKey:relationshipName];
		//Else get the single id
		} else {
			[objectIDRelationships setObject:[self objectIDForEntity:[relationshipDescription destinationEntity] referenceObject:relationship] forKey:relationshipName];
		}
	}];
	
	return objectIDRelationships;
}

/***************************
 Return the node data (attributes, unfulfilled relationships and object IDs) for the entities using the url at the supplied path
 **************************/
- (NSArray *)_nodeDataForEntities:(NSArray *)aEntities atURL:(NSURL *)aBaseURL error:(NSError **)aError {
	NSMutableArray *returnArray = [NSMutableArray array];
	
	for (NSEntityDescription *entity in aEntities) {
		//Parse our entity JSON to a dictionary
		NSData *data = [NSData dataWithContentsOfURL:[[self URL] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", [entity name]]]];
		NSDictionary *entityDictionary = [[_CJSONDeserializer deserializer] deserializeAsDictionary:data error:aError];
		if (!entityDictionary)
			return nil;
		
		//Loop our objects, getting loading the attributes, relationships and id
		NSInteger lastIndex = 0;
		for (NSString *objectID in entityDictionary) {
			NSDictionary *objectValues = [entityDictionary objectForKey:objectID];
			
			NSDictionary *attributes = [self _cacheNodeAttributesFromJSONAttributes:objectValues inEntity:entity];
			NSDictionary *relationships = [self _objectIDRelationshipsFromJSONRelationships:objectValues inEntity:entity];
			
			NSString *referenceId = [NSString stringWithFormat:@"%@.%@", [entity name], objectID];
			NSManagedObjectID *managedObjectID = [self objectIDForEntity:entity referenceObject:referenceId];
			
			[returnArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:attributes, M3AttributesKey, relationships, M3RelationshipsKey, managedObjectID, M3ObjectIdKey, nil]];
			
			//Update the last index
			if ([objectID integerValue] > lastIndex) {
				lastIndex = [objectID integerValue];
			}
		}
		[entityLastIndexes setObject:[NSNumber numberWithInteger:lastIndex] forKey:[entity name]];
	}
	
	return [returnArray copy];
}

/***************************
 Get the final property cache data using the supplied data and node map
 **************************/
- (NSMutableDictionary *)_propertyDataFromNodeData:(NSDictionary *)aData usingNodeMap:(NSDictionary *)aNodeMap {
	NSMutableDictionary *propertyData = [NSMutableDictionary dictionaryWithDictionary:[aData objectForKey:M3AttributesKey]];
	
	//Handle relationships
	[[aData objectForKey:M3RelationshipsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, id relationship, BOOL *stop) {
		//To many relationship
		if ([relationship isKindOfClass:[NSSet class]]) {
			NSMutableSet *relationshipSet = [NSMutableSet set];
			
			for (NSManagedObjectID *relationshipID in relationship) {
				[relationshipSet addObject:[aNodeMap objectForKey:relationshipID]];
			}
			
			[propertyData setObject:relationshipSet forKey:relationshipName];
		//To one relationship
		} else {
			[propertyData setObject:[aNodeMap objectForKey:relationship] forKey:relationshipName];
		}
	}];
	
	return propertyData;
}



/***************************
 Load data
 **************************/
- (BOOL)load:(NSError **)aError {
	NSDictionary *metadataDict = [[self class] metadataForPersistentStoreWithURL:[self URL] error:&*aError];
	if (!metadataDict)
		return NO;
	[self setMetadata:metadataDict];
	
	NSDictionary *objectData = [jsonStore loadFromURL:[self URL]];
	
	NSMutableDictionary *nodemap = [NSMutableDictionary dictionary];
	for (NSString *jsonId in objectData) {
		//Ignore any non-numeric objects, our stores are 1 indexed
		if ([jsonId integerValue] == 0)
			continue;
		[jsonStore objectFromDictionary:objectData
								 withId:jsonId
							   usingMap:nodemap 
						  creationBlock:^id(NSEntityDescription *entity, NSString *jsonId) 
		{
			NSManagedObjectID *objectId = [self objectIDForEntity:entity referenceObject:jsonId];
			return [[NSAtomicStoreCacheNode alloc] initWithObjectID:objectId];									  
		}];
		
		//Look for highest index
		NSString *entityName = [[jsonId componentsSeparatedByString:@"."] objectAtIndex:0];
		NSInteger entityId = [[[jsonId componentsSeparatedByString:@"."] objectAtIndex:1] integerValue];
		NSNumber *lastIndex = [entityLastIndexes objectForKey:entityName];
		if (!lastIndex) {
			lastIndex = [NSNumber numberWithInt:1];
		}
		if ([lastIndex integerValue] < entityId) {
			[entityLastIndexes setObject:[NSNumber numberWithInteger:entityId] forKey:entityName];
		}
	}
	
	[self addCacheNodes:[NSSet setWithArray:[nodemap allValues]]];
	
	return YES;
}


/***************************
 Create a new cach node
 **************************/
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)aManagedObject {
	NSAtomicStoreCacheNode *node = [[NSAtomicStoreCacheNode alloc] initWithObjectID:[aManagedObject objectID]];
	[self updateCacheNode:node fromManagedObject:aManagedObject];
	return node;
}

/***************************
 Create a new reference object
 **************************/
- (id)newReferenceObjectForManagedObject:(NSManagedObject *)aManagedObject {
	NSString *entityName = [[aManagedObject entity] name];
	
	//Increment the last index for the entity
	NSInteger lastIndex = [[entityLastIndexes objectForKey:entityName] integerValue];
	lastIndex++;
	[entityLastIndexes setObject:[NSNumber numberWithInteger:lastIndex] forKey:entityName];
	
	return [NSString stringWithFormat:@"%@.%ld", entityName, lastIndex];
}

/***************************
 Update the cache node
 **************************/
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)aNode fromManagedObject:(NSManagedObject *)aManagedObject {
	NSMutableDictionary *propertyCacheDict = [NSMutableDictionary dictionary];
	
	for (NSPropertyDescription *description in [aManagedObject entity]) {
		id value = [aManagedObject valueForKey:[description name]];
		if (value) {
			[propertyCacheDict setObject:value forKey:[description name]];
		}
	}
	
	[aNode setPropertyCache:propertyCacheDict];
}





#pragma mark -
#pragma mark Save

/***************************
 Save to disk
 **************************/
- (BOOL)save:(NSError **)aError {
	if (![[self class] setMetadata:[self metadata] forPersistentStoreWithURL:[self URL] error:aError]) {
		return NO;
	}
	
	NSMutableDictionary *nodes = [NSMutableDictionary dictionary];
	for (NSAtomicStoreCacheNode *node in [self cacheNodes]) {
		[nodes setObject:node forKey:[self referenceObjectForObjectID:[node objectID]]];
	}
	
	return [jsonStore saveObjects:nodes toURL:[self URL] error:aError];
}

/***************************
 Empty the property cache
 **************************/
- (void)willRemoveCacheNodes:(NSSet *)aCacheNodes {
	[aCacheNodes makeObjectsPerformSelector:@selector(setPropertyCache:) withObject:nil];
}

@end
