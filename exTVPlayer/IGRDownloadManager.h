//
//  IGRDownloadManager.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/16/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

@class IGREntityExTrack;
@class DALabeledCircularProgressView;

typedef void (^IGRDownloadManagerCompleateBlock)(void);

@interface IGRDownloadManager : NSObject

+ (nonnull instancetype)defaultInstance;

- (void)startDownloadTrack:(nonnull IGREntityExTrack *)aTrack withProgress:(nonnull DALabeledCircularProgressView *)aProgress compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock;
- (void)updateProgress:(nullable DALabeledCircularProgressView *)aProgress forTrack:(nonnull IGREntityExTrack *)aTrack compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock;
- (void)cancelDownloadTrack:(nonnull IGREntityExTrack *)aTrack;
- (void)removeAllProgresses;

@end
