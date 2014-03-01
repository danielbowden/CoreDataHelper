//
//  CoreDataHelper.m
//
//  Daniel Bowden
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper

static CoreDataHelper *coreDataInstance = nil;
static NSString *datastorePath = nil;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (CoreDataHelper *)sharedManager
{
    @synchronized(self)
    {
        if (datastorePath == nil)
        {
            NSLog(@"No DatastorePath has been set for CoreDataHelper");
            abort();
        }
        
        if (coreDataInstance == nil)
        {
            coreDataInstance = [[self alloc] init];
            coreDataInstance.loggingEnabled = NO;
        }
    }
    return coreDataInstance;
}

+ (void) initDataStorePath:(NSString *)path
{
    datastorePath = path;
}

#pragma mark - Core Data Stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    @synchronized(self)
    {
        if (_managedObjectContext != nil)
        {
            return _managedObjectContext;
        }
        
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil)
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];   
        }
        return _managedObjectContext;
    }
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    @synchronized(self)
    {
        if (_managedObjectModel != nil)
        {
            return _managedObjectModel;
        }
        
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:datastorePath withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        return _managedObjectModel;
    }
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    @synchronized(self)
    {
        if (_persistentStoreCoordinator != nil)
        {
            return _persistentStoreCoordinator;
        }
        
        NSURL *documentsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        
        NSURL *storeURL = [documentsDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", datastorePath]];
        NSError *error = nil;
        
              NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        {
            if (_loggingEnabled)
            {
                NSLog(@"Unresolved PersistentStoreCoordinator error %@, %@", error, [error userInfo]);
            }
            abort();
        }
        return _persistentStoreCoordinator;
    }
}

#pragma mark - Datastore interaction.

+ (void)saveContext
{
    NSError *error = nil;
    
    if ([[CoreDataHelper sharedManager] managedObjectContext] != nil)
    {
        if ([[[CoreDataHelper sharedManager] managedObjectContext] hasChanges] && ![[[CoreDataHelper sharedManager] managedObjectContext] save:&error])
        {
            if ([[CoreDataHelper sharedManager] loggingEnabled])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
            abort();
        }
    }

}

+ (void)rollbackChanges
{
    if ([[CoreDataHelper sharedManager] managedObjectContext] != nil)
    {
        [[[CoreDataHelper sharedManager] managedObjectContext] rollback];
    }
}

#pragma mark - INSERTS

+ (id)insertObject:(NSString *)objectName
{
    return [NSEntityDescription insertNewObjectForEntityForName:objectName inManagedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext]];
}

#pragma mark - DELETES

+ (void)deleteObject:(id)object
{
    [[[CoreDataHelper sharedManager] managedObjectContext] deleteObject:object];
}

+ (void)deleteObjectsNamed:(NSString *)name
{
    [CoreDataHelper deleteObjectsNamed:name predicate:nil];
}

+ (void)deleteObjectsNamed:(NSString *)name predicate:(NSPredicate *)predicate
{
    NSArray *matches = [CoreDataHelper selectObjectsNamed:name predicate:predicate];
    
    for (id obj in matches)
    {
        [CoreDataHelper deleteObject:obj];
    }
}

#pragma mark - SELECTS

+ (NSArray *)selectObjectsNamed:(NSString *)name predicate:(NSPredicate *)predicate
{
    return [CoreDataHelper selectObjectsNamed:name predicate:predicate sortDescriptors:nil limit:0];
}

+ (NSArray *)selectObjectsNamed:(NSString *)name
{
    return [CoreDataHelper selectObjectsNamed:name predicate:nil sortDescriptors:nil limit:0];
}

+ (NSArray *)selectObjectsNamed:(NSString *)name predicate:(NSPredicate *)predicate orderBy:(NSString *)order ascending:(BOOL)asc
{
    NSArray *sortDescriptors = nil;
    
    if (order != nil && order.length)
    {
        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:order ascending:asc];
        sortDescriptors = [NSArray arrayWithObject:sortDesc];
    }
    
    return [CoreDataHelper selectObjectsNamed:name predicate:predicate sortDescriptors:sortDescriptors limit:0];
}

