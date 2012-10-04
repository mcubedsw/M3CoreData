/*****************************************************************
 M3CoreDataConstants.h
 M3CoreData
 
 Created by Martin Pilkington on 27/05/2012.
 
 Please read the LICENCE.txt for licensing information
 *****************************************************************/

extern NSString *M3CoreDataErrorDomain;

extern const NSInteger M3EntityNotFoundError;

extern NSString *M3JSONStoreType;

#if TARGET_OS_MAC
	#define M3Color NSColor
#elif TARGET_OS_IPHONE
	#define M3Color UIColor
#else
	#error "Unsupported platform"
#endif