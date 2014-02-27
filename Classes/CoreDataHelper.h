//
//  CoreDataHelper.h
//
//  Daniel Bowden
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign) BOOL loggingEnabled;

+ (CoreDataHelper *)sharedManager;

+ (void)initDataStorePath:(NSString *)path;
+ (void)saveContext;
+ (void)rollbackChanges;

//INSERTS
+ (id)insertObject:(NSString *)objectName;

//DELETES
+ (void)deleteObject:(id)object;

+ (void)deleteObjectsNamed:(NSString*)name;

+ (void)deleteObjectsNamed:(NSString *)name
                 predicate:(NSPredicate*)predicate;

//SELECTS
+ (NSArray *)selectObjectsNamed:(NSString *)name;

+ (NSArray *)selectObjectsNamed:(NSString*)name
                      predicate:(NSPredicate*)predicate;

+ (NSArray *)selectObjectsNamed:(NSString*)name
                      predicate:(NSPredicate*)predicate
                sortDescriptors:(NSArray*)sortDescriptors
                          limit:(int)limit;

+ (NSArray *)selectObjectsNamed:(NSString *)name
                        orderBy:(NSString *)order
                      ascending:(BOOL)asc;

+ (NSArray *)selectObjectsNamed:(NSString *)name
                      predicate:(NSPredicate *)predicate
                        orderBy:(NSString *)order
                      ascending:(BOOL)asc;

+ (NSManagedObject *)selectObjectNamed:(NSString *)name
                             predicate:(NSPredicate *)predicate
                               orderBy:(NSString *)order
                             ascending:(BOOL)asc;

+ (NSManagedObject *)selectObjectNamed:(NSString *)name
                             predicate:(NSPredicate *)predicate;

+ (NSManagedObject *)selectObjectNamed:(NSString *)name;

+ (NSManagedObject *)selectObjectNamed:(NSString *)name
                               orderBy:(NSString *)order
                             ascending:(BOOL)asc;

//COUNTS

+ (NSUInteger)countForObjectsNamed:(NSString *)name
                         predicate:(NSPredicate *)predicate;

+ (NSUInteger)countForObjectsNamed:(NSString *)name;


//FETCHED RESULTS CONTROLLERS

+ (NSFetchedResultsController *)fetchedResultsControllerForObjectNamed:(NSString *)name
                                                             predicate:(NSPredicate *)predicate
                                                       sortDescriptors:(NSArray *)sortDescriptors
                                                    sectionNameKeyPath:(NSString *)sectionName;


@end
