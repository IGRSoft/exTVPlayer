//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRStartScreenController.h"
#import "IGRCatalogViewController.h"

#import "IGREntityAppSettings.h"

@interface IGRStartScreenController () <UITextFieldDelegate>

@property (copy, nonatomic) NSString *catalogId;

@property (weak, nonatomic) IBOutlet UITextField *catalogTextField;

@end

@implementation IGRStartScreenController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	self.catalogTextField.text = self.catalogId = settings.lastPlayedCatalog;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.catalogId = [textField.text copy];
	
	IGREntityAppSettings *settings = [self appSettings];
	settings.lastPlayedCatalog = self.catalogId;
}

#pragma mark - UITextFieldDelegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"openCatalog"])
	{
		IGRCatalogViewController *catalogViewController = segue.destinationViewController;
		
		[catalogViewController setCatalogId:self.catalogId];
	}
}

- (IGREntityAppSettings*)appSettings
{
	IGREntityAppSettings *settings = [IGREntityAppSettings MR_findFirst];
	if (!settings)
	{
		settings = [IGREntityAppSettings MR_createEntity];
		[MR_DEFAULT_CONTEXT saveOnlySelfAndWait];
	}
	
	return settings;
}

@end
