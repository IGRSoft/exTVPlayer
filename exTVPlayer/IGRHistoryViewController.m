//
//  IGRHistoryViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRHistoryViewController.h"
#import "IGRCChanelViewController_Private.h"
#import "IGREntityExCatalog.h"

@interface IGRHistoryViewController ()

@end

@implementation IGRHistoryViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self showHistory];
	
	[self reloadData];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{	
	[super viewDidAppear:animated];
}

- (void)endAppearanceTransition
{
	self.needHighlightCell = NO;
}

- (void)showHistory
{
	self.chanelMode = IGRChanelMode_History;
}

#pragma mark - UICollectionViewDataSource
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSUInteger result = [super collectionView:collectionView numberOfItemsInSection:section];
	
	[self showParsingProgress:NO];
	
	return result;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_History)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"viewedTimestamp != nil"];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"viewedTimestamp"
															   withPredicate:predicate
																	sortedBy:@"viewedTimestamp"
																   ascending:NO];
	}
	
	return _fetchedResultsController;
}
@end
