//
//  IGRCatalogViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCatalogViewController.h"
#import "IGRMediaViewController.h"

#import "IGREXParser.h"
#import "IGREntityExCatalog.h"
#import "IGREntityExTrack.h"
#import "IGRExItemCell.h"
#import "DACircularProgressView.h"

@interface IGRCatalogViewController () <NSFetchedResultsControllerDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *catalogTitle;
@property (weak, nonatomic) IBOutlet UIButton *favoritButton;

@property (copy, nonatomic) NSString *catalogId;
@property (strong, nonatomic) IGREntityExCatalog *catalog;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (assign, nonatomic) BOOL needUpdateSelection;

- (IBAction)onTouchFavorit:(id)sender;

@end

@implementation IGRCatalogViewController

- (void)setCatalogId:(NSString *)aCatalogId
{
	_catalogId = aCatalogId;
	self.catalog = [IGREntityExCatalog MR_findFirstByAttribute:@"itemId"
													 withValue:_catalogId];
	[IGREXParser parseCatalogContent:aCatalogId];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	self.needUpdateSelection = YES;
	
	if (self.catalog)
	{
		self.catalogTitle.text = self.catalog.name;
		[self onTouchFavorit:nil];
	}
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[self.catalog.latestViewedTrack integerValue]];
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
	
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if ([MR_DEFAULT_CONTEXT hasChanges])
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)preferredFocusedView
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[self.catalog.latestViewedTrack integerValue]];
	
	return [self.tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

- (BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[self.catalog.latestViewedTrack integerValue]];
	
	if (self.needUpdateSelection)
	{
		return indexPath.section == aIndexPath.section;
	}
	
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldUpdateFocusInContext:(UITableViewFocusUpdateContext *)context
{
	IGRExItemCell *previouslyFocusedCell = (IGRExItemCell *)context.previouslyFocusedView;
	IGRExItemCell *nextFocusedCell = (IGRExItemCell *)context.nextFocusedView;
	
	if ([previouslyFocusedCell isKindOfClass:[IGRExItemCell class]])
	{
		[previouslyFocusedCell setHighlighted:NO];
	}
	
	if ([nextFocusedCell isKindOfClass:[IGRExItemCell class]])
	{
		[nextFocusedCell setHighlighted:YES];
	}
	
	return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"playPlaylistPosition"])
	{
		IGRMediaViewController *catalogViewController = segue.destinationViewController;
		self.catalog.latestViewedTrack = @(self.tableView.indexPathForSelectedRow.section);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setPlaylist:[self.fetchedResultsController sections]
									  position:self.tableView.indexPathForSelectedRow.section];
		});
	}
}

- (IBAction)onTouchFavorit:(UIButton *)sender
{
	if (self.catalog)
	{
		if (sender)
		{
			self.catalog.isFavorit = @(![self.catalog.isFavorit boolValue]);
		}
		
		UIImage *image = [self.catalog.isFavorit boolValue] ?	[UIImage imageNamed:@"favorit-on"] :
																[UIImage imageNamed:@"favorit-off"];
		[self.favoritButton setImage:image forState:UIControlStateNormal];
	}
}

#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	IGRExItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IGRExItemCell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	
	if (indexPath == [[tableView indexPathsForVisibleRows] lastObject])
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.needUpdateSelection = NO;
		});
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return NO if you do not want the specified item to be editable.
	return YES;
}

- (void)configureCell:(IGRExItemCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	IGREntityExTrack *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	cell.title.text = track.name;
	
	CGFloat trackPosition = track.position.floatValue;
	if (track.status.integerValue == IGRTrackState_Done)
	{
		trackPosition = 1.0;
	}
	cell.trackStatus.progress = 1.0 - trackPosition;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"catalog.itemId == %@", self.catalogId];
		_fetchedResultsController = [IGREntityExTrack MR_fetchAllGroupedBy:@"orderId"
															 withPredicate:predicate
																  sortedBy:@"orderId"
																 ascending:YES];
	}
	
	return _fetchedResultsController;
}

@end
