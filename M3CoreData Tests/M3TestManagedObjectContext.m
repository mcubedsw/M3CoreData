//
//  M3TestManagedObjectContext.m
//  M3CoreData
//
//  Created by Martin Pilkington on 10/10/2012.
//  Copyright (c) 2012 M Cubed Software. All rights reserved.
//

#import "M3TestManagedObjectContext.h"

@implementation M3TestManagedObjectContext

- (NSArray *)executeFetchRequest:(NSFetchRequest *)aRequest error:(NSError *__autoreleasing *)aError {
	if (self.fetchRequestBlock) {
		return self.fetchRequestBlock(aRequest, aError);
	}
	return [super executeFetchRequest:aRequest error:aError];
}

- (NSUInteger)countForFetchRequest:(NSFetchRequest *)aRequest error:(NSError *__autoreleasing *)aError {
	if (self.fetchRequestBlock) {
		return [self.fetchRequestBlock(aRequest, aError) count];
	}
	return [super countForFetchRequest:aRequest error:aError];
}

@end
