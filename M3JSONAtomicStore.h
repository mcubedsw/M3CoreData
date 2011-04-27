//
//  M3JSONAtomicStore.h
//  JSONAtomicStore
//
//  Created by Martin Pilkington on 25/02/2011.
//  Copyright 2011 M Cubed Software. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *M3JSONStoreType;

@interface M3JSONAtomicStore : NSAtomicStore {
	NSMutableDictionary *entityLastIndexes;
}

@end
