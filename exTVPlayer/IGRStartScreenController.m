//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRStartScreenController.h"
#import "IGRCatalogViewController.h"

#import "IGREXParser.h"
#import "IGREntityAppSettings.h"
#import "IGREntityExChanel.h"

#import "IGRChanelCell.h"

@interface IGRStartScreenController () <UITextFieldDelegate, NSFetchedResultsControllerDelegate>

@property (copy, nonatomic) NSString *catalogId;

@property (weak, nonatomic) IBOutlet UITextField *catalogTextField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UICollectionView *chanels;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *sectionChanges;
@property (strong, nonatomic) NSMutableArray *itemChanges;

@end

@implementation IGRStartScreenController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	IGREntityAppSettings *settings = [self appSettings];
	[IGREXParser parseVideoCatalogContent:settings.videoLanguageId.stringValue];
	
	self.chanels.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	self.catalogTextField.text = self.catalogId = settings.lastPlayedCatalog;
	self.nextButton.enabled = self.catalogId.length > 0;
}

- (UIView *)preferredFocusedView
{
	return self.catalogTextField;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Public

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

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.catalogId = [textField.text copy];
	
	IGREntityAppSettings *settings = [self appSettings];
	settings.lastPlayedCatalog = self.catalogId;
	
	self.nextButton.enabled = self.catalogId.length > 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"openCatalog"])
	{
		IGRCatalogViewController *catalogViewController = segue.destinationViewController;
		
		[catalogViewController setCatalogId:self.catalogId];
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
	IGRChanelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IGRChanelCell" forIndexPath:indexPath];
	
	NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(indexPath.row + indexPath.section)];
	IGREntityExChanel *track = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
	
	cell.title.text = track.name;
	
	return cell;
}

#pragma mark - UICollectionViewDelegate
#pragma mark -

- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{
	
	IGRChanelCell *previouslyFocusedCell = (IGRChanelCell *)context.previouslyFocusedView;
	IGRChanelCell *nextFocusedCell = (IGRChanelCell *)context.nextFocusedView;
	
	if ([previouslyFocusedCell isKindOfClass:[IGRChanelCell class]])
	{
		[previouslyFocusedCell setHighlighted:NO];
		[UIView animateWithDuration:0.1
							  delay:0
							options:(UIViewAnimationOptionAllowUserInteraction)
						 animations:^{
							 [previouslyFocusedCell.backgroundView setBackgroundColor:[UIColor whiteColor]];
						 }
						 completion:nil ];
	}
	
	if ([nextFocusedCell isKindOfClass:[IGRChanelCell class]])
	{
		[previouslyFocusedCell setHighlighted:YES];
		[UIView animateWithDuration:0.1
							  delay:0
							options:(UIViewAnimationOptionAllowUserInteraction)
						 animations:^{
							 [nextFocusedCell.backgroundView setBackgroundColor:[UIColor colorWithRed:213/255.0f green:232/255.0f blue:255/255.0f alpha:1]];
						 }
						 completion:nil];
	}
	
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected item!");
}

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
