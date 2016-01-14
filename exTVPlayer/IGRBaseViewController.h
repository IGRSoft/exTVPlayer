//
//  IGRBaseViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IGREntityAppSettings.h"

@interface IGRBaseViewController : UIViewController

- (IGREntityAppSettings*)appSettings;

- (void)callCustomAction;

@end
