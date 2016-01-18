//
//  IGRSettingsViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRBaseViewController.h"

@class IGREntityExTrack;

@interface IGRSettingsViewController : IGRBaseViewController

+ (void)removeSavedTrack:(IGREntityExTrack *)aTrack;

@end
