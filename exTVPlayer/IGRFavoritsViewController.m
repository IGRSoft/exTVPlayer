//
//  IGRFavoritsViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRFavoritsViewController.h"

@interface IGRFavoritsViewController ()

@end

@implementation IGRFavoritsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self showFavorites];
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
