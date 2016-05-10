//
//  UITextView+UIFocusUpdateContext.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 5/10/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "UITextView+UIFocusUpdateContext.h"

@implementation UITextView (UIFocusUpdateContext)

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    if (context.nextFocusedView == self)
    {
        // handle focus appearance changes
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    else
    {
        // handle unfocused appearance changes
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

@end