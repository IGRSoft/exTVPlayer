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

#import "IGRDownloadManager.h"

#import "DACircularProgressView.h"
#import "DALabeledCircularProgressView.h"
#import <WebImage/WebImage.h>

@import AVFoundation;

#if	TARGET_OS_IOS
static IGRMediaViewController *_mediaViewController;
#endif

@interface IGRCatalogViewController () <NSFetchedResultsControllerDelegate, UITableViewDelegate,
                                        UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate>

@property (weak,   nonatomic) IBOutlet UITableView *tableView;
@property (weak,   nonatomic) IBOutlet UIView      *navigationView;
@property (weak,   nonatomic) IBOutlet UILabel     *catalogTitle;
@property (weak,   nonatomic) IBOutlet UILabel     *catalogDescription;
@property (weak,   nonatomic) IBOutlet UIImageView *catalogImage;
@property (strong, nonatomic) IBOutlet UIButton    *favoritButton;

@property (strong, nonatomic) UINavigationBar  *navigationBar;
@property (strong, nonatomic) UINavigationItem *navigationItem;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (copy,   nonatomic) NSString *catalogId;
@property (strong, nonatomic) IGREntityExCatalog *catalog;

#if	TARGET_OS_TV
@property (weak, nonatomic)   IGRMediaViewController *mediaViewController;
#endif
@property (assign, nonatomic) BOOL needUpdateSelection;

@property (strong, nonatomic) IGRDownloadManager *downloadManager;

- (IBAction)onTouchFavorit:(id)sender;

@end

@implementation IGRCatalogViewController

- (void)setCatalogId:(NSString *)aCatalogId
{
	_catalogId = aCatalogId;
	[self.tableView reloadData];
	
	__weak typeof(self) weak = self;
	[IGREXParser parseCatalogContent:aCatalogId
					  compleateBlock:^(NSArray *items) {
						  
						  weak.catalog = [items firstObject];
						  if (_fetchedResultsController)
						  {
							  [weak.fetchedResultsController performFetch:nil];
						  }
					  }];
	
	self.catalog.viewedTimestamp = [NSDate date];
	
	self.downloadManager = [IGRDownloadManager defaultInstance];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
#if	TARGET_OS_IOS
	{
		self.navigationBar = [[UINavigationBar alloc] initWithFrame:self.navigationView.frame];
		self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self.navigationView addSubview:self.navigationBar];
		
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
																	   style:UIBarButtonItemStylePlain
																	  target:self
																	  action:@selector(onTouchBack:)];
		
		UIImage* favoritImageOff = [UIImage imageNamed:@"favorit-off"];
		UIImage* favoritImageOn = [UIImage imageNamed:@"favorit-on"];
		
		CGRect favoritImageRect = CGRectMake(0, 0, favoritImageOff.size.width, favoritImageOff.size.height);
		self.favoritButton = [[UIButton alloc] initWithFrame:favoritImageRect];
		[self.favoritButton setBackgroundImage:favoritImageOff forState:UIControlStateNormal];
		[self.favoritButton setBackgroundImage:favoritImageOn forState:UIControlStateSelected];
		
		[self.favoritButton addTarget:self action:@selector(onTouchFavorit:) forControlEvents:UIControlEventTouchUpInside];
		[self.favoritButton setShowsTouchWhenHighlighted:YES];
		
		UIBarButtonItem *fvButton =[[UIBarButtonItem alloc] initWithCustomView:self.favoritButton];
		
		
		self.navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
		self.navigationItem.leftBarButtonItem = backButton;
		self.navigationItem.rightBarButtonItem = fvButton;
		
		[self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
		
		[self.navigationView addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar
																		attribute:NSLayoutAttributeTop
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.navigationView
																		attribute:NSLayoutAttributeTop
																	   multiplier:1.0
																		 constant:0.0]];
		[self.navigationView addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationView
																		attribute:NSLayoutAttributeBottom
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.navigationBar
																		attribute:NSLayoutAttributeBottom
																	   multiplier:1.0
																		 constant:0.0]];
		[self.navigationView addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar
																		attribute:NSLayoutAttributeLeading
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.navigationView
																		attribute:NSLayoutAttributeLeading
																	   multiplier:1.0
																		 constant:0.0]];
		[self.navigationView addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationView
																		attribute:NSLayoutAttributeTrailing
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.navigationBar
																		attribute:NSLayoutAttributeTrailing
																	   multiplier:1.0
																		 constant:0.0]];
	}
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
#if	TARGET_OS_IOS
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	/* listen for notifications from the player */
	[defaultCenter addObserver:self
					  selector:@selector(didMergeChangesFromiCloud:)
						  name:MagicalRecordDidMergeChangesFromiCloudNotification
						object:nil];
