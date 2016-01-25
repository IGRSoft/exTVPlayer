//
//  IGRCChanelViewController_Private.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/24/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

@interface IGRCChanelViewController ()

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (assign, nonatomic) IGRChanelMode chanelMode;

@property (assign, nonatomic) dispatch_once_t onceToken;

- (void)showParsingProgress:(BOOL)show;

@end
