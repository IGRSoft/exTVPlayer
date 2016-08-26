//
//  IGRFavoritsViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRFavoritsViewController.h"
#import "IGRChanelViewController_Private.h"

#import "IGREntityExCatalog.h"

@interface IGRFavoritsViewController ()

@end

@implementation IGRFavoritsViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self showFavorites];
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

- (void)showFavorites
{
	self.chanelMode = IGRChanelMode_Favorites;
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
	if (_fetchedResultsController == nil && self.chanelMode == IGRChanelMode_Favorites)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorit == YES"];
		_fetchedResultsController = [IGREntityExCatalog MR_fetchAllGroupedBy:@"itemId"
															   withPredicate:predicate
																	sortedBy:@"timestamp"
																   ascending:NO];
	}
	
	return _fetchedResultsController;
}

@end
