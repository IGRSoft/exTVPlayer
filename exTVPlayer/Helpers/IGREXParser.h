//
//  IGREXParser.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 12/17/15.
//  Copyright © 2015 IGR Software. All rights reserved.
//

@interface IGREXParser : NSObject

+ (BOOL)parseCatalogContent:(NSString *)aCatalogId;
+ (void)parseVideoCatalogContent:(NSString *)aVideoCatalogId;
+ (void)parseChanelContent:(NSString *)aChanelId;

+ (NSArray *)parseLiveSearchContent:(NSString *)aSearchText page:(NSUInteger)aPage catalog:(NSInteger)aCatalog;
+ (NSArray *)parseLiveCatalog:(NSString *)aCatalog page:(NSUInteger)aPage;

@end
