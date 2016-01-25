//
//  IGRCatalogViewControllerCollectionViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCChanelViewController.h"
#import "IGRCChanelViewController_Private.h"

#import "IGRCatalogViewController.h"

#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityAppSettings.h"

#import "IGRCatalogCell.h"

#import "IGREXParser.h"
#import <WebImage/WebImage.h>

@interface IGRCChanelViewController () <NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) UILabel *noContentLabel;
@property (strong, nonatomic) UIActivityIndicatorView *parsingActivityIndicator;

@property (weak,   nonatomic) IBOutlet UICollectionView *catalogs;
@property (strong, nonatomic) NSIndexPath *lastSelectedItem;

@property (strong, nonatomic) NSMutableArray<NSString*> *chanels;

@property (copy,   nonatomic) NSString *liveSearchRequest;
@property (copy,   nonatomic) NSString *liveChanel;
@property (assign, nonatomic) NSInteger livePage;

@property (assign, nonatomic) NSUInteger catalogCount;

@property (assign, nonatomic) BOOL hasSomeData;
@property (assign, nonatomic) BOOL updateInProgress;
@property (assign, nonatomic) BOOL waitingDoneUpdate;

@property (strong, nonatomic) NSTimer *refreshTimer;
@property (assign, atomic   ) BOOL needRefresh;

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
	
	self.parsingActivityIndicator = [[UIActivityIndicatorView alloc]
									 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	self.parsingActivityIndicator.color = IGR_DARKBLUECOLOR;
	self.parsingActivityIndicator.center = self.view.center;
	self.parsingActivityIndicator.hidden = YES;
	self.parsingActivityIndicator.hidesWhenStopped = YES;
	
	[self.view addSubview:self.parsingActivityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.needHighlightCell = YES;
	self.updateInProgress = NO;
	self.waitingDoneUpdate = NO;
	
	self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1
												  target:self
												selector:@selector(refreshTimerExceeded)
												userInfo:nil
												 repeats:YES];
	
	[super viewWillAppear:animated];
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
	
	if (self.needHighlightCell && catalog)
	{
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0
													  inSection:(self.lastSelectedItem.row + self.lastSelectedItem.section)];
		IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		catalog.favorit = (entityatalog.isFavorit).boolValue;
		[[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem] setHighlighted:YES];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(IGRCatalogCell *obj, NSUInteger idx, BOOL *stop) {
		
		[obj setSelected:NO];
		[obj setHighlighted:NO];
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
	self.onceToken = 0;
	
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];

	self.chanelMode = [settings.sourceType isEqualToNumber:@(IGRSourceType_RSS)] ? IGRChanelMode_Catalog :
																				   IGRChanelMode_Catalog_Live;
	
	if (self.chanelMode == IGRChanelMode_Catalog)
	{
		__weak typeof(self) weak = self;
		_chanels = [NSMutableArray arrayWithObject:aChanel];
		[IGREXParser parseChanelContent:aChanel compleateBlock:^(NSArray *items) {
			
			[weak.fetchedResultsController performFetch:nil];
			[weak showParsingProgress:NO];
			
			[weak.catalogs reloadData];
		}];
	}
	else
	{
		_liveChanel = aChanel;
		_livePage = 0;
		__weak typeof(self) weak = self;
		[IGREXParser parseLiveCatalog:self.liveChanel page:self.livePage compleateBlock:^(NSArray *items) {
			
			NSUInteger startPosition = weak.chanels.count;
			weak.chanels = [NSMutableArray arrayWithArray:items];
			[weak asyncUpdateFromPosition:startPosition];
		}];
	}
}

- (void)setCatalog:(NSString *)aCatalog
{
	self.chanelMode = IGRChanelMode_Catalog_One;
	
	__weak typeof(self) weak = self;
	_chanels = [NSMutableArray arrayWithObject:aCatalog];
	[IGREXParser parseCatalogContent:aCatalog compleateBlock:^(NSArray *items) {
		
		[weak.fetchedResultsController performFetch:nil];
	}];
}

- (void)setSearchResult:(NSString *)aSearchRequest
{
	_liveSearchRequest = aSearchRequest;
	self.chanelMode = IGRChanelMode_Search;
	
	_liveChanel = @"0";
	_livePage = 0;
	__weak typeof(self) weak = self;
	[IGREXParser parseLiveSearchContent:self.liveSearchRequest
								   page:self.livePage
								catalog:self.liveChanel.integerValue
						 compleateBlock:^(NSArray *items) {
							 
							 NSUInteger startPosition = weak.chanels.count;
							 weak.chanels = [NSMutableArray arrayWithArray:items];
							 [weak asyncUpdateFromPosition:startPosition];
						 }];
}

