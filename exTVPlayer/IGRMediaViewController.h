//
//  IGRMediaViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

typedef NS_ENUM(NSUInteger, IGRTrackProperties)
{
	IGRTrackProperties_None = 0,
	IGRTrackProperties_Setuped,
	IGRTrackProperties_InConfiguration
};

@interface IGRMediaViewController : UIViewController

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition;

@end
