//
//  IGREXParser.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IGREXParser : NSObject

+ (NSDictionary *)catalogContent:(NSString *)aCatalogId;

@end