#endif
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.needUpdateSelection = YES;
	
	if (self.catalog)
	{
#if	TARGET_OS_IOS
		self.navigationItem.title = self.catalog.name;
#else
		self.catalogTitle.text = self.catalog.name;
        self.catalogDescription.text = self.catalog.catalogDescription;
        [self.catalogImage sd_setImageWithURL:[NSURL URLWithString:self.catalog.imgUrl]
                             placeholderImage:nil];
#endif
	}
	[self onTouchFavorit:nil];
	
	if ((self.fetchedResultsController).sections.count && ![self.catalog.latestViewedTrack isEqualToNumber:@0])
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalog.latestViewedTrack).integerValue];
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
	}
	
#if	TARGET_OS_TV
	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
										  initWithTarget:self action:@selector(handleLongPress:)];
	lpgr.minimumPressDuration = 1.0; //seconds
	lpgr.delegate = self;
	[self.tableView addGestureRecognizer:lpgr];
#endif
	
	[self.tableView reloadData];
	
#if	TARGET_OS_IOS
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(self.catalog.latestViewedTrack).integerValue];
	IGRExItemCell *trackCell = (IGRExItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	trackCell.highlighted = YES;
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	[ super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self.downloadManager removeAllProgresses];
	
#if	TARGET_OS_TV
	for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers)
	{
		[self.tableView removeGestureRecognizer:gr];
	}
#endif
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
		[_mediaViewController stopPIP];
		_mediaViewController = segue.destinationViewController;
#if	TARGET_OS_IOS
		if (AVPictureInPictureController.isPictureInPictureSupported)
		{
			_mediaViewController.delegate = self;
		}
#endif
		self.catalog.latestViewedTrack = @(self.tableView.indexPathForSelectedRow.section);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[_mediaViewController setPlaylist:(self.fetchedResultsController).sections
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
		
#if	TARGET_OS_IOS
		self.favoritButton.selected = (self.catalog.isFavorit).boolValue;
#else
		UIImage *image = (self.catalog.isFavorit).boolValue ? [UIImage imageNamed:@"favorit-on"] :
		[UIImage imageNamed:@"favorit-off"];
		[self.favoritButton setImage:image forState:UIControlStateNormal];
#endif
	}
}

- (IBAction)onTouchBack:(UIButton *)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
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
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.needUpdateSelection = NO;
		});
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)configureCell:(IGRExItemCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	IGREntityExTrack *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setMinimumIntegerDigits:2];
	NSString *positionString = [numberFormatter stringFromNumber:@(track.orderId.integerValue + 1)];
	NSString *title = [NSString stringWithFormat:@"[%@] %@", positionString, track.name];
	
	cell.title.text = title;
	
	CGFloat trackPosition = track.position.floatValue / track.duration.floatValue;
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

#pragma mark - UITableViewRowAction

