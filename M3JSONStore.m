/*****************************************************************
 M3JSONStore.h
 M3CoreData
 
 Created by Martin Pilkington on 30/04/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import "M3JSONStore.h"
#import "_CJSONDeserializer.h"
#import "_CJSONSerializer.h"

@implementation M3JSONStore {
	NSManagedObjectModel *model;
}

- (id)initWithModel:(NSManagedObjectModel *)aModel {
	if ((self = [super init])) {
		model = [aModel retain];
	}
	return self;
}

- (void)dealloc {
	[model release];
	[super dealloc];
}

- (NSDictionary *)loadFromURL:(NSURL *)aURL {
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
	[[model entitiesByName] enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entity, BOOL *stop) {
		NSData *entityData = [NSData dataWithContentsOfURL:[aURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", entityName]]];
		NSError *error = nil;
		NSDictionary *entityDict = [[_CJSONDeserializer deserializer] deserializeAsDictionary:entityData error:&error];
		NSAssert(entityDict, @"Error while parsing JSON for entity '%@': %@", entityName, error);
		
		for (NSString *objId in entityDict) {
			[returnDictionary setObject:[entityDict objectForKey:objId] forKey:[NSString stringWithFormat:@"%@.%@", entityName, objId]];
		}
	}];
	
	return [[returnDictionary copy] autorelease];
}

- (BOOL)saveObjects:(NSDictionary *)aObjects toURL:(NSURL *)aURL error:(NSError **)aError {
	//pass in objects dict
	
	NSMutableDictionary *jsonEntities = [NSMutableDictionary dictionary];
	
	[aObjects enumerateKeysAndObjectsUsingBlock:^(NSString *jsonId, id obj, BOOL *stop) {
		NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
		
		NSString *entityName = [[jsonId componentsSeparatedByString:@"."] objectAtIndex:0];
		NSString *objectId = [[jsonId componentsSeparatedByString:@"."] objectAtIndex:1];
		NSEntityDescription *entity = [[model entitiesByName] objectForKey:entityName];
		
		[[entity attributesByName] enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
			id attributeValue = [obj valueForKey:attributeName];
			if (!attributeValue)
				return;
			
			if ([attribute attributeType] == NSDateAttributeType) {
				attributeValue = [attributeValue description];
			} else if ([attribute attributeType] == NSTransformableAttributeType) {
				NSString *classValueName = [[attribute userInfo] objectForKey:@"attributeValueClassName"];
				
				if ([classValueName isEqualToString:@"NSURL"]) {
					attributeValue = [NSString stringWithFormat:@"@url(%@)", attributeValue];
				} else if ([classValueName isEqualToString:@"NSColor"]) {
					NSColor *colour = [attributeValue colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
					attributeValue = [NSString stringWithFormat:@"@rgba(%d,%d,%d,%f.2)", 255 * [colour redComponent], 255 * [colour greenComponent], 255 * [colour blueComponent], [colour alphaComponent]];
				} else {
					attributeValue = [[NSValueTransformer valueTransformerForName:[attribute valueTransformerName]] reverseTransformedValue:attributeValue];
				}
			}
			//handle archived, url and colour
			[jsonObject setObject:attributeValue forKey:attributeName];
		}];
		
		[[entity relationshipsByName] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
			if ([relationshipDescription isToMany]) {
				NSMutableArray *relationshipValue = [NSMutableArray array];
				for (id relationshipNode in [obj valueForKey:relationshipName]) {
					NSArray *keys = [aObjects allKeysForObject:relationshipNode];
					if ([keys count]) {
						[relationshipValue addObject:[keys objectAtIndex:0]];
					}
				}
				if ([relationshipValue count]) {
					[jsonObject setObject:relationshipValue forKey:relationshipName];
				}
			} else {
				id relationshipNode = [obj valueForKey:relationshipName];
				if (relationshipNode) {
					NSArray *keys = [aObjects allKeysForObject:relationshipNode];
					if ([keys count]) {
						[jsonObject setObject:[keys objectAtIndex:0] forKey:relationshipName];
					}
				}
			}
		}];
		
		//Add to our entity dict, creating it if needed
		NSMutableDictionary *entityDict = [jsonEntities objectForKey:[entity name]];
		if (!entityDict) {
			entityDict = [NSMutableDictionary dictionary];
			[jsonEntities setObject:entityDict forKey:[entity name]];
		}
		
		[entityDict setObject:jsonObject forKey:objectId];
	}];
	
	//Loop through our JSON entities and write to disk
	for (NSString *entityName in jsonEntities) {
		NSDictionary *jsonRepresentation = [jsonEntities objectForKey:entityName];
		NSString *fileContents = [[_CJSONSerializer serializer] serializeDictionary:jsonRepresentation];
		NSURL *entityURL = [aURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", entityName]];
		if (![fileContents writeToURL:entityURL atomically:YES encoding:NSUTF8StringEncoding error:&*aError])
			return NO;
	};
	return YES;
}

- (id)objectFromDictionary:(NSDictionary *)aDict withId:(NSString *)aId usingMap:(NSMutableDictionary *)aMap creationBlock:(id (^)(NSEntityDescription *entity, NSString *jsonId))aBlock {
	id object = [aMap objectForKey:aId];	
	if (!object) {
		NSString *entityName = [[aId componentsSeparatedByString:@"."] objectAtIndex:0];
		
		NSEntityDescription *entity = [[model entitiesByName] objectForKey:entityName];
		NSDictionary *objectData = [aDict objectForKey:aId];
		
		NSAssert(entity, @"Entity with name '%@' does not exist", entityName);
		
		object = aBlock(entity, aId);
		[aMap setObject:object forKey:aId];
		
		[[entity attributesByName] enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attribute, BOOL *stop) {
			id attributeValue = [objectData objectForKey:attributeName];
			if (!attributeValue)
				return;
			
			if ([attribute attributeType] == NSDateAttributeType) {
				attributeValue = [NSDate dateWithString:attributeValue];
			} else if ([attribute attributeType] == NSTransformableAttributeType) {
				NSString *classValueName = [[attribute userInfo] objectForKey:@"attributeValueClassName"];
				if (!classValueName) {
					attributeValue = [[NSValueTransformer valueTransformerForName:[attribute valueTransformerName]] transformedValue:attributeValue];
				} else if ([classValueName isEqualToString:@"NSURL"]) {
					NSAssert([attributeValue hasPrefix:@"@url("], @"URL in attribute '%@' in JSON object '%@' isn't correctly defined as @url()", attributeName, aId);
					attributeValue = [NSURL URLWithString:[attributeValue substringWithRange:NSMakeRange(5, [attributeValue length]-6)]];
				} else if ([classValueName isEqualToString:@"NSColor"]) {
					NSAssert([attributeValue hasPrefix:@"@rgba("], @"Colour in attribute '%@' in JSON object '%@' isn't correctly defined as @rgba()", attributeName, aId);
					NSArray *colourComponents = [[attributeValue substringWithRange:NSMakeRange(6, [attributeValue length]-7)] componentsSeparatedByString:@","];
					NSAssert([colourComponents count] == 4, @"Colour in attribute '%@' in JSON object '%@' doesn't have 4 components", attributeName, aId);
					attributeValue = [NSColor colorWithCalibratedRed:[[colourComponents objectAtIndex:0] integerValue]/255.0
															   green:[[colourComponents objectAtIndex:1] integerValue]/255.0
																blue:[[colourComponents objectAtIndex:2] integerValue]/255.0
															   alpha:[[colourComponents objectAtIndex:3] floatValue]];
				}
			}
			
			[object setValue:attributeValue forKey:attributeName];
		}];
		
		[[entity relationshipsByName] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationship, BOOL *stop) {
			id relationshipValue = [objectData objectForKey:relationshipName];
			if (!relationshipValue)
				return;
			
			if ([relationship isToMany]) {
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
