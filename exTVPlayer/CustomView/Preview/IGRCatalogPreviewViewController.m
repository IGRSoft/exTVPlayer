//
//  IGRCatalogPreviewViewController.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/24/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRCatalogPreviewViewController.h"
#import "IGREntityExCatalog.h"

#import <WebImage/WebImage.h>

@interface IGRCatalogPreviewViewController () <UIPreviewActionItem>

@property (strong, nonatomic) IGREntityExCatalog *catalog;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation IGRCatalogPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithCatalog:(IGREntityExCatalog *)aCatalog
{
	if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]])
	{
		self.catalog = aCatalog;
	}
	
	return self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.titleLabel.text = self.catalog.name;
	[self.imageView sd_setImageWithURL:[NSURL URLWithString:self.catalog.imgUrl]
					  placeholderImage:nil];
}

- (NSArray <id <UIPreviewActionItem>> *)previewActionItems
{
	__weak typeof(self) weak = self;
	UIPreviewAction *openAction = [UIPreviewAction actionWithTitle:@"Open"
															 style:UIPreviewActionStyleDefault
														   handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
		
		if ([weak.delegate respondsToSelector:@selector(openCatalogForPreview)])
		{
			[weak.delegate openCatalogForPreview];
		}
	}];
	
	return @[openAction];
}

@end
