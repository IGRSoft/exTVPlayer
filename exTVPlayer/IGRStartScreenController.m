//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRStartScreenController.h"
#import "IGRCatalogViewController.h"
#import "IGRCChanelViewController.h"

#import "IGREXParser.h"
#import "IGREntityAppSettings.h"
#import "IGREntityExChanel.h"

#import "IGRChanelCell.h"

@interface IGRStartScreenController () <UITextFieldDelegate, NSFetchedResultsControllerDelegate>

@property (copy, nonatomic) NSString *catalogId;

@property (weak, nonatomic) IBOutlet UITextField *catalogTextField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UICollectionView *chanels;
@property (weak, nonatomic) IBOutlet UIButton *languageButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *sectionChanges;
@property (strong, nonatomic) NSMutableArray *itemChanges;

@property (strong, nonatomic) NSArray *languages;

@end

@implementation IGRStartScreenController

- (void)viewDidLoad
{
	self.languages = @[
					   @{@"id": @(IGRVideoCategory_Rus), @"langString": @"Рус"},
					   @{@"id": @(IGRVideoCategory_Ukr), @"langString": @"Укр"},
					   @{@"id": @(IGRVideoCategory_Eng), @"langString": @"En"},
					   @{@"id": @(IGRVideoCategory_Esp), @"langString": @"Esp"},
					   @{@"id": @(IGRVideoCategory_De), @"langString": @"DE"},
					   @{@"id": @(IGRVideoCategory_Pl), @"langString": @"Pl"}
					   ];
	
	[super viewDidLoad];
	
	self.chanels.backgroundColor = [UIColor clearColor];
	
	[self updateViewForLanguage];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	self.catalogTextField.text = self.catalogId = settings.lastPlayedCatalog;
	self.nextButton.enabled = self.catalogId.length > 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.chanels.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj setSelected:NO];
	}];
	
	[super viewWillDisappear:animated];
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

- (IBAction)onChangeLanguage:(id)sender
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *langId = settings.videoLanguageId;
	
	NSUInteger pos = [self.languages indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		BOOL result = [obj[@"id"] isEqualToNumber:langId];
		*stop = result;
		
		return result;
	}];
	
	pos = ((pos + 1) == self.languages.count) ? 0 : ++pos;
	
	NSDictionary *newLanguage = self.languages[pos];
	settings.videoLanguageId = newLanguage[@"id"];
	
	[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
	
	[self updateViewForLanguage];
}

- (void)updateViewForLanguage
{
	_fetchedResultsController = nil;
	
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *langId = settings.videoLanguageId;
	[IGREXParser parseVideoCatalogContent:langId.stringValue];
	
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		
		return [evaluatedObject[@"id"] isEqualToNumber:langId];
	}];
	
	NSString *langString = [[self.languages filteredArrayUsingPredicate:predicate] firstObject][@"langString"];
	
	[self.languageButton setTitle:langString forState:UIControlStateNormal];
	
	[self.chanels reloadData];
}

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
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setCatalogId:self.catalogId];
		});
	}
	else if ([segue.identifier isEqualToString:@"showChanel"])
	{
		IGRCChanelViewController *catalogViewController = segue.destinationViewController;
		
		NSIndexPath *dbIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.chanels.indexPathsForSelectedItems.firstObject.row + self.chanels.indexPathsForSelectedItems.firstObject.section)];
		IGREntityExChanel *chanel = [self.fetchedResultsController objectAtIndexPath:dbIndexPath];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController setChanel:chanel];
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
	}
	
	if ([nextFocusedCell isKindOfClass:[IGRChanelCell class]])
	{
		[nextFocusedCell setHighlighted:YES];
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
