//
//  IGRUserDefaults.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/23/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IGRUserDefaults : NSObject

@property (nonatomic, strong) NSArray *history;
@property (nonatomic, strong) NSArray *favorites;

- (void)loadUserSettings;
- (void)saveUserSettings;

@end
