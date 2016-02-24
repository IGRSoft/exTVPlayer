//
//  IGRCatalogViewControllerCollectionViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/19/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRChanelViewController.h"
#import "IGRChanelViewController_Private.h"

#import "IGRCatalogViewController.h"

#import "IGREntityExChanel.h"
#import "IGREntityExCatalog.h"
#import "IGREntityAppSettings.h"

#import "IGRCatalogCell.h"

#import "IGREXParser.h"
#import <WebImage/WebImage.h>

#if	TARGET_OS_IOS
#import "SDiOSVersion.h"
#endif

@interface IGRChanelViewController () <NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) UILabel *noContentLabel;
@property (strong, nonatomic) UIActivityIndicatorView *parsingActivityIndicator;

@property (strong, nonatomic) UINavigationBar *navigationBar;
@property (strong, nonatomic) UINavigationItem *navigationItem;

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

@implementation IGRChanelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.lastSelectedItem = [NSIndexPath indexPathForRow:0 inSection:0];
	
	CGFloat w = self.view.bounds.size.width;
	CGFloat h = self.view.bounds.size.height;
	CGRect labelRect = CGRectMake(0.0, 0.0, w, h);
	
	self.noContentLabel = [[UILabel alloc] initWithFrame:labelRect];
	self.noContentLabel.text = NSLocalizedString(@"No_Content", nil);
	self.noContentLabel.textAlignment = NSTextAlignmentCenter;
	self.noContentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	self.noContentLabel.textColor = [UIColor darkGrayColor];
	self.noContentLabel.hidden = YES;
	
	[self.view addSubview:self.noContentLabel];
	
	self.parsingActivityIndicator = [[UIActivityIndicatorView alloc]
									 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	self.parsingActivityIndicator.color = IGR_DARKBLUECOLOR;
	self.parsingActivityIndicator.center = self.view.center;
	self.parsingActivityIndicator.hidesWhenStopped = YES;
	[self.parsingActivityIndicator stopAnimating];
	[self.view addSubview:self.parsingActivityIndicator];
	
#if	TARGET_OS_IOS
	
	self.noContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.parsingActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
	
	if ([self isMemberOfClass:[IGRChanelViewController class]])
	{
		CGSize viewSize = self.view.frame.size;
		
		self.navigationBar = [[UINavigationBar alloc] initWithFrame:
								   CGRectMake(0, 0, viewSize.width, 70.0)];
		self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self.view addSubview:self.navigationBar];
		
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
																	   style:UIBarButtonItemStylePlain
																	  target:self action:@selector(onTouchBack:)];
		
		self.navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
		self.navigationItem.leftBarButtonItem = backButton;
		
		[self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
		
		NSDictionary *viewsDictionary = @{@"navigationBar":self.navigationBar};
		[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navigationBar]|"
																		  options:0
																		  metrics:nil
																			views:viewsDictionary]];
		
		// height view
		[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[navigationBar(==70)]"
																				   options:0
																				   metrics:nil
																					 views:viewsDictionary]];
	}
	
	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
										  initWithTarget:self action:@selector(handleLongPress:)];
	lpgr.minimumPressDuration = 1.0; //seconds
	lpgr.delegate = self;
	[self.catalogs addGestureRecognizer:lpgr];

	// Center horizontally
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noContentLabel
														  attribute:NSLayoutAttributeCenterX
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.view
														  attribute:NSLayoutAttributeCenterX
														 multiplier:1.0
														   constant:0.0]];
	
	// Center vertically
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noContentLabel
														  attribute:NSLayoutAttributeCenterY
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.view
														  attribute:NSLayoutAttributeCenterY
														 multiplier:1.0
														   constant:0.0]];
	
	// Center horizontally
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.parsingActivityIndicator
														  attribute:NSLayoutAttributeCenterX
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.view
														  attribute:NSLayoutAttributeCenterX
														 multiplier:1.0
														   constant:0.0]];
	
	// Center vertically
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.parsingActivityIndicator
														  attribute:NSLayoutAttributeCenterY
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.view
														  attribute:NSLayoutAttributeCenterY
														 multiplier:1.0
														   constant:0.0]];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
#if	TARGET_OS_TV
	self.needHighlightCell = YES;
#else
	self.needHighlightCell = NO;
#endif
	self.updateInProgress = NO;
	self.waitingDoneUpdate = NO;
	
	self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:2
												  target:self
												selector:@selector(refreshTimerExceeded)
												userInfo:nil
												 repeats:YES];
	
#if	TARGET_OS_TV
	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
										  initWithTarget:self action:@selector(handleLongPress:)];
	lpgr.minimumPressDuration = 1.0; //seconds
	lpgr.delegate = self;
	[self.catalogs addGestureRecognizer:lpgr];
#endif
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGRCatalogCell *catalog = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem];
	
	if (self.needHighlightCell && catalog)
	{
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0
													  inSection:(self.lastSelectedItem.row + self.lastSelectedItem.section)];
		IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		catalog.favorit = (entityatalog.isFavorit).boolValue;
		[catalog setHighlighted:YES];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
#if	TARGET_OS_TV
	for (UIGestureRecognizer *gr in self.catalogs.gestureRecognizers)
	{
		[self.catalogs removeGestureRecognizer:gr];
	}
