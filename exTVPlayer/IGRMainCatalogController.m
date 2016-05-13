//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRMainCatalogController.h"
#import "IGRChanelViewController.h"

#import "IGREXParser.h"
#import "IGREntityExChanel.h"

#import "IGRCollectionCell.h"

#if	TARGET_OS_IOS
#import "SDiOSVersion.h"
#endif

@interface IGRMainCatalogController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *chanels;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *sectionChanges;
@property (strong, nonatomic) NSMutableArray *itemChanges;

@property (strong, nonatomic) NSIndexPath *lastSelectedItem;
@property (strong, nonatomic) NSNumber *lastVideoCatalog;

@end

@implementation IGRMainCatalogController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// create settings
	[self appSettings];
	
	self.chanels.backgroundColor = [UIColor clearColor];
	self.lastSelectedItem = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *langId = settings.videoLanguageId;
	
	if (![self.lastVideoCatalog isEqualToNumber:langId])
	{
		self.lastVideoCatalog = langId;
		
		__weak typeof(self) weak = self;
		
		[IGREXParser parseLiveVideoCatalogContent:langId.stringValue compleateBlock:^(NSArray * _Nullable items) {
			
			[IGREXParser parseVideoCatalogContent:langId.stringValue compleateBlock:^(NSArray *_Nullable items) {
				
				weak.fetchedResultsController = nil;
				weak.lastSelectedItem = nil;
				
				[weak.chanels reloadData];
			}];
		}];
		
	}
	else if (self.lastSelectedItem)
	{
#if	TARGET_OS_TV
		[[self.chanels cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
#endif
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.chanels.visibleCells enumerateObjectsUsingBlock:^(IGRCollectionCell *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setSelected:NO];
		[obj setHighlighted:NO];
	}];
	
	[super viewWillDisappear:animated];
}

- (UIView *)preferredFocusedView
{
	return self.chanels;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Public

#pragma mark - Privat

#if	TARGET_OS_TV
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
	   withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
	if ([context.nextFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")])
	{
		[self deselectVisibleCells];
	}
	else if ([context.previouslyFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")]
			 && [context.nextFocusedView isKindOfClass:[IGRCollectionCell class]])
	{
		[self deselectVisibleCells];
		[(IGRCollectionCell *)context.nextFocusedView setHighlighted:YES];
	}
}
#endif

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showChanel"])
	{
		IGRChanelViewController *catalogViewController = segue.destinationViewController;
		
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0
													  inSection:(self.chanels.indexPathsForSelectedItems.firstObject.row + self.chanels.indexPathsForSelectedItems.firstObject.section)];
		IGREntityExChanel *chanel = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setChanel:chanel.itemId];
		});
	}
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (self.fetchedResultsController).sections.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	IGRCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IGRCollectionCell"
																	   forIndexPath:indexPath];
	
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
	IGREntityExChanel *track = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	cell.title.text = track.name;
	
	return cell;
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

#if	TARGET_OS_TV
- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{	
	IGRCollectionCell *previouslyFocusedCell = (IGRCollectionCell *)context.previouslyFocusedView;
	IGRCollectionCell *nextFocusedCell = (IGRCollectionCell *)context.nextFocusedView;
	
	if ([previouslyFocusedCell isKindOfClass:[IGRCollectionCell class]])
	{
		[previouslyFocusedCell setHighlighted:NO];
	}
	
	if ([nextFocusedCell isKindOfClass:[IGRCollectionCell class]])
	{
		[self deselectVisibleCells];
		[nextFocusedCell setHighlighted:YES];		
	}
	
	return YES;
}

- (void)deselectVisibleCells
{
	[self.chanels.visibleCells enumerateObjectsUsingBlock:^(IGRCollectionCell *obj, NSUInteger idx, BOOL *stop) {
		
		[obj setHighlighted:NO];
	}];
}
#endif

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	self.lastSelectedItem = indexPath;
}

#if	TARGET_OS_IOS
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section
{
	CGFloat left = 10.0;
	CGFloat right = 10.0;
	
	switch ([SDiOSVersion deviceSize])
	{
		case Screen3Dot5inch:
		case Screen4inch:
		{
			left = 10.0;
			right = 10.0;
		}
			break;
		case Screen5Dot5inch:
		{
			left = 35.0;
			right = 35.0;
		}
			break;
		case Screen4Dot7inch:
		{
			left = 35.0;
			right = 35.0;
		}
			break;
		case UnknownSize:
		{
			left = 35.0;
			right = 35.0;
		}
			break;
	}
	
	return UIEdgeInsetsMake(10.0, left, 10.0, right);
}
#endif

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil)
	{
		IGREntityAppSettings *settings = [self appSettings];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoCatalog.itemId == %@", settings.videoLanguageId];
		_fetchedResultsController = [IGREntityExChanel MR_fetchAllGroupedBy:@"name"
															 withPredicate:predicate
																  sortedBy:@"name"
																 ascending:YES];
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
	[self.chanels performBatchUpdates:^{
		for (NSDictionary *change in _sectionChanges) {
			[change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSFetchedResultsChangeType type = [key unsignedIntegerValue];
				switch(type) {
					case NSFetchedResultsChangeInsert:
						[self.chanels insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.chanels deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
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
						[self.chanels insertItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeDelete:
						[self.chanels deleteItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeUpdate:
						[self.chanels reloadItemsAtIndexPaths:@[obj]];
						break;
					case NSFetchedResultsChangeMove:
						[self.chanels moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
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
