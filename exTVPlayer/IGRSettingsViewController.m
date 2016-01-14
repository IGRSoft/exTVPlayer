//
//  IGRSettingsViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRSettingsViewController.h"

@interface IGRSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *languageButton;
@property (weak, nonatomic) IBOutlet UIButton *cacheButton;
@property (weak, nonatomic) IBOutlet UIButton *historySizeButton;

@property (strong, nonatomic) NSArray *languages;
@property (strong, nonatomic) NSArray *caches;
@property (strong, nonatomic) NSArray *history;

@end

@implementation IGRSettingsViewController

- (void)viewDidLoad
{
	self.languages = @[
					   @{@"id": @(IGRVideoCategory_Rus), @"langString": @"Русский"},
					   @{@"id": @(IGRVideoCategory_Ukr), @"langString": @"Укрїнський"},
					   @{@"id": @(IGRVideoCategory_Eng), @"langString": @"Ennglish"},
					   @{@"id": @(IGRVideoCategory_Esp), @"langString": @"Española"},
					   @{@"id": @(IGRVideoCategory_De),  @"langString": @"Deutsch"},
					   @{@"id": @(IGRVideoCategory_Pl),  @"langString": @"Polskie"}
					   ];
	
	self.caches = @[
					@{@"value": @(IGRCache_Default),		@"name": NSLocalizedString(@"Cache_Default", nil)},
					@{@"value": @(IGRCache_HighLatency),	@"name": NSLocalizedString(@"Cache_HighLatency", nil)},
					@{@"value": @(IGRCache_HigherLatency),	@"name": NSLocalizedString(@"Cache_HigherLatency", nil)}
					];
	
	self.history = @[@(IGRHistorySize_5),
					 @(IGRHistorySize_10),
					 @(IGRHistorySize_20),
					 @(IGRHistorySize_50)
					];
	
	[super viewDidLoad];
	
	[self updateViewForLanguage];
	[self updateViewForCache];
	[self updateViewForHistorySize];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *langId = settings.videoLanguageId;
	
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		
		return [evaluatedObject[@"id"] isEqualToNumber:langId];
	}];
	
	NSString *langString = [[self.languages filteredArrayUsingPredicate:predicate] firstObject][@"langString"];
	
	[self.languageButton setTitle:langString forState:UIControlStateNormal];
}

- (IBAction)onChangeCache:(id)sender
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *cache = settings.cacheSize;
	
	NSUInteger pos = [self.caches indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		BOOL result = [obj[@"value"] isEqualToNumber:cache];
		*stop = result;
		
		return result;
	}];
	
	pos = ((pos + 1) == self.caches.count) ? 0 : ++pos;
	
	NSDictionary *newCache = self.caches[pos];
	settings.cacheSize = newCache[@"value"];
	
	[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
	
	[self updateViewForCache];
}

- (void)updateViewForCache
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *cache = settings.cacheSize;
	
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		
		return [evaluatedObject[@"value"] isEqualToNumber:cache];
	}];
	
	NSString *cacheName = [[self.caches filteredArrayUsingPredicate:predicate] firstObject][@"name"];
	
	[self.cacheButton setTitle:cacheName forState:UIControlStateNormal];
}

- (IBAction)onChangeHistorySize:(id)sender
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *historySize = settings.historySize;
	
	NSUInteger pos = [self.history indexOfObject:historySize];
	
	pos = ((pos + 1) == self.history.count) ? 0 : ++pos;
	
	NSNumber *newHistorySize = self.history[pos];
	settings.historySize = newHistorySize;
	
	[MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait];
	
	[self updateViewForHistorySize];
}

- (void)updateViewForHistorySize
{
	IGREntityAppSettings *settings = [self appSettings];
	NSNumber *historySize = settings.historySize;
	
	[self.historySizeButton setTitle:historySize.stringValue forState:UIControlStateNormal];
}

@end
