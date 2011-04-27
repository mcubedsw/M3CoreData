/*****************************************************************
 M3JSONAtomicStore.h
 M3CoreData
 
 Created by Martin Pilkington on 25/02/2011.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

#import <Foundation/Foundation.h>

extern NSString *M3JSONStoreType;

@interface M3JSONAtomicStore : NSAtomicStore {
	NSMutableDictionary *entityLastIndexes;
}

@end
