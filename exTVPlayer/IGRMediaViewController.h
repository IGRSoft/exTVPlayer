//
//  IGRMediaViewController.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

@import AVKit;

@interface IGRMediaViewController : UIViewController

- (void)setPlaylist:(NSArray *)aPlayList position:(NSUInteger)aPosition;

- (void)stopPIP;

@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) BOOL isPIP;

@end
