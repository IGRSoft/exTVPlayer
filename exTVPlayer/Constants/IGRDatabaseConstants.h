//
//  IGRDatabaseConstants.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 3/24/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#ifndef IGRDatabaseConstants_h
#define IGRDatabaseConstants_h

#ifdef __OBJC__
#import <CoreData/CoreData.h>
#endif

#if	TARGET_OS_TV
#import "MagicalRecord.h"
#else
#import <MagicalRecord/MagicalRecord.h>
#endif

#define MR_DEFAULT_CONTEXT [[MagicalRecordStack defaultStack] context]
#define MR_DEFAULT_CONTEXT_SAVEONLY [MR_DEFAULT_CONTEXT MR_saveOnlySelfAndWait]
#define MR_DEFAULT_CONTEXT_SAVETOPERSISTENTSTORE if (MR_DEFAULT_CONTEXT.hasChanges)\
{\
[MR_DEFAULT_CONTEXT MR_saveToPersistentStoreAndWait];\
}

#endif /* IGRDatabaseConstants_h */