#if	TARGET_OS_IOS
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
	IGREntityExTrack *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	__weak typeof(self) weak = self;
	IGRExItemCell *trackCell = (IGRExItemCell *)[tableView cellForRowAtIndexPath:indexPath];
	
	UITableViewRowAction *actionSaveTrack = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																			   title:@"\U0001F4E5"
																			 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
											 {
												 [weak startDownloadTrack:track
																 withCell:trackCell
															   onPosition:indexPath];
												 
												 [weak.tableView setEditing:NO animated:YES];
											 }];
	
	UITableViewRowAction *actionCancelDownload = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																					title:@"\U0001F6AB"
																				  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
												  {
													  [weak cancelDownloadTrack:track onPosition:indexPath];
													  
													  [weak.tableView setEditing:NO animated:YES];
												  }];
	
	UITableViewRowAction *actionRemoveDownloadedTrack = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																						   title:@"\u274C"
																						 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
														 {
															 [weak removeSavedTrack:track onPosition:indexPath];
															 
															 [weak.tableView setEditing:NO animated:YES];
														 }];
	
	actionSaveTrack.backgroundColor = IGR_LIGHTBLUECOLOR;
	actionCancelDownload.backgroundColor = IGR_LIGHTBLUECOLOR;
	actionRemoveDownloadedTrack.backgroundColor = IGR_LIGHTBLUECOLOR;
	
	__weak typeof(indexPath) weakIndexPath = indexPath;
	UITableViewRowAction *markPlayedAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																				title:@"\u26AA\uFE0F"
																			  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
											  {
												  track.status = @(IGRTrackState_Done);
												  track.position = @0;
												  
												  [weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationFade];
												  
												  [weak.tableView setEditing:NO animated:YES];
											  }];

	
	UITableViewRowAction *markUnplayedAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																			   title:@"\U0001F535"
																			 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
											 {
												 track.status = @(IGRTrackState_New);
												 track.position = @0;
												 
												 [weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationFade];
												 
												 [weak.tableView setEditing:NO animated:YES];
											 }];
	
	markPlayedAction.backgroundColor = IGR_YELLOWCOLOR;
	markUnplayedAction.backgroundColor = IGR_YELLOWCOLOR;
	
	NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
	
	switch (track.dataStatus.integerValue)
	{
		case IGRTrackDataStatus_Web:
			[actions addObject:actionSaveTrack];
			break;
			
		case IGRTrackDataStatus_Downloading:
			[actions addObject:actionCancelDownload];
			break;
		case IGRTrackDataStatus_Local:
			[actions addObject:actionRemoveDownloadedTrack];
			break;
	}
	
	switch (track.status.integerValue)
	{
		case IGRTrackState_New:
			[actions addObject:markPlayedAction];
			break;
			
		case IGRTrackState_Half:
			[actions addObject:markPlayedAction];
			[actions addObject:markUnplayedAction];
			break;
		case IGRTrackState_Done:
			[actions addObject:markUnplayedAction];
			break;
	}
	
	return actions;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView.visibleCells enumerateObjectsUsingBlock:^(IGRExItemCell *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setHighlighted:NO];
	}];
}

