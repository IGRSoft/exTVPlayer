//
//  IGRSettingsConstants.h
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 3/24/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#ifndef IGRSettingsConstants_h
#define IGRSettingsConstants_h

typedef NS_ENUM(NSUInteger, IGRSourceType)
{
	IGRSourceType_RSS		= 0,
	IGRSourceType_Live		= 1
};

typedef NS_ENUM(NSUInteger, IGRTrackState)
{
	IGRTrackState_New = 0,
	IGRTrackState_Half,
	IGRTrackState_Done
};

typedef NS_ENUM(NSUInteger, IGRTrackDataStatus)
{
	IGRTrackDataStatus_Web = 0,
	IGRTrackDataStatus_Downloading,
	IGRTrackDataStatus_Local
};

typedef NS_ENUM(NSUInteger, IGRVideoCategory)
{
	IGRVideoCategory_Rus = 23775,
	IGRVideoCategory_Ukr = 80934,
	IGRVideoCategory_Eng = 80925,
	IGRVideoCategory_Esp = 187077,
	IGRVideoCategory_De  = 45205,
	IGRVideoCategory_Pl  = 968815
};

typedef NS_ENUM(NSUInteger, IGRHistorySize)
{
	IGRHistorySize_5	= 5,
	IGRHistorySize_10	= 10,
	IGRHistorySize_20	= 20,
	IGRHistorySize_50	= 50
};

typedef NS_ENUM(NSUInteger, IGRChanelMode)
{
	IGRChanelMode_Catalog		= 0,
	IGRChanelMode_Catalog_Live,
	IGRChanelMode_Catalog_One,
	IGRChanelMode_Favorites,
	IGRChanelMode_History,
	IGRChanelMode_Search
};

typedef NS_ENUM(NSUInteger, IGRSeekBack)
{
	IGRSeekBack_0		= 0,
	IGRSeekBack_5		= 5,
	IGRSeekBack_10		= 10,
	IGRSeekBack_15		= 15,
	IGRSeekBack_30		= 30,
	IGRSeekBack_60		= 60,
};

#endif /* IGRSettingsConstants_h */
