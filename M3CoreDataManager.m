/*****************************************************************
 M3CoreDataManager.m
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
#import "M3CoreDataManager.h"

@implementation M3CoreDataManager

@synthesize delegate;

- (id)initWithInitialType:(NSString *)type appSupportName:(NSString *)supName modelName:(NSString *)mName dataStoreName:(NSString *)storeName {
	NSAssert(NO, @"Called initWithInitialType:appSupportName:modelName:dataStoreName, should call initWithInitialType:modelURL:dataStoreURL:");
	return nil;
}


- (id)initWithInitialType:(NSString *)type modelURL:(NSURL *)aModelURL dataStoreURL:(NSURL *)storeURL {
	if ((self = [super init])) {
		initialType = type;
		if (!type) {
			initialType = NSXMLStoreType;
		}
		modelURL = aModelURL;
		dataStoreURL = storeURL;
	}
	return self;
}

/**
 Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "Minim" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */


- (NSString *)applicationSupportFolder {
	NSAssert(NO, @"Called applicationSupportFolder, should call applicationSupportFolderWithName:");
	return nil;
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *url;
    NSError *error;

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    if (![persistentStoreCoordinator addPersistentStoreWithType:initialType configuration:nil URL:dataStoreURL options:options error:&error]){
		if ([error code] == 134100) {
			//If we failed with an incorrect data model error then pass the version identifiers of the store to the delegate to decide what to do next
			if ([[self delegate] respondsToSelector:@selector(coreDataManager:encounteredIncorrectModelWithVersionIdentifiers:)]) {
				persistentStoreCoordinator = nil;
				NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:initialType URL:url error:&error];
				[[self delegate] coreDataManager:self encounteredIncorrectModelWithVersionIdentifiers:[metadata objectForKey:NSStoreModelVersionIdentifiersKey]];
			}
		} else {
			[[NSApplication sharedApplication] presentError:error];
		}
    }    
	
    return persistentStoreCoordinator;
}


/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
    if (!managedObjectContext) {
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator: coordinator];
		}
	}
    
    return managedObjectContext;
}



- (NSApplicationTerminateReply)save {
	NSError *error = nil;
	NSInteger reply = NSTerminateNow;
	NSManagedObjectContext *moc = [self managedObjectContext];
	if (moc != nil) {
		if ([moc commitEditing]) {
			if ([moc hasChanges] && ![moc save:&error]) {
				NSLog(@"%@", [[error userInfo] objectForKey:NSDetailedErrorsKey]);
				BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES) {
					reply = NSTerminateCancel;
				} else {
					NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
					if (alertReturn == NSAlertAlternateReturn) {
						reply = NSTerminateCancel;	
					}
				}
			}
		} else {
			reply = NSTerminateCancel;
		}
	}
	return reply;
}

@end
