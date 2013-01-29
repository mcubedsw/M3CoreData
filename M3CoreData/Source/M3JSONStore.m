/*****************************************************************
 M3JSONStore.h
 M3CoreData
 
 Created by Martin Pilkington on 30/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3JSONStore.h"
#import "M3StoreObjectFactory.h"
#import "_CJSONDeserializer.h"
#import "_CJSONSerializer.h"

//???: Yes I know, very long methods. I need to refactor this class quite a lot
@implementation M3JSONStore

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)aModel dataURL:(NSURL *)aURL objectFactory:(id<M3StoreObjectFactory>)aFactory {
	if ((self = [super init])) {
		_managedObjectModel = aModel;
		_dataURL = aURL;
		_objectFactory = aFactory;
	}
	return self;
}





#pragma mark -
#pragma mark Public Methods

- (NSDictionary *)loadObjects:(NSError **)aError {
	if (![self validateDataURLForLoading:aError]) return nil;
	
	NSDictionary *JSONRepresentation = [self loadJSONRepresentation:aError];
	if (!JSONRepresentation) return nil;
	
	NSDictionary *objects = [self createObjectsFromJSONRepresentation:JSONRepresentation];
	[self createRelationshipsBetweenObjects:objects withJSONRepresentation:JSONRepresentation];
	
	return objects;
}


- (BOOL)saveObjects:(NSDictionary *)aObjects error:(NSError **)aError {
	if (![self validateDataURLForSaving:aError]) return NO;
	
	for (NSString *entityName in aObjects) {
		NSDictionary *JSONRepresentation = [self JSONRepresentationOfObjects:aObjects[entityName] inEntity:self.managedObjectModel.entitiesByName[entityName]];

		if (![self writeJSONEntityWithName:entityName objects:JSONRepresentation error:aError]) return NO;
	}
	
	return YES;
}





#pragma mark -
#pragma mark Load JSON

- (NSDictionary *)loadJSONRepresentation:(NSError **)aError {
	NSMutableDictionary *JSONRepresentation = [NSMutableDictionary dictionary];
	for (NSString *entityName in self.managedObjectModel.entitiesByName) {
		NSDictionary *JSONDictionary = [self JSONDictionaryForEntityWithName:entityName error:aError];
		if (!JSONDictionary) return nil;
		
		JSONRepresentation[entityName] = JSONDictionary;
	}
	return [JSONRepresentation copy];
}


- (NSDictionary *)JSONDictionaryForEntityWithName:(NSString *)aName error:(NSError **)aError {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *fileName = [aName stringByAppendingPathExtension:@"json"];
	//If the file doesn't exist, we have an empty entity. This is not a failure so we need to return an empty dictionary rather than nil
	if (![fileManager fileExistsAtPath:[self.dataURL.path stringByAppendingPathComponent:fileName]]) return @{};
	
	NSData *JSONData = [NSData dataWithContentsOfURL:[self.dataURL URLByAppendingPathComponent:fileName] options:0 error:aError];
	if (!JSONData) return nil;
	
	return [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:aError];
}





#pragma mark -
#pragma mark Write JSON 

- (BOOL)writeJSONEntityWithName:(NSString *)aEntityName objects:(NSDictionary *)aObjects error:(NSError **)aError {
	NSData *data = [NSJSONSerialization dataWithJSONObject:aObjects options:NSJSONWritingPrettyPrinted error:aError];
	if (!data) return NO;
	
	//We shoudl really write everything to a separate bundle then replace it atomically, but we can cheat for now given this isn't really for production use
	NSString *fileName = [aEntityName stringByAppendingPathExtension:@"json"];
	return [data writeToURL:[self.dataURL URLByAppendingPathComponent:fileName] options:NSDataWritingAtomic error:aError];
}





#pragma mark -
#pragma mark Creating Objects

- (NSDictionary *)createObjectsFromJSONRepresentation:(NSDictionary *)aJSONRepresentation {
	NSMutableDictionary *objects = [NSMutableDictionary dictionary];
	NSDictionary *entities = self.managedObjectModel.entitiesByName;
	
	for (NSString *entityName in entities) {
		objects[entityName] = [self objectsFromJSONDictionary:aJSONRepresentation[entityName] entity:entities[entityName]];
	}
	
	return [objects copy];
}


- (NSDictionary *)objectsFromJSONDictionary:(NSDictionary *)aDictionary entity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *objects = [NSMutableDictionary dictionary];
	[aDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *JSONID, NSDictionary *JSONDictionary, BOOL *stop) {
		objects[JSONID] = [self objectFromJSONDictionary:JSONDictionary JSONID:JSONID entity:aEntity];
	}];
	return [objects copy];
}


- (id)objectFromJSONDictionary:(NSDictionary *)aDictionary JSONID:(NSString *)aID entity:(NSEntityDescription *)aEntity {
	id object = [self.objectFactory createObjectWithEntity:aEntity JSONID:aID];
	
	[aEntity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
		id value = aDictionary[attributeName];
		if (!value) return;
		
		if (attribute.attributeType == NSDateAttributeType) value = [self dateFromStringValue:value];
		else if (attribute.attributeType == NSTransformableAttributeType) value = [self transformedValue:value forAttribute:attribute];
		
		[object setValue:value forKey:attributeName];
	}];
	
	return object;
}





#pragma mark -
#pragma mark Transforming values

- (NSDate *)dateFromStringValue:(NSString *)aString {
	return [NSDate dateWithString:aString];
}


- (NSString *)stringValueFromDate:(NSDate *)aDate {
	return aDate.description;
}


- (id)transformedValue:(id)aValue forAttribute:(NSAttributeDescription *)aAttribute {
	NSString *classValueName = aAttribute.userInfo[@"attributeValueClassName"];
	
	if ([classValueName isEqualToString:@"NSURL"]) return [NSURL URLWithString:aValue];
	
	if ([classValueName isEqualToString:@"NSColor"]) {
		NSArray *components = [[aValue substringWithRange:NSMakeRange(6, [aValue length] - 7)] componentsSeparatedByString:@","];
		return [NSColor colorWithCalibratedRed:[components[0] integerValue]/255.0
										 green:[components[1] integerValue]/255.0
										  blue:[components[2] integerValue]/255.0
										 alpha:[components[3] floatValue]];
	}
	
	return [[NSValueTransformer valueTransformerForName:aAttribute.valueTransformerName] transformedValue:aValue];
}


- (id)reverseTransformedValue:(id)aValue forAttribute:(NSAttributeDescription *)aAttribute {
	NSString *classValueName = aAttribute.userInfo[@"attributeValueClassName"];
	
	if ([classValueName isEqualToString:@"NSURL"]) return [aValue absoluteString];
	
	if ([classValueName isEqualToString:@"NSColor"]) {
		M3Color *colour = [aValue colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
		
		NSUInteger redComponent = 255 * colour.redComponent;
		NSUInteger greenComponent = 255 * colour.greenComponent;
		NSUInteger blueComponent = 255 * colour.blueComponent;
		
		return [NSString stringWithFormat:@"@rgba(%ld,%ld,%ld,%.2f)", redComponent, greenComponent, blueComponent, colour.alphaComponent];
	}
	
	return [[NSValueTransformer valueTransformerForName:aAttribute.valueTransformerName] reverseTransformedValue:aValue];

}





#pragma mark -
#pragma mark Creating relationships

- (void)createRelationshipsBetweenObjects:(NSDictionary *)aObjects withJSONRepresentation:(NSDictionary *)aJSONRepresentation {
	NSDictionary *entities = self.managedObjectModel.entitiesByName;
	NSDictionary *relationshipMap = [self relationshipMapFromObjects:aObjects];
	
	for (NSString *entityName in entities) {
		for (NSString *objectID in aObjects[entityName]) {
			[self createRelationshipForObject:aObjects[entityName][objectID] JSONRepresentation:aJSONRepresentation[entityName][objectID] entity:entities[entityName] relationshipMap:relationshipMap];
		}
	}
}


- (NSDictionary *)relationshipMapFromObjects:(NSDictionary *)aDictionary {
	NSMutableDictionary *map = [NSMutableDictionary dictionary];
	
	for (NSString *entityName in aDictionary) {
		for (NSString *objectID in aDictionary[entityName]) {
			NSString *relationshipID = [NSString stringWithFormat:@"%@.%@", entityName, objectID];
			map[relationshipID] = aDictionary[entityName][objectID];
		}
	}
	return [map copy];
}


- (void)createRelationshipForObject:(id)aObject JSONRepresentation:(NSDictionary *)aJSONRepresentation entity:(NSEntityDescription *)aEntity relationshipMap:(NSDictionary *)aMap {
	[aEntity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationship, BOOL *stop) {
		id relationshipIDs = [aJSONRepresentation valueForKey:relationshipName];
		if (!relationshipIDs) return;
		
		if (relationship.isToMany) {
			NSMutableSet *relationshipValue = [NSMutableSet set];
			for (NSString *relationshipID in relationshipIDs) {
				[relationshipValue addObject:aMap[relationshipID]];
			}
			[aObject setValue:[relationshipValue copy] forKey:relationshipName];
		} else {
			[aObject setValue:aMap[relationshipIDs] forKey:relationshipName];
		}
	}];
}





#pragma mark -
#pragma mark Creating JSON Dictionaries

- (NSDictionary *)JSONRepresentationOfObjects:(NSDictionary *)aObjects inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *JSONRepresentation = [NSMutableDictionary dictionary];
	for (NSString *JSONID in aObjects) {
		JSONRepresentation[JSONID] = [self JSONRepresentationOfObject:aObjects[JSONID] inEntity:aEntity];
	}
	return [JSONRepresentation copy];
}


- (NSDictionary *)JSONRepresentationOfObject:(NSDictionary *)aObject inEntity:(NSEntityDescription *)aEntity {
	NSMutableDictionary *JSONRepresentation = [NSMutableDictionary dictionary];
	
	//Attributes
	[aEntity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
		id value = aObject[attributeName];
		if (!value) return;
		
		if (attribute.attributeType == NSDateAttributeType) value = [self stringValueFromDate:value];
		else if (attribute.attributeType == NSTransformableAttributeType) value = [self reverseTransformedValue:value forAttribute:attribute];
		
		JSONRepresentation[attributeName] = value;
	}];
	
	return [JSONRepresentation copy];
}





#pragma mark -
#pragma mark Helpers

- (BOOL)validateDataURLForLoading:(NSError **)aError {
	NSFileManager *fileManager = [NSFileManager new];
	BOOL isDirectory = NO;
	if ([fileManager fileExistsAtPath:self.dataURL.path isDirectory:&isDirectory] && !isDirectory) {
		if (aError != NULL) *aError = [self notDirectoryErrorWithURL:self.dataURL];
		return NO;
	}
	return YES;
}


- (BOOL)validateDataURLForSaving:(NSError **)aError {
	NSFileManager *fileManager = [NSFileManager new];
	BOOL isDirectory = NO;
	BOOL fileExists = [fileManager fileExistsAtPath:self.dataURL.path isDirectory:&isDirectory];
	
	if (fileExists && !isDirectory) {
		*aError = [self notDirectoryErrorWithURL:self.dataURL];
		return NO;
	}
	
	if (!fileExists) {
		if (![fileManager createDirectoryAtURL:self.dataURL withIntermediateDirectories:YES attributes:nil error:aError]) return NO;
	}
	return YES;
}











#pragma mark -
#pragma mark Errors

- (NSError *)notDirectoryErrorWithURL:(NSURL *)aURL {
	return [NSError errorWithDomain:M3CoreDataErrorDomain code:0 userInfo:nil];
}











//*****//
- (id)initWithModel:(NSManagedObjectModel *)aModel {
	if ((self = [super init])) {
		_managedObjectModel = aModel;
	}
	return self;
}





#pragma mark - 
#pragma mark Loading

//*****//
- (NSDictionary *)loadFromURL:(NSURL *)aURL {
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
	[self.managedObjectModel.entitiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entity, BOOL *stop) {
		NSString *entityFile = [NSString stringWithFormat:@"%@.json", entityName];
		NSData *entityData = [NSData dataWithContentsOfURL:[aURL URLByAppendingPathComponent:entityFile]];
		if (!entityData) return;

		NSError *error = nil;
		NSDictionary *entityDict = [[_CJSONDeserializer deserializer] deserializeAsDictionary:entityData error:&error];
		NSAssert(entityDict, @"Error while parsing JSON for entity '%@': %@", entityName, error);
		
		for (NSString *jsonID in entityDict) {
			for (NSString *idComponent in [jsonID componentsSeparatedByString:@"::"]) {
				NSString *objectID = [NSString stringWithFormat:@"%@.%@", entityName, idComponent];
				returnDictionary[objectID] = entityDict[jsonID];
			}
		}
	}];
	
	return [returnDictionary copy];
}





#pragma mark -
#pragma mark Saving

//*****//
- (BOOL)saveObjects:(NSDictionary *)aObjects toURL:(NSURL *)aURL error:(NSError **)aError {
	NSMutableDictionary *jsonEntities = [NSMutableDictionary dictionary];
	
	[aObjects enumerateKeysAndObjectsUsingBlock:^(NSString *jsonId, id object, BOOL *stop) {
		NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
		
		NSString *entityName = [jsonId componentsSeparatedByString:@"."][0];
		NSString *objectId = [jsonId componentsSeparatedByString:@"."][1];
		NSEntityDescription *entity = self.managedObjectModel.entitiesByName[entityName];
		
		[entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
			id attributeValue = [object valueForKey:attributeName];
			if (!attributeValue) return;
			
			if (attribute.attributeType == NSDateAttributeType) {
				attributeValue = [attributeValue description];
			} else if (attribute.attributeType == NSTransformableAttributeType) {
				NSString *classValueName = attribute.userInfo[@"attributeValueClassName"];
				
				if ([classValueName isEqualToString:@"NSURL"]) {
					attributeValue = [NSString stringWithFormat:@"@url(%@)", attributeValue];
				//TODO: Handle UI Color
				} else if ([classValueName isEqualToString:@"NSColor"]) {
					M3Color *colour = [attributeValue colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
					attributeValue = [NSString stringWithFormat:@"@rgba(%f,%f,%f,%f.2)", 255 * colour.redComponent, 255 * colour.greenComponent, 255 * colour.blueComponent, colour.alphaComponent];
				} else {
					attributeValue = [[NSValueTransformer valueTransformerForName:attribute.valueTransformerName] reverseTransformedValue:attributeValue];
				}
			}
			//handle archived, url and colour
			jsonObject[attributeName] = attributeValue;
		}];
		
		[entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
			if (relationshipDescription.isToMany) {
				NSMutableArray *relationshipValue = [NSMutableArray array];
				for (id relationshipNode in [object valueForKey:relationshipName]) {
					NSArray *keys = [aObjects allKeysForObject:relationshipNode];
					if (keys.count) {
						[relationshipValue addObject:keys[0]];
					}
				}
				if (relationshipValue.count) {
					jsonObject[relationshipName] = relationshipValue;
				}
			} else {
				id relationshipNode = [object valueForKey:relationshipName];
				if (relationshipNode) {
					NSArray *keys = [aObjects allKeysForObject:relationshipNode];
					if (keys.count) {
						jsonObject[relationshipName] = keys[0];
					}
				}
			}
		}];
		
		//Add to our entity dict, creating it if needed
		NSMutableDictionary *entityDict = jsonEntities[entity.name];
		if (!entityDict) {
			entityDict = [NSMutableDictionary dictionary];
			jsonEntities[entity.name] = entityDict;
		}
		
		entityDict[objectId] = entityDict;
	}];
	
	//Loop through our JSON entities and write to disk
	for (NSString *entityName in jsonEntities) {
		NSDictionary *jsonRepresentation = jsonEntities[entityName];
		NSString *fileContents = [[_CJSONSerializer serializer] serializeDictionary:jsonRepresentation];
		NSURL *entityURL = [aURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", entityName]];
		if (![fileContents writeToURL:entityURL atomically:YES encoding:NSUTF8StringEncoding error:aError]) {
			return NO;
		}
	}
	return YES;
}





