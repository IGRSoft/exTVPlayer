//
//  IGRCatalogViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCatalogViewController.h"
#import "IGRMediaViewController.h"

#import "IGREXParser.h"
#import "IGRExTrack.h"
#import "IGRExItemCell.h"

@interface IGRCatalogViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *catalogTitle;

@property (strong, nonatomic) NSArray *catalogTracks;
@property (copy, nonatomic) NSString *catalogTitleString;

@end

@implementation IGRCatalogViewController

- (void)setCatalogId:(NSString *)aCatalogId
{
	NSDictionary *catalogContent = [IGREXParser catalogContent:aCatalogId];
	
	self.catalogTracks = catalogContent[@"tracks"];
	self.catalogTitleString = catalogContent[@"title"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.catalogTitle.text = self.catalogTitleString;
	
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"playPlaylistPosition"])
	{
		IGRMediaViewController *catalogViewController = segue.destinationViewController;
		[catalogViewController setPlaylist:self.catalogTracks position:self.tableView.indexPathForSelectedRow.row];
	}
}

#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.catalogTracks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IGRExItemCell";
    IGRExItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	IGRExTrack *track = self.catalogTracks[indexPath.row];
	cell.title.text = track.title;
	cell.viewStatus.image = [UIImage imageNamed:@"new"];
	
    return cell;
}

#pragma mark - UITableViewDelegate
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


@end
