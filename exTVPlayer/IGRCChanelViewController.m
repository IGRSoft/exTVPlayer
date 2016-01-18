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

@property (weak, nonatomic  ) IBOutlet UICollectionView *catalogs;
@property (strong, nonatomic) UILabel *noContentLabel;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray<NSString*> *chanels;

@property (strong, nonatomic) NSIndexPath *lastSelectedItem;

@property (assign, nonatomic) IGRChanelMode chanelMode;

@property (copy,   nonatomic) NSString *liveSearchRequest;
@property (copy,   nonatomic) NSString *liveChanel;
@property (assign, nonatomic) NSInteger livePage;

@end

@implementation IGRCChanelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lastSelectedItem = [NSIndexPath indexPathForRow:0 inSection:0];
	
	CGFloat w = 1000.0;
	CGFloat h = 50.0;
	CGRect labelRect = CGRectMake((self.view.bounds.size.width - w) * 0.5,
								  (self.view.bounds.size.height - h) * 0.5, w, h);
	self.noContentLabel = [[UILabel alloc] initWithFrame:labelRect];
	self.noContentLabel.text = NSLocalizedString(@"No_Content", nil);
	self.noContentLabel.textAlignment = NSTextAlignmentCenter;
	self.noContentLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:32.0];
	self.noContentLabel.textColor = [UIColor darkGrayColor];
	self.noContentLabel.hidden = YES;
	
	[self.view addSubview:self.noContentLabel];
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
	
	if (catalog)
	{
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.lastSelectedItem.row + self.lastSelectedItem.section)];
		IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		[catalog setFavorit:[entityatalog.isFavorit boolValue]];
		[[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
	}
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

- (void)setChanel:(NSString *)aChanel
{
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];

	self.chanelMode = [settings.sourceType isEqualToNumber:@(IGRSourceType_RSS)] ? IGRChanelMode_Catalog : IGRChanelMode_Catalog_Live;
	
	if (self.chanelMode == IGRChanelMode_Catalog)
	{
		_chanels = [NSMutableArray arrayWithObject:aChanel];
		[IGREXParser parseChanelContent:aChanel];
	}
	else
	{
		_liveChanel = aChanel;
		_livePage = 0;
		_chanels = [NSMutableArray arrayWithArray:[IGREXParser parseLiveCatalog:self.liveChanel page:self.livePage]];
		
		[self asyncUpdate];
	}
}

- (void)setCatalog:(NSString *)aCatalog
{
	self.chanelMode = IGRChanelMode_Catalog_One;
	
	_chanels = [NSMutableArray arrayWithObject:aCatalog];
	[IGREXParser parseCatalogContent:aCatalog];
}

- (void)setSearchResult:(NSString *)aSearchRequest
{
	_liveSearchRequest = aSearchRequest;
	self.chanelMode = IGRChanelMode_Search;
	
	_liveChanel = @"0";
	_livePage = 0;
	_chanels = [NSMutableArray arrayWithArray:[IGREXParser parseLiveSearchContent:self.liveSearchRequest
																			 page:self.livePage
																		  catalog:self.liveChanel.integerValue]];
	
	[self asyncUpdate];
}

- (void)asyncUpdate
{
	NSUInteger count = self.chanels.count;
	__weak typeof(self) weak = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		[weak.chanels enumerateObjectsUsingBlock:^(NSString * _Nonnull chanel, NSUInteger idx, BOOL * _Nonnull stop) {
			
			if ([IGREXParser parseCatalogContent:chanel] || (idx + 1) == count)
			{
				dispatch_sync(dispatch_get_main_queue(), ^{
					
					[weak.fetchedResultsController performFetch:nil];
					[weak.catalogs reloadData];
				});
			}
		}];
	});
}

- (void)showFavorites
{
	self.chanelMode = IGRChanelMode_Favorites;
}

- (void)showHistory
{
	self.chanelMode = IGRChanelMode_History;
}

#pragma mark - Privat

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	
	if ([segue.identifier isEqualToString:@"openCatalog"])
	{
		IGRCatalogViewController *catalogViewController = segue.destinationViewController;
		
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalogs.indexPathsForSelectedItems.firstObject.row + self.catalogs.indexPathsForSelectedItems.firstObject.section)];
		IGREntityExCatalog *catalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setCatalogId:catalog.itemId];
		});
	}
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSUInteger count = [[self.fetchedResultsController sections] count];
	if (self.chanelMode == IGRChanelMode_History)
	{
		IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
		count = MIN(settings.historySize.integerValue, count);
	}
	
	self.noContentLabel.hidden = count > 0;
	
	return count;
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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.chanelMode == IGRChanelMode_Search || self.chanelMode == IGRChanelMode_Catalog_Live)
	{
		if ((indexPath.row + indexPath.section) == (self.chanels.count - 1) && self.livePage >= 0)
		{
			++self.livePage;
			
			NSArray *chanels = nil;
			
			if (self.chanelMode == IGRChanelMode_Search)
			{
				chanels = [NSMutableArray arrayWithArray:[IGREXParser parseLiveSearchContent:self.liveSearchRequest
																						 page:self.livePage
																					  catalog:self.liveChanel.integerValue]];
			}
			else
			{
				chanels = [IGREXParser parseLiveCatalog:self.liveChanel page:self.livePage];
			}
			
			if (chanels.count)
			{
				[_chanels addObjectsFromArray:chanels];
				self.fetchedResultsController = nil;
				[self asyncUpdate];
			}
			else
			{
				self.livePage = -1;
			}
		}
	}
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_Favorites)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorit == YES"];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															  withPredicate:predicate
																   sortedBy:@"orderId"
																  ascending:NO];
	}
	else if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_Catalog)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chanel.itemId == %@", self.chanels.firstObject];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															   withPredicate:predicate
																	sortedBy:@"orderId"
																   ascending:NO];
	}
	else if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_Catalog_One)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", self.chanels.firstObject];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															   withPredicate:predicate
																	sortedBy:@"orderId"
																   ascending:NO];
	}
	else if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_History)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"viewedTimestamp != nil"];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"viewedTimestamp"
															   withPredicate:predicate
																	sortedBy:@"viewedTimestamp"
																   ascending:NO];
	}
	else if (_fetchedResultsController == nil && (self.chanelMode == IGRChanelMode_Search || self.chanelMode == IGRChanelMode_Catalog_Live))
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId IN %@", self.chanels];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"orderId"
															   withPredicate:predicate
																	sortedBy:@"orderId"
																   ascending:YES];
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
			IGRCatalogCell *catalogCell = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:indexPath];
			if (catalogCell.isHighlighted)
			{
				NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0
															  inSection:(indexPath.row + indexPath.section)];
				IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
				
				entityatalog.isFavorit = @(!catalogCell.favorit);
				[catalogCell setFavorit:[entityatalog.isFavorit boolValue]];
				
				self.lastSelectedItem = indexPath;
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
					[catalogCell setHighlighted:YES];
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
