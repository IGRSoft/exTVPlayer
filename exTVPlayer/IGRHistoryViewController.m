//
//  IGRHistoryViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRHistoryViewController.h"
#import "IGRCChanelViewController.h"

@interface IGRHistoryViewController ()

@property (weak, nonatomic) IBOutlet UIButton *showHistoryButton;
@property (assign, nonatomic) BOOL allowAction;

@end

@implementation IGRHistoryViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.allowAction = YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
	if (self.allowAction)
	{
		[self.showHistoryButton sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
		self.allowAction = NO;
	}
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showHistoryChanels"])
	{
		IGRCChanelViewController *catalogViewController = segue.destinationViewController;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[catalogViewController showHistory];
		});
	}
}

- (void)callCustomAction
{
	self.allowAction = YES;
}

@end
