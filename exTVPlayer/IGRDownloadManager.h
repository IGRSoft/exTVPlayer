//
//  IGRDownloadManager.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/16/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

@class IGREntityExTrack;

typedef void (^IGRDownloadManagerCompleateBlock)(void);

@interface IGRDownloadManager : NSObject

+ (nonnull instancetype)defaultInstance;

- (void)startDownloadTrack:(nonnull IGREntityExTrack *)aTrack withProgress:(nonnull UIProgressView *)aProgress compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock;
- (void)updateProgress:(nullable UIProgressView *)aProgress forTrack:(nonnull IGREntityExTrack *)aTrack compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock;
- (void)cancelDownloadTrack:(nonnull IGREntityExTrack *)aTrack;
- (void)removeAllProgresses;

@end
