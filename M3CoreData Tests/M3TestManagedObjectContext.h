/*****************************************************************
 M3TestManagedObjectContext.h
 M3CoreData
 
 Created by Martin Pilkington on 10/10/2012.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import <CoreData/CoreData.h>

typedef NSArray *(^M3TestFetchRequestBlock)(NSFetchRequest *, NSError **);

@interface M3TestManagedObjectContext : NSManagedObjectContext

@property (copy) M3TestFetchRequestBlock fetchRequestBlock;

@end
