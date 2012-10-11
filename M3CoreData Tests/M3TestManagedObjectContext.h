//
//  M3TestManagedObjectContext.h
//  M3CoreData
//
//  Created by Martin Pilkington on 10/10/2012.
//  Copyright (c) 2012 M Cubed Software. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NSArray *(^M3TestFetchRequestBlock)(NSFetchRequest *, NSError **);

@interface M3TestManagedObjectContext : NSManagedObjectContext

@property (copy) M3TestFetchRequestBlock fetchRequestBlock;

@end