#endif

	[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(IGRCatalogCell *obj, NSUInteger idx, BOOL *stop) {
		
		[obj setSelected:NO];
		[obj setHighlighted:NO];
	}];
	
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
#if	TARGET_OS_IOS
	for (UIGestureRecognizer *gr in self.catalogs.gestureRecognizers)
	{
		[self.catalogs removeGestureRecognizer:gr];
	}
#endif
}

#pragma mark - Public

- (void)setChanel:(NSString *)aChanel
{
	self.onceToken = 0;
	
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];

	self.chanelMode = [settings.sourceType isEqualToNumber:@(IGRSourceType_RSS)] ? IGRChanelMode_Catalog :
																				   IGRChanelMode_Catalog_Live;
	
	IGREntityExChanel *chanel = [IGREntityExChanel MR_findFirstByAttribute:@"itemId" withValue:aChanel];
	[self updateTitleCorCatalog:chanel.name];
	
	if (self.chanelMode == IGRChanelMode_Catalog)
	{
		__weak typeof(self) weak = self;
		_chanels = [NSMutableArray arrayWithObject:aChanel];
		[IGREXParser parseChanelContent:aChanel compleateBlock:^(NSArray *items) {
			
			weak.hasSomeData = [weak.fetchedResultsController performFetch:nil];
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
		[weak.catalogs reloadData];
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
								catalog:self.liveChanel
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

					position = startPosition + parsePosition;
				}
				
				++parsePosition;
			}];
		}];
		
		self.updateInProgress = NO;
	}
	else
	{
		[self showParsingProgress:NO];
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

- (void)reloadData
{
	[self.fetchedResultsController performFetch:nil];
	[self.catalogs reloadData];
}

- (void)refreshTimerExceeded
{
	if (self.needRefresh)
	{
		[self.catalogs reloadData];
		_needRefresh = NO;
		
		[self deselectVisibleCells];
#if	TARGET_OS_TV
		IGRCatalogCell *catalogCell = (IGRCatalogCell *)[self.catalogs cellForItemAtIndexPath:self.lastSelectedItem];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[catalogCell setHighlighted:YES];
		});
#endif
	}
}

- (void)deselectVisibleCells
{
	[self.catalogs.visibleCells enumerateObjectsUsingBlock:^(IGRCatalogCell *obj, NSUInteger idx, BOOL *stop) {
		
		[obj setHighlighted:NO];
	}];
}

- (void)updateTitleCorCatalog:(NSString *)aTitle
{
#if	TARGET_OS_IOS
	
	if (self.navigationItem.title.length)
	{
		return;
	}
	
	self.navigationItem.title = aTitle;
	
#endif
}

- (IBAction)onTouchBack:(UIButton *)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
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

#if	TARGET_OS_TV
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
	if ([context.nextFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")])
	{
		[self deselectVisibleCells];
	}
	else if ([context.previouslyFocusedView isKindOfClass:NSClassFromString(@"UITabBarButton")]
			 && [context.nextFocusedView isKindOfClass:[IGRCatalogCell class]])
	{
		[self deselectVisibleCells];
		[(IGRCatalogCell *)context.nextFocusedView setHighlighted:YES];
	}
}
#endif

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

#if	TARGET_OS_TV
	if (self.catalogCount)
	{
		__weak typeof(self) weak = self;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			if (weak.needHighlightCell)
			{
				weak.needHighlightCell = NO;
				IGRCatalogCell *catalog = (IGRCatalogCell *)[weak.catalogs cellForItemAtIndexPath:weak.lastSelectedItem];
				
				if (catalog)
				{
					NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0
																  inSection:section];
					IGREntityExCatalog *entityatalog = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
					
					catalog.favorit = (entityatalog.isFavorit).boolValue;
					[catalog setHighlighted:YES];
				}
			}
		});
	}
#endif
	
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
	
	cell.tag = catalog.itemId.integerValue;
	cell.title.text = catalog.name;
	[cell.image sd_setImageWithURL:[NSURL URLWithString:catalog.imgUrl]
				  placeholderImage:nil];
	
	cell.favorit = (catalog.isFavorit).boolValue;
	
	return cell;
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

#if	TARGET_OS_TV
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
		[self deselectVisibleCells];
		[nextFocusedCell setHighlighted:YES];
		
		self.lastSelectedItem = [self.catalogs indexPathForCell:nextFocusedCell];
	}
	
	return YES;
}
#endif

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
		if ((indexPath.row + indexPath.section) == (self.catalogCount - 4
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

#if	TARGET_OS_IOS
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section
{
	CGFloat left = 20.0;
	CGFloat right = 20.0;
	
	switch ([SDiOSVersion deviceSize])
	{
		case Screen3Dot5inch:
		{
			left = 10.0;
			right = 10.0;
		}
			break;
		case Screen4inch:
		{
			left = 15.0;
			right = 15.0;
		}
			break;
		case Screen4Dot7inch:
		{
			left = 30.0;
			right = 30.0;
		}
			break;
		case Screen5Dot5inch:
		{
			left = 40.0;
			right = 40.0;
		}
			break;
		case UnknownSize:
		{
			left = 25.0;
			right = 25.0;
		}
			break;
	}
	
	return UIEdgeInsetsMake(10.0, left, 10.0, right);
}
#endif

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
										catalog:self.liveChanel
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
				
				[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
				
				self.lastSelectedItem = indexPath;
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
#if TARGET_OS_TV
					[catalogCell setHighlighted:YES];
#else
					[catalogCell setHighlighted:NO];
#endif
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
