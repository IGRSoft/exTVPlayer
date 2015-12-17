//
//  ViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRStartScreenController.h"
#import "IGRCatalogViewController.h"

@interface IGRStartScreenController () <UITextFieldDelegate>

@property (copy, nonatomic) NSString *catalogId;

@end

@implementation IGRStartScreenController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.catalogId = [textField.text copy];
}

#pragma mark - UITextFieldDelegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"openCatalog"])
	{
		IGRCatalogViewController *catalogViewController = segue.destinationViewController;
		
#if DEBUG1
		[catalogViewController setCatalogId:@"94195016"];
#else
		[catalogViewController setCatalogId:self.catalogId];
#endif
	}
}

@end
