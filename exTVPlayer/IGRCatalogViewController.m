//
//  IGRCatalogViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCatalogViewController.h"
#import "IGRMediaViewController.h"
#import "IGRSettingsViewController.h"

#import "IGREXParser.h"
#import "IGREntityExCatalog.h"
#import "IGREntityExTrack.h"
#import "IGRExItemCell.h"
#import "DACircularProgressView.h"
#import "IGRDownloadManager.h"

static const CGFloat reloadTime = 0.3;

@interface IGRCatalogViewController () <NSFetchedResultsControllerDelegate, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *catalogTitle;
@property (weak, nonatomic) IBOutlet UIButton *favoritButton;

@property (copy, nonatomic  ) NSString *catalogId;
@property (strong, nonatomic) IGREntityExCatalog *catalog;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (assign, nonatomic) BOOL needUpdateSelection;

@property (strong, nonatomic) IGRDownloadManager *downloadManager;

- (IBAction)onTouchFavorit:(id)sender;

@end

@implementation IGRCatalogViewController

- (void)setCatalogId:(NSString *)aCatalogId
{
	_catalogId = aCatalogId;
	__weak typeof(self) weak = self;
	[IGREXParser parseCatalogContent:aCatalogId
					  compleateBlock:^(NSArray *items) {
		
		self.catalog = [IGREntityExCatalog MR_findFirstByAttribute:@"itemId"
														 withValue:_catalogId];
		[weak.fetchedResultsController performFetch:nil];
	}];
	
	self.catalog.viewedTimestamp = [NSDate date];
	
	self.downloadManager = [IGRDownloadManager defaultInstance];
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
	}
	[self onTouchFavorit:nil];
	
	if ((self.fetchedResultsController).sections.count && ![self.catalog.latestViewedTrack isEqualToNumber:@0])
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalog.latestViewedTrack).integerValue];
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
	}
	
	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
										  initWithTarget:self action:@selector(handleLongPress:)];
	lpgr.minimumPressDuration = 1.0; //seconds
	lpgr.delegate = self;
	[self.tableView addGestureRecognizer:lpgr];
	
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[ super viewWillDisappear:animated];
	
	[self.downloadManager removeAllProgresses];
	
	if (MR_DEFAULT_CONTEXT.hasChanges)
	{
		[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];
	}
	
	for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers)
	{
		[self.tableView removeGestureRecognizer:gr];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)preferredFocusedView
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalog.latestViewedTrack).integerValue];
	
	return [self.tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

- (BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalog.latestViewedTrack).integerValue];
	
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
			
			[catalogViewController setPlaylist:(self.fetchedResultsController).sections
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
			self.catalog.isFavorit = @(!(self.catalog.isFavorit).boolValue);
		}
		
		UIImage *image = (self.catalog.isFavorit).boolValue ?	[UIImage imageNamed:@"favorit-on"] :
																[UIImage imageNamed:@"favorit-off"];
		[self.favoritButton setImage:image forState:UIControlStateNormal];
	}
}

#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return (self.fetchedResultsController).sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = (self.fetchedResultsController).sections[section];
	return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"IGRExItemCell";
	IGRExItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	if (!cell)
	{
		cell = [[IGRExItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									reuseIdentifier:cellIdentifier];
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	
	if (indexPath == tableView.indexPathsForVisibleRows.lastObject)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(reloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.needUpdateSelection = NO;
		});
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
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
	cell.savedIcon.hidden = ![track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Local)];
	cell.saveProgress.hidden = ![track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Downloading)];
	
	if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Downloading)])
	{
		__weak typeof(self) weak = self;
		__weak typeof(indexPath) weakIndexPath = indexPath;
		
		[self.downloadManager updateProgress:cell.saveProgress forTrack:track compleateBlock:^{
			
			if (weakIndexPath)
			{
				[weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			}
		}];
	}
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

#pragma mark - UIGestureRecognizerDelegate

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		NSIndexPath *indexPath = nil;
		for (indexPath in (self.tableView).indexPathsForVisibleRows)
		{
			IGRExItemCell *trackCell = (IGRExItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
			if (trackCell.isHighlighted)
			{
				UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tracks Options", @"")
																			  message:@""
																	   preferredStyle:UIAlertControllerStyleActionSheet];

				IGREntityExTrack *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
				UIAlertAction* action = nil;
				
				__weak typeof(self) weak = self;
				__weak typeof(indexPath) weakIndexPath = indexPath;
				if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Web)])
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save Track", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) {
														
														[weak.downloadManager startDownloadTrack:track
																					withProgress:trackCell.saveProgress compleateBlock:^(void) {
																						
																						if (weakIndexPath)
																						{
																							[weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationNone];
																						}
																					}];
														trackCell.saveProgress.hidden = NO;
														
														[view dismissViewControllerAnimated:YES completion:nil];
														
													}];
				}
				else if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Downloading)])
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel Download", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) {
														
														[weak.downloadManager cancelDownloadTrack:track];
														if (weakIndexPath)
														{
															dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(reloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
																[weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationNone];
															});
														}
														
														[view dismissViewControllerAnimated:YES completion:nil];
														
													}];
				}
				else if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Local)])
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Track", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) {
														
														[IGRSettingsViewController removeSavedTrack:track];
														
														dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(reloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
															[weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationNone];
														});
														
														[view dismissViewControllerAnimated:YES completion:nil];
														
													}];
				}
				
				[view addAction:action];
				
				UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
																 style:UIAlertActionStyleCancel
															   handler:^(UIAlertAction * action)
										 {
											 [view dismissViewControllerAnimated:YES completion:nil];
										 }];
				
				
				[view addAction:cancel];
				[self presentViewController:view animated:YES completion:nil];
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(reloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
					[trackCell setHighlighted:YES];
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
