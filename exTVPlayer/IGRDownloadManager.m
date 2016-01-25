//
//  IGRDownloadManager.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/16/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRDownloadManager.h"
#import "IGRAppDelegate.h"

#import "IGREntityExTrack.h"

#import <AFNetworking/AFNetworking.h>

@interface IGRDownloadManager ()

@property (strong, nonatomic) AFURLSessionManager *manager;
@property (strong, nonatomic) NSMutableArray *downloads;

@end

static NSString * const kIGRKeyWebUrl	 = @"webUrl";
static NSString * const kIGRKeyTask		 = @"task";
static NSString * const kIGRKeyProgress  = @"progress";
static NSString * const kIGRKeyCompleate = @"compleate";

@implementation IGRDownloadManager

+ (nonnull instancetype)defaultInstance
{
	static IGRDownloadManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	
	return sharedInstance;
}

- (nonnull instancetype)init
{
	self = [super init];
	if(self)
	{
		self.downloads = [NSMutableArray array];
		
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
	}
	
	return self;
}

- (void)startDownloadTrack:(nonnull IGREntityExTrack *)aTrack
			  withProgress:(nonnull UIProgressView *)aProgress
			compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock
{
	NSMutableDictionary *downloadObject = [self downloadObjectForTrack:aTrack];
	
	if (aTrack.localName.length ||
		downloadObject != nil ||
		[aTrack.dataStatus isEqualToNumber:@(IGRTrackDataStatus_Downloading)])
	{
		return;
	}
	
	aTrack.dataStatus = @(IGRTrackDataStatus_Downloading);
	
	NSURL *URL = [NSURL URLWithString:aTrack.webPath];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	__weak typeof(self) weak = self;
	NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request
																		  progress:^(NSProgress * _Nonnull downloadProgress)
	{
		NSMutableDictionary *downloadObject = [weak downloadObjectForTrack:aTrack];
		UIProgressView *progress = downloadObject[kIGRKeyProgress];
		if (![progress isEqual:[NSNull null]] && !progress.observedProgress)
		{
			progress.observedProgress = downloadProgress;
		}
	}
																	   destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
	{
		NSURL *destURL = [IGRAppDelegate videoFolder];
		destURL = [destURL URLByAppendingPathComponent:response.suggestedFilename];
		
		return destURL;
	}
																 completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
	{
		if (!error)
		{
			NSLog(@"File downloaded to: %@", filePath);
			
			aTrack.localName = filePath.lastPathComponent;
			aTrack.dataStatus = @(IGRTrackDataStatus_Local);
			[aTrack.managedObjectContext MR_saveOnlySelfAndWait];
			
			NSMutableDictionary *downloadObject = [weak downloadObjectForTrack:aTrack];
			
			if (downloadObject != nil)
			{
				[weak.downloads removeObject:downloadObject];
			}
			
			IGRDownloadManagerCompleateBlock block = downloadObject[kIGRKeyCompleate];
			if (block && ![block isEqual:[NSNull null]])
			{
				block();
			}
		}
	}];
	
	downloadObject = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   downloadTask, kIGRKeyTask,
										   aTrack.webPath, kIGRKeyWebUrl,
										   aProgress, kIGRKeyProgress, nil];
	
	if (compleateBlock)
	{
		downloadObject[kIGRKeyCompleate] = compleateBlock;
	}
	[self.downloads addObject:downloadObject];
	
	[downloadTask resume];
}

- (void)updateProgress:(nullable UIProgressView *)aProgress
			  forTrack:(nonnull IGREntityExTrack *)aTrack
		compleateBlock:(nullable IGRDownloadManagerCompleateBlock)compleateBlock
{
	NSMutableDictionary *downloadObject = [self downloadObjectForTrack:aTrack];
	
	if (downloadObject != nil)
	{
		if (compleateBlock)
		{
			downloadObject[kIGRKeyCompleate] = compleateBlock;
		}
		
		UIProgressView *oldProgress = downloadObject[kIGRKeyProgress];
		
		if (oldProgress != aProgress)
		{
			downloadObject[kIGRKeyProgress] = aProgress;
		}
	}
}

- (void)cancelDownloadTrack:(nonnull IGREntityExTrack *)aTrack
{
	NSMutableDictionary *downloadObject = [self downloadObjectForTrack:aTrack];
	NSURLSessionDownloadTask *downloadTask = downloadObject[kIGRKeyTask];
	
	[self.downloads removeObject:downloadObject];
	[downloadTask cancel];
	
	aTrack.dataStatus = @(IGRTrackDataStatus_Web);
	[aTrack.managedObjectContext MR_saveOnlySelfAndWait];
}

- (void)removeAllProgresses
{
	for (NSMutableDictionary *downloadObject in self.downloads)
	{
		downloadObject[kIGRKeyProgress] = [NSNull null];
		downloadObject[kIGRKeyCompleate] = [NSNull null];
	}
}

- (NSMutableDictionary *)downloadObjectForTrack:(IGREntityExTrack *)aTrack
{
	NSUInteger downloadingPosition = [self.downloads indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		BOOL result = [obj[kIGRKeyWebUrl] isEqualToString:aTrack.webPath];
		*stop = result;
		
		return result;
	}];
	
	if (downloadingPosition != NSNotFound)
	{
		return self.downloads[downloadingPosition];
	}
	
	return nil;
}

@end