#endif

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil && self.catalogId.length)
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
				UIAlertControllerStyle style = UIAlertControllerStyleActionSheet;
				UIAlertController *view = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tracks Options", @"")
																			  message:@""
																	   preferredStyle:style];
				
				IGREntityExTrack *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
				UIAlertAction* action = nil;
				
				__weak typeof(self) weak = self;
				__weak typeof(indexPath) weakIndexPath = indexPath;
				if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Web)])
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save Track", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action)
							  {
								  
								  [weak startDownloadTrack:track
												  withCell:trackCell
												onPosition:weakIndexPath];
								  
								  [view dismissViewControllerAnimated:YES completion:nil];
								  
							  }];
				}
				else if ([track.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Downloading)])
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel Download", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action)
							  {
								  
								  [weak cancelDownloadTrack:track onPosition:weakIndexPath];
								  
								  [view dismissViewControllerAnimated:YES completion:nil];
								  
							  }];
				}
				else
				{
					action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Track", @"")
													  style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action)
							  {
								  
								  [weak removeSavedTrack:track onPosition:weakIndexPath];
								  
								  [view dismissViewControllerAnimated:YES completion:nil];
								  
							  }];
				}
				
				[view addAction:action];
				
				UIAlertAction *markPlayedAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Mark as Played", @"")
																		   style:UIAlertActionStyleDefault
																		 handler:^(UIAlertAction * action)
												   {
													   
													   track.status = @(IGRTrackState_Done);
													   track.position = @0;
													   
													   [weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationFade];
													   
													   [view dismissViewControllerAnimated:YES completion:nil];
													   
												   }];
				
				UIAlertAction *markUnplayedAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Mark as Unplayed", @"")
																			 style:UIAlertActionStyleDefault
																		   handler:^(UIAlertAction * action)
													 {
														 
														 track.status = @(IGRTrackState_New);
														 track.position = @0;
														 
														 [weak.tableView reloadRowsAtIndexPaths:@[weakIndexPath] withRowAnimation:UITableViewRowAnimationFade];
														 
														 [view dismissViewControllerAnimated:YES completion:nil];
														 
													 }];
				
				switch (track.status.integerValue)
				{
					case IGRTrackState_New:
						[view addAction:markPlayedAction];
						break;
						
					case IGRTrackState_Half:
						[view addAction:markPlayedAction];
						[view addAction:markUnplayedAction];
						break;
					case IGRTrackState_Done:
						[view addAction:markUnplayedAction];
						break;
				}
				
				UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
																 style:UIAlertActionStyleCancel
															   handler:^(UIAlertAction * action)
										 {
											 [view dismissViewControllerAnimated:YES completion:nil];
										 }];
				
				
				[view addAction:cancel];
				[self presentViewController:view animated:YES completion:nil];
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

- (void)startDownloadTrack:(nonnull IGREntityExTrack *)aTrack
				  withCell:(nonnull IGRExItemCell *)aTrackCell
				onPosition:(nullable NSIndexPath *)aIndexPath
{
	[self.downloadManager startDownloadTrack:aTrack
								withProgress:aTrackCell.saveProgress compleateBlock:^(void) {
									
									if (aIndexPath)
									{
										[self.tableView reloadRowsAtIndexPaths:@[aIndexPath]
															  withRowAnimation:UITableViewRowAnimationNone];
									}
								}];
	
	aTrackCell.saveProgress.hidden = NO;
}

- (void)cancelDownloadTrack:(nonnull IGREntityExTrack *)aTrack
				 onPosition:(nullable NSIndexPath *)aIndexPat
{
	[self.downloadManager cancelDownloadTrack:aTrack];
	if (aIndexPat)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.tableView reloadRowsAtIndexPaths:@[aIndexPat] withRowAnimation:UITableViewRowAnimationNone];
		});
	}
}

- (void)removeSavedTrack:(nonnull IGREntityExTrack *)aTrack
			  onPosition:(nullable NSIndexPath *)aIndexPat
{
	[IGRSettingsViewController removeSavedTrack:aTrack];
	
	if (aIndexPat)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReloadTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.tableView reloadRowsAtIndexPaths:@[aIndexPat] withRowAnimation:UITableViewRowAnimationNone];
		});
	}
}

#pragma mark - AVPlayerViewControllerDelegate

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
	_mediaViewController.isPIP = YES;
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
	_mediaViewController.isPIP = NO;
}

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController
{
	return YES;
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler
{
	if (self.presentedViewController == _mediaViewController)
	{
		completionHandler(NO);
	}
	else
	{
		[self presentViewController:_mediaViewController animated:YES completion:^{
			
			completionHandler(YES);
		}];
	}
}

#pragma mark - NSNotificationCenter

- (void)didMergeChangesFromiCloud:(NSNotification*)aNotification
{
	[self.fetchedResultsController performFetch:nil];
	[self.tableView reloadData];
}

@end
