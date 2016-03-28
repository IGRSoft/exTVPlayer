//
//  IGRSearchViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRSearchViewController.h"
#import "IGRChanelViewController.h"

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
		IGRChanelViewController *chanelViewController = segue.destinationViewController;
		
		NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
		NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:self.searchText];
		if (self.searchText.length > 4 && [alphaNums isSupersetOfSet:inStringSet]) //Max: 9999
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
	BOOL textChanged = ![self.searchText isEqualToString:textField.text];
	self.searchText = [textField.text copy];
	
	IGREntityAppSettings *settings = [self appSettings];
	settings.lastPlayedCatalog = self.searchText;
	
	BOOL isText = self.searchText.length > 0;
	self.getListButton.enabled = isText;
	
	if (isText && textChanged)
	{
		CGFloat delay = 0.0;
#if	TARGET_OS_TV
		delay = kReloadTime * 2;
#endif
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self performSegueWithIdentifier:@"openSearch" sender:self];
		});
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	return [textField resignFirstResponder];
}

- (void)activateSearchField
{
	[self.catalogTextField becomeFirstResponder];
}

@end
