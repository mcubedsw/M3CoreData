//
//  M3TestValueTransformer.m
//  M3CoreData
//
//  Created by Martin Pilkington on 22/01/2013.
//  Copyright (c) 2013 M Cubed Software. All rights reserved.
//

#import "M3TestValueTransformer.h"

@implementation M3TestValueTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSString class];
}

- (id)transformedValue:(id)aValue {
	return [aValue stringByAppendingFormat:@"abc123"];
}

- (id)reverseTransformedValue:(NSString *)aValue {
	return [aValue substringToIndex:aValue.length - 6];
}

@end
