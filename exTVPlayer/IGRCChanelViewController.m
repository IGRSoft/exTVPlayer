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

@interface IGRCChanelViewController () <NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *catalogs;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) IGREntityExChanel *chanel;

@property (strong, nonatomic) NSIndexPath *lastSelectedItem;

@property (assign, nonatomic) BOOL isShowFavorit;

@end

@implementation IGRCChanelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lastSelectedItem = [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
										  initWithTarget:self action:@selector(handleLongPress:)];
	lpgr.minimumPressDuration = 1.0; //seconds
	lpgr.delegate = self;
	[self.catalogs addGestureRecognizer:lpgr];
	
	IGRCatalogCell *catalog = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem];
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.lastSelectedItem.row + self.lastSelectedItem.section)];
	IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	[catalog setFavorit:[entityatalog.isFavorit boolValue]];
	[[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setSelected:NO];
	}];
	
	for (UIGestureRecognizer *gr in self.catalogs.gestureRecognizers)
	{
		[self.catalogs removeGestureRecognizer:gr];
	}
	
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
	self.isShowFavorit = NO;
	_chanel = aChanel;
	[IGREXParser parseChanelContent:aChanel.itemId];
}

- (void)showFavorit
{
	self.isShowFavorit = YES;
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	
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
	
	[cell setFavorit:[catalog.isFavorit boolValue]];
	
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
	self.lastSelectedItem = indexPath;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil && self.isShowFavorit)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorit == YES"];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															  withPredicate:predicate
																   sortedBy:@"orderId"
																  ascending:NO];
	}
	else if (_fetchedResultsController == nil && !self.isShowFavorit)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chanel.itemId == %@", self.chanel.itemId];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															   withPredicate:predicate
																	sortedBy:@"orderId"
																   ascending:NO];
	}
	
	return _fetchedResultsController;
}

#pragma mark - UIGestureRecognizerDelegate

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		NSIndexPath *indexPath = nil;
		for (indexPath in [self.catalogs indexPathsForVisibleItems])
		{
			IGRCatalogCell *catalog = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:indexPath];
			if (catalog.isHighlighted)
			{
				NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
				IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
				
				entityatalog.isFavorit = @(!catalog.favorit);
				[catalog setFavorit:[entityatalog.isFavorit boolValue]];
				
				self.lastSelectedItem = indexPath;
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
					[[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
				});
				
				break;
			}
			else
			{
				indexPath = nil;
			}
		}
	}
}

@end