#pragma mark -
#pragma mark Quering

- (id)objectFromDictionary:(NSDictionary *)aDict withId:(NSString *)aId usingMap:(NSMutableDictionary *)aMap creationBlock:(id (^)(NSEntityDescription *entity, NSString *jsonId))aBlock {
	id object = aMap[aId];
	if (!object) {
		NSString *entityName = [aId componentsSeparatedByString:@"."][0];
		
		NSEntityDescription *entity = self.managedObjectModel.entitiesByName[entityName];
		NSDictionary *objectData = aDict[aId];
		NSAssert(entity, @"Entity with name '%@' does not exist", entityName);
		
		object = aBlock(entity, aId);
		for (NSString *objectId in [aDict allKeysForObject:objectData]) {
			aMap[objectId] = object;
		}
		
		[entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
			id attributeValue = objectData[attributeName];
			if (!attributeValue) return;
			
			if (attribute.attributeType == NSDateAttributeType) {
				attributeValue = [NSDate dateWithString:attributeValue];
			} else if (attribute.attributeType == NSTransformableAttributeType) {
				NSString *classValueName = attribute.userInfo[@"attributeValueClassName"];
				if (!classValueName) {
					attributeValue = [[NSValueTransformer valueTransformerForName:attribute.valueTransformerName] transformedValue:attributeValue];
				} else if ([classValueName isEqualToString:@"NSURL"]) {
					NSAssert([attributeValue hasPrefix:@"@url("], @"URL in attribute '%@' in JSON object '%@' isn't correctly defined as @url()", attributeName, aId);
					attributeValue = [NSURL URLWithString:[attributeValue substringWithRange:NSMakeRange(5, [attributeValue length] - 6)]];
				//TODO: Handle UI Color
				} else if ([classValueName isEqualToString:@"NSColor"]) {
					NSAssert([attributeValue hasPrefix:@"@rgba("], @"Colour in attribute '%@' in JSON object '%@' isn't correctly defined as @rgba()", attributeName, aId);
					NSArray *colourComponents = [[attributeValue substringWithRange:NSMakeRange(6, [attributeValue length] - 7)] componentsSeparatedByString:@","];
					NSAssert(colourComponents.count == 4, @"Colour in attribute '%@' in JSON object '%@' doesn't have 4 components", attributeName, aId);
					attributeValue = [NSColor colorWithCalibratedRed:[colourComponents[0] integerValue]/255.0
															   green:[colourComponents[1] integerValue]/255.0
																blue:[colourComponents[2] integerValue]/255.0
															   alpha:[colourComponents[3] floatValue]];
				}
			}
			
			[object setValue:attributeValue forKey:attributeName];
		}];
		
		[entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationship, BOOL *stop) {
			id relationshipValue = objectData[relationshipName];
			if (!relationshipValue)	return;
			
			if (relationship.isToMany) {
				NSAssert([relationshipValue isKindOfClass:[NSArray class]], @"Relationship '%@' is defined as to-many, but in the JSON object '%@' it isn't defined as an array", relationshipName, aId);
				NSMutableSet *relationshipSet = [NSMutableSet set]; 
				for (NSString *relationshipItem in relationshipValue) {
					id relationshipObject = [self objectFromDictionary:aDict withId:relationshipItem usingMap:aMap creationBlock:aBlock];
					[relationshipSet addObject:relationshipObject];
				}
				[object setValue:relationshipSet forKey:relationshipName];
			} else {
				NSAssert([relationshipValue isKindOfClass:[NSString class]], @"Relationship '%@' is defined as to-one, but in the JSON object '%@' it isn't defined as a string", relationshipName, aId);
				id relationshipObject = [self objectFromDictionary:aDict withId:relationshipValue usingMap:aMap creationBlock:aBlock];
				[object setValue:relationshipObject forKey:relationshipName];
			}
		}];
	}
	
	return object;
}

@end