- (void)asyncUpdateFromPosition:(NSUInteger)startPosition
{
	self.updateInProgress = YES;
	
	NSUInteger count = self.chanels.count;
	__block NSUInteger position = startPosition;
	__block NSUInteger parsePosition = 0;
	__weak typeof(self) weak = self;
	
	NSArray *chanelsRange = [self.chanels subarrayWithRange:NSMakeRange(startPosition, count - startPosition)];
	
	if (chanelsRange.count)
	{
		[chanelsRange enumerateObjectsUsingBlock:^(NSString * _Nonnull chanel, NSUInteger idx, BOOL * _Nonnull stop) {
			
			[IGREXParser parseCatalogContent:chanel
							  compleateBlock:^(NSArray *items)
			{
				weak.hasSomeData = [weak.fetchedResultsController performFetch:nil];

				if ((parsePosition != 0 && (parsePosition % 20) == 0) || (parsePosition + 1) == count)
				{
					weak.hasSomeData = [weak.fetchedResultsController performFetch:nil];
					
					if (position == startPosition)
					{
						[weak showParsingProgress:NO];
						weak.needRefresh = YES;
					}
					else
					{
						weak.needRefresh = YES;
					}
					
					IGRCatalogCell *catalogCell = (IGRCatalogCell *)[weak.catalogs cellForItemAtIndexPath:weak.lastSelectedItem];

					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
						
						[catalogCell setHighlighted:YES];
					});
					
					position = startPosition + parsePosition;
				}
				
				if ((++parsePosition + 1) == count)
				{
					weak.updateInProgress = NO;
				}
			}];
		}];
	}
	else
	{
		[weak showParsingProgress:NO];
	}
}

#pragma mark - Privat

- (void)showParsingProgress:(BOOL)show
{
	if (self.hasSomeData)
	{
		[self.parsingActivityIndicator stopAnimating];
		self.noContentLabel.hidden = YES;
	}
	else
	{
		if (show)
		{
			[self.parsingActivityIndicator startAnimating];
		}
		else
		{
			[self.parsingActivityIndicator stopAnimating];
			self.noContentLabel.hidden = NO;
		}
	}
}

- (void)refreshTimerExceeded
{
	if (self.needRefresh)
	{
		[self.catalogs reloadData];
		_needRefresh = NO;
	}
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
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setCatalogId:catalog.itemId];
		});
	}
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
	if ([context.nextFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")])
	{
		[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(IGRCatalogCell *obj, NSUInteger idx, BOOL *stop) {
			
			[obj setHighlighted:NO];
		}];
	}
	else if ([context.previouslyFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")]
			 && [context.nextFocusedView isKindOfClass:[IGRCatalogCell class]])
	{
		[(IGRCatalogCell *)context.nextFocusedView setHighlighted:YES];
	}
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	self.catalogCount = (self.fetchedResultsController).sections.count;
	self.hasSomeData = self.catalogCount > 0;
	
	dispatch_once(&_onceToken, ^{

		[self showParsingProgress:YES];
	});
	
	if (self.chanelMode == IGRChanelMode_History)
	{
		IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
		self.catalogCount = MIN(settings.historySize.integerValue, self.catalogCount);
	}
	
	return self.catalogCount;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	IGRCatalogCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IGRCatalogCell"
																	 forIndexPath:indexPath];
	
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
	IGREntityExCatalog *catalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	cell.title.text = catalog.name;
	[cell.image sd_setImageWithURL:[NSURL URLWithString:catalog.imgUrl]
				  placeholderImage:nil];
	
	cell.favorit = (catalog.isFavorit).boolValue;
	
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
		
		self.lastSelectedItem = [self.catalogs indexPathForCell:nextFocusedCell];
	}
	
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	self.lastSelectedItem = indexPath;
}

- (void)collectionView:(UICollectionView *)collectionView
	   willDisplayCell:(UICollectionViewCell *)cell
	forItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.chanelMode == IGRChanelMode_Search || self.chanelMode == IGRChanelMode_Catalog_Live)
	{
		if ((indexPath.row + indexPath.section) == (self.catalogCount - 10
													) && self.livePage >= 0)
		{
			if (self.updateInProgress && self.waitingDoneUpdate)
			{
				return;
			}
			else if (!self.waitingDoneUpdate)
			{
				self.waitingDoneUpdate = YES;
				[self tryUpdateData];
			}
		}
	}
}

- (void)tryUpdateData
{
	if (self.updateInProgress)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self tryUpdateData];
		});
	}
	else
	{
		++self.livePage;
		
		__weak typeof(self) weak = self;
		void (^updateChanels)(NSArray *) = ^(NSArray *items)
		{
			if (items.count)
			{
				NSUInteger startPosition = weak.catalogCount;
				
				[weak.chanels addObjectsFromArray:items];
				weak.fetchedResultsController = nil;
				weak.catalogCount = 0;
				
				[weak.fetchedResultsController performFetch:nil];
				
				[weak asyncUpdateFromPosition:startPosition];
			}
			else
			{
				weak.livePage = -1;
			}
			
			weak.waitingDoneUpdate = NO;
		};
		
		if (self.chanelMode == IGRChanelMode_Search)
		{
			[IGREXParser parseLiveSearchContent:self.liveSearchRequest
										   page:self.livePage
										catalog:self.liveChanel.integerValue
								 compleateBlock:updateChanels];
		}
		else
		{
			[IGREXParser parseLiveCatalog:self.liveChanel page:self.livePage compleateBlock:updateChanels];
		}
	}
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (!self.chanels.count)
	{
		return nil;
	}
	
	if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_Catalog)
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
	else if (_fetchedResultsController == nil && (self.chanelMode == IGRChanelMode_Search ||
												  self.chanelMode == IGRChanelMode_Catalog_Live))
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
				catalogCell.favorit = (entityatalog.isFavorit).boolValue;
				
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
