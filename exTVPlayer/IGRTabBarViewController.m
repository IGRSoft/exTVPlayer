//
//  IGRTabBarViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRTabBarViewController.h"
#import "IGRBaseViewController.h"

@interface IGRTabBarViewController () <UITabBarControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL allowCustomAction;

@end

@implementation IGRTabBarViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.delegate = self;
	self.allowCustomAction = NO;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(IGRBaseViewController *)viewController
{
	if (self.allowCustomAction)
	{
		self.allowCustomAction = NO;
		[viewController callCustomAction];
	}
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender
{
	self.allowCustomAction = YES;
	
	return YES;
}

@end
