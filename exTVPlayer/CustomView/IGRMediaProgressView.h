//
//  IGRMediaProgressView.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/30/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import "IGRCustomViewFromXib.h"

@protocol IGRMediaProgressDelegate <NSObject>

- (void)updatedProgressPosition:(CGFloat)aProgressPosition;

@end

@interface IGRMediaProgressView : IGRCustomViewFromXib

@property (weak, nonatomic) id <IGRMediaProgressDelegate> delegate;

- (void)setTime:(NSString *)aTime;
- (void)setRemainingTime:(NSString *)aTime;

- (void)setTimePosition:(CGFloat)aPosition;
- (void)setNextTimePosition:(CGFloat)aPosition;

@property (nonatomic, readonly) CGFloat progress;

- (void)processNewPosition;

@end
