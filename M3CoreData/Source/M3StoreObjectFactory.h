//
//  M3StoreObjectConverter.h
//  M3CoreData
//
//  Created by Martin Pilkington on 21/01/2013.
//  Copyright (c) 2013 M Cubed Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol M3StoreObjectFactory <NSObject>

- (id)createObjectWithEntity:(NSEntityDescription *)aEntity JSONID:(NSString *)aJSONID;

@end
