/*****************************************************************
M3CoreDataManager.h
M3Extensions

Created by Martin Pilkington on 15/07/2009.

Copyright (c) 2006-2010 M Cubed Software

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

*****************************************************************/

#import <Cocoa/Cocoa.h>


/**
 @class M3CoreDataManager
 Encapsulates all the usual CoreData management code for library apps, moving it out of your sight.
 */
@interface M3CoreDataManager : NSObject {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	NSString *initialType;
	NSString *appSupportName;
	NSURL *modelURL;
	NSURL *dataStoreURL;
	
	id delegate;
}

/**
 @property delegate
 The manager's delegate
 @since Available in M3CoreData 1.0 and later
 */
@property (assign) id delegate;

/**
 Initialises the manager with the supplied data
 <b>Discussion</b>
 This method does not create any of the core data object, these are created as needed upon their access
 @param type The store type for the persistent store
 @param subName The name of the application support folder
 @result mName The name of the model to use
 @result storeName The name of the data store to load
 @since Available in M3CoreData 1.0 and later
 */
- (id)initWithInitialType:(NSString *)type modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)storeURL;

/**
 Returns the persistent store coordinator, creating it if necessary
 @result Returns the persistent store coordinator
 @since Available in M3CoreData 1.0 and later
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

/**
 Returns the managed object model, creating it if necessary
 @result Returns the managed object model
 @since Available in M3CoreData 1.0 and later
 */
- (NSManagedObjectModel *)managedObjectModel;

/**
 Returns the managed object context, creating it if necessary
 @result Returns the managed object context
 @since Available in M3CoreData 1.0 and later
 */
- (NSManagedObjectContext *)managedObjectContext;

/**
 Attempts to save the data to disk, presenting an error if it fails
 @result Returns NSTerminateNow if successful, NSTerminateCancel if not
 @since Available in M3CoreData 1.0 and later
 */
- (NSApplicationTerminateReply)save;

@end


/**
 @category M3CoreDataManager(DelegateMethods)
 Delegate methods for M3CoreDataManager
 */
@interface M3CoreDataManager(DelegateMethods) 

/**
 Calls the delegate when the manager encounters a data store which doesn't match the correct model
 @param manager The core data manager
 @param idents A set of version identifiers for the store
 @since Available in M3CoreData 1.0 and later
 */
- (void)coreDataManager:(M3CoreDataManager *)manager encounteredIncorrectModelWithVersionIdentifiers:(NSSet *)idents;

@end