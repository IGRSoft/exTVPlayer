//
//  IGRDownloadManager.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/16/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

@class IGREntityExTrack;

@interface IGRDownloadManager : NSObject

+ (instancetype)defaultInstance;

- (void)startDownloadTrack:(IGREntityExTrack *)aTrack withProgress:(UIProgressView *)aProgress;
- (void)updateProgress:(UIProgressView *)aProgress forTrack:(IGREntityExTrack *)aTrack;

- (void)removeAllProgresses;

@end
