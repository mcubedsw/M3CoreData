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
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL*)url options:(NSDictionary *)options { 
	BOOL isDirectory;
	BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
	if (![url isFileURL] || (!isDirectory && storeExists)) {
		[self release];
		return nil;
	}
		
	if ((self = [super initWithPersistentStoreCoordinator:coordinator configurationName:configurationName URL:url options:options])) {
		if (!storeExists) {
			if (![[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:NULL]) {
				[self release];
				return nil;
			}
		}
		entityLastIndexes = [[NSMutableDictionary alloc] init];
		jsonStore = [[M3JSONStore alloc] initWithModel:[coordinator managedObjectModel]];
		[self setMetadata:[NSDictionary dictionaryWithObjectsAndKeys:[self type], NSStoreTypeKey, nil]];
	}
	return self;
}

/***************************
 Clean up
 **************************/
- (void)dealloc {
	[entityLastIndexes release];
	[super dealloc];
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
+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL *)url error:(NSError **)error {
	NSData *data = [NSData dataWithContentsOfURL:[url URLByAppendingPathComponent:@"_Metadata.json"]];
	NSMutableDictionary *metadata = [[[_CJSONDeserializer deserializer] deserializeAsDictionary:data error:&*error] mutableCopy];
	[metadata setObject:[NSArray arrayWithObject:@"1"] forKey:NSStoreModelVersionIdentifiersKey];
	return [metadata autorelease];
}

/***************************
 Set the metadata on the file
 **************************/
+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL*)url error:(NSError **)error {	
	NSString *json = [[_CJSONSerializer serializer] serializeDictionary:metadata];
	return [json writeToURL:[url URLByAppendingPathComponent:@"_Metadata.json"] atomically:YES encoding:NSUTF8StringEncoding error:&*error];
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
		NSDictionary *entityDictionary = [[_CJSONDeserializer deserializer] deserializeAsDictionary:data error:&*aError];
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
	
	return [[returnArray copy] autorelease];
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
- (BOOL)load:(NSError **)error {
	NSDictionary *metadataDict = [[self class] metadataForPersistentStoreWithURL:[self URL] error:&*error];
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
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject {
	NSAtomicStoreCacheNode *node = [[[NSAtomicStoreCacheNode alloc] initWithObjectID:[managedObject objectID]] autorelease];
	[self updateCacheNode:node fromManagedObject:managedObject];
	return node;
}

/***************************
 Create a new reference object
 **************************/
- (id)newReferenceObjectForManagedObject:(NSManagedObject *)managedObject {
	NSString *entityName = [[managedObject entity] name];
	
	//Increment the last index for the entity
	NSInteger lastIndex = [[entityLastIndexes objectForKey:entityName] integerValue];
	lastIndex++;
	[entityLastIndexes setObject:[NSNumber numberWithInteger:lastIndex] forKey:entityName];
	
	return [[NSString stringWithFormat:@"%@.%d", entityName, lastIndex] retain];
}

/***************************
 Update the cache node
 **************************/
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject {
	NSMutableDictionary *propertyCacheDict = [NSMutableDictionary dictionary];
	
	for (NSPropertyDescription *description in [managedObject entity]) {
		id value = [managedObject valueForKey:[description name]];
		if (value) {
			[propertyCacheDict setObject:value forKey:[description name]];
		}
	}
	
	[node setPropertyCache:propertyCacheDict];
}





#pragma mark -
#pragma mark Save

/***************************
 Save to disk
 **************************/
- (BOOL)save:(NSError **)error {
	if (![[self class] setMetadata:[self metadata] forPersistentStoreWithURL:[self URL] error:&*error]) {
		return NO;
	}
	
	NSMutableDictionary *nodes = [NSMutableDictionary dictionary];
	for (NSAtomicStoreCacheNode *node in [self cacheNodes]) {
		[nodes setObject:node forKey:[self referenceObjectForObjectID:[node objectID]]];
	}
	
	return [jsonStore saveObjects:nodes toURL:[self URL] error:&*error];
}

/***************************
 Empty the property cache
 **************************/
- (void)willRemoveCacheNodes:(NSSet *)cacheNodes {
	[cacheNodes makeObjectsPerformSelector:@selector(setPropertyCache:) withObject:nil];
}

@end
