//
//  UITextView+UIFocusUpdateContext.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 5/10/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UITextField (UIFocusUpdateContext)

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator;
@end
