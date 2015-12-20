//
//  IGRCatalogViewControllerCollectionViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCChanelViewController.h"
#import "IGRCatalogViewController.h"

#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityAppSettings.h"

#import "IGRCatalogCell.h"

#import "IGREXParser.h"
#import <WebImage/WebImage.h>

@interface IGRCChanelViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *catalogs;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) IGREntityExChanel *chanel;

@property (strong, nonatomic) NSMutableArray *sectionChanges;
@property (strong, nonatomic) NSMutableArray *itemChanges;

@end

@implementation IGRCChanelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
//	NSIndexPath *dbIndexPath = [[self.catalogs indexPathsForSelectedItems] firstObject];
//	if (!dbIndexPath)
//	{
//		dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//	}
//	
//	IGRCatalogCell *cell = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:dbIndexPath];;
//
//	[self.catalogs selectItemAtIndexPath:dbIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
//	
//	[cell setHighlighted:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setSelected:NO];
	}];
	
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public

- (void)setChanel:(IGREntityExChanel *)aChanel
{
	_chanel = aChanel;
	[IGREXParser parseChanelContent:aChanel.itemId];
}

#pragma mark - Privat

- (IGREntityAppSettings*)appSettings
{
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
	if (!settings)
	{
		settings = [IGREntityAppSettings MR_createEntity];
		settings.videoLanguageId = @(IGRVideoCategory_Rus);
		
		[MR_DEFAULT_CONTEXT saveOnlySelfAndWait];
	}
	
	return settings;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	if ([segue.identifier isEqualToString:@"openCatalog"])
	{
		IGRCatalogViewController *catalogViewController = segue.destinationViewController;
		
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalogs.indexPathsForSelectedItems.firstObject.row + self.catalogs.indexPathsForSelectedItems.firstObject.section)];
		IGREntityExCatalog *catalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		IGREntityAppSettings *settings = [self appSettings];
		settings.lastPlayedCatalog = catalog.itemId;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setCatalogId:catalog.itemId];
		});
	}
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [[self.fetchedResultsController sections] count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	IGRCatalogCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IGRCatalogCell" forIndexPath:indexPath];
	
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
	IGREntityExCatalog *catalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	cell.title.text = catalog.name;
	[cell.image sd_setImageWithURL:[NSURL URLWithString:catalog.imgUrl]
				  placeholderImage:nil];
	
	return cell;
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{
	
	IGRCatalogCell *previouslyFocusedCell = (IGRCatalogCell *)context.previouslyFocusedView;
	IGRCatalogCell *nextFocusedCell = (IGRCatalogCell *)context.nextFocusedView;
	
	if ([previouslyFocusedCell isKindOfClass:[IGRCatalogCell class]])
	{
		[previouslyFocusedCell setHighlighted:NO];
	}
	
	if ([nextFocusedCell isKindOfClass:[IGRCatalogCell class]])
	{
		[nextFocusedCell setHighlighted:YES];
	}
	
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Selected item!");
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chanel.itemId == %@", self.chanel.itemId];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															  withPredicate:predicate
																   sortedBy:@"orderId"
																  ascending:NO];
	}
	
	return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_sectionChanges = [[NSMutableArray alloc] init];
	_itemChanges = [[NSMutableArray alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
	change[@(type)] = @(sectionIndex);
	[_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
	switch(type) {
		case NSFetchedResultsChangeInsert:
			change[@(type)] = newIndexPath;
			break;
		case NSFetchedResultsChangeDelete:
			change[@(type)] = indexPath;
			break;
		case NSFetchedResultsChangeUpdate:
			change[@(type)] = indexPath;
			break;
		case NSFetchedResultsChangeMove:
			change[@(type)] = @[indexPath, newIndexPath];
			break;
	}
	[_itemChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.catalogs performBatchUpdates:^{
		for (NSDictionary *change in _sectionChanges) {
			[change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSFetchedResultsChangeType type = [key unsignedIntegerValue];
				switch(type) {
					case NSFetchedResultsChangeInsert:
						[self.catalogs insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.catalogs deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
						break;
					default:
						break;
				}
			}];
		}
		for (NSDictionary *change in _itemChanges) {
			[change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSFetchedResultsChangeType type = [key unsignedIntegerValue];
				switch(type) {
					case NSFetchedResultsChangeInsert:
						[self.catalogs insertItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.catalogs deleteItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeUpdate:
						[self.catalogs reloadItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeMove:
						[self.catalogs moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
						break;
				}
			}];
		}
	} completion:^(BOOL finished) {
		_sectionChanges = nil;
		_itemChanges = nil;
	}];
}

@end
