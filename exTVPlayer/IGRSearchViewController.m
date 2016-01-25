//
//  IGRSearchViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRSearchViewController.h"
#import "IGRCChanelViewController.h"

@interface IGRSearchViewController () <UITextFieldDelegate>

@property (copy, nonatomic) NSString *searchText;

@property (weak, nonatomic) IBOutlet UITextField *catalogTextField;
@property (weak, nonatomic) IBOutlet UIButton *getListButton;

@end

@implementation IGRSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	IGREntityAppSettings *settings = [self appSettings];
	self.catalogTextField.text = self.searchText = settings.lastPlayedCatalog;
	self.getListButton.enabled = self.searchText.length > 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)preferredFocusedView
{
	return self.catalogTextField;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"openSearch"])
	{
		IGRCChanelViewController *chanelViewController = segue.destinationViewController;
		
		NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
		NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:self.searchText];
		if ([alphaNums isSupersetOfSet:inStringSet])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[chanelViewController setCatalog:self.searchText];
			});
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[chanelViewController setSearchResult:self.searchText];
			});
		}
	}
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.searchText = [textField.text copy];
	
	IGREntityAppSettings *settings = [self appSettings];
	settings.lastPlayedCatalog = self.searchText;
	
	self.getListButton.enabled = self.searchText.length > 0;
}

@end
