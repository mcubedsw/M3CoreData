/*****************************************************************
 M3StoreObjectFactory.h
 M3CoreData
 
 Created by Martin Pilkington on 21/01/2013.
 
 Please read the LICENCE.txt for licensing information
*****************************************************************/

#import <Foundation/Foundation.h>

@protocol M3StoreObjectFactory <NSObject>

- (id)createObjectWithEntity:(NSEntityDescription *)aEntity JSONID:(NSString *)aJSONID;

@end
