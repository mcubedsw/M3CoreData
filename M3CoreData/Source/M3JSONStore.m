/*****************************************************************
 M3JSONStore.h
 M3CoreData
 
 Created by Martin Pilkington on 30/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3JSONStore.h"
#import "_CJSONDeserializer.h"
#import "_CJSONSerializer.h"

//???: Yes I know, very long methods. I need to refactor this class quite a lot
@implementation M3JSONStore

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
#warning Handle UI Color
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
#warning Handle UI Color
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
			
			object[attributeName] = attributeValue;
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
				object[relationshipName] = relationshipSet;
			} else {
				NSAssert([relationshipValue isKindOfClass:[NSString class]], @"Relationship '%@' is defined as to-one, but in the JSON object '%@' it isn't defined as a string", relationshipName, aId);
				id relationshipObject = [self objectFromDictionary:aDict withId:relationshipValue usingMap:aMap creationBlock:aBlock];
				object[relationshipName] = relationshipObject;
			}
		}];
	}
	
	return object;
}

@end