+ (NSArray *)selectObjectsNamed:(NSString *)name orderBy:(NSString *)order ascending:(BOOL)asc
{
    return [CoreDataHelper selectObjectsNamed:name predicate:nil orderBy:order ascending:asc];
}

+ (NSArray *)selectObjectsNamed:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors limit:(int)limit
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors != nil && sortDescriptors.count)
    {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    if (limit > 0)
    {
        [fetchRequest setFetchLimit:limit];
    }
    
    NSError *error;
    NSArray *matches;
    
    if (!(matches = [[[CoreDataHelper sharedManager] managedObjectContext] executeFetchRequest:fetchRequest error:&error]))
    {
        if ([[CoreDataHelper sharedManager] loggingEnabled])
        {
            NSLog(@"Core Data Fetch Request Failed: %@, %@", error, [error userInfo]);
        }
    }
    
    return matches;
}

+ (NSManagedObject *)selectObjectNamed:(NSString *)name predicate:(NSPredicate *)predicate orderBy:(NSString *)order ascending:(BOOL)asc
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }

    if (order != nil && order.length)
    {
        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:order ascending:asc];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    }
    
    [fetchRequest setFetchLimit:1];
    
    NSError *error;
    NSArray *matches;

    if (!(matches = [[[CoreDataHelper sharedManager] managedObjectContext] executeFetchRequest:fetchRequest error:&error]))
    {
        if ([[CoreDataHelper sharedManager] loggingEnabled])
        {
            NSLog(@"Core Data Fetch Request Failed: %@, %@", error, [error userInfo]);
        }
    }
    
    if (matches.count)
    {
        return [matches objectAtIndex:0];
    }
    else
    {
        return nil;
    }
}

+ (NSManagedObject *)selectObjectNamed:(NSString *)name predicate:(NSPredicate *)predicate
{
    return [CoreDataHelper selectObjectNamed:name predicate:predicate orderBy:nil ascending:NO];
}

+ (NSManagedObject *)selectObjectNamed:(NSString *)name
{
    return [CoreDataHelper selectObjectNamed:name predicate:nil orderBy:nil ascending:NO];
}

+ (NSManagedObject *)selectObjectNamed:(NSString *)name orderBy:(NSString *)order ascending:(BOOL)asc
{
    return [CoreDataHelper selectObjectNamed:name predicate:nil orderBy:order ascending:asc];
}

#pragma mark - COUNTS

+ (NSUInteger)countForObjectsNamed:(NSString *)name includeSubentities:(BOOL)includeSubentities
{
    return [CoreDataHelper countForObjectsNamed:name predicate:nil includeSubentities:includeSubentities];
}

+ (NSUInteger)countForObjectsNamed:(NSString *)name predicate:(NSPredicate *)predicate includeSubentities:(BOOL)includeSubentities
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext]];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:includeSubentities];
    
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
    
    NSError *error;
    NSUInteger count = [[[CoreDataHelper sharedManager] managedObjectContext] countForFetchRequest:fetchRequest error:&error];
    
    if (count == NSNotFound)
    {
        if ([[CoreDataHelper sharedManager] loggingEnabled])
        {
            NSLog(@"Core Data Count Fetch Request Failed: %@, %@", error, [error userInfo]);
        }
    }
    
    return count;
}

#pragma mark - FETCHED RESULTS CONTROLLERS

+ (NSFetchedResultsController *)fetchedResultsControllerForObjectNamed:(NSString *)name predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors sectionNameKeyPath:(NSString *)sectionName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    //only fetch a subset, fetching more as we scroll
    [fetchRequest setFetchBatchSize:20];
    
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors != nil && sortDescriptors.count)
    {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[CoreDataHelper sharedManager] managedObjectContext] sectionNameKeyPath:sectionName cacheName:nil];
    
    return controller;
}

@end
