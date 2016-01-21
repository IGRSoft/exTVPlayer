//
//  IGRHistoryViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRHistoryViewController.h"

@interface IGRHistoryViewController ()

@end

@implementation IGRHistoryViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self showHistory];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
	self.needHighlightCell = NO;
	
	[super viewDidAppear:animated];
}

@end
