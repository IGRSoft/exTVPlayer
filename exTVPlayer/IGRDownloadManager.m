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

static NSString * const kIGRKeyWebUrl	= @"webUrl";
static NSString * const kIGRKeyTask		= @"task";
static NSString * const kIGRKeyProgress = @"progress";

@implementation IGRDownloadManager

+ (instancetype)defaultInstance
{
	static IGRDownloadManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	
	return sharedInstance;
}

- (instancetype)init
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

- (void)startDownloadTrack:(IGREntityExTrack *)aTrack withProgress:(UIProgressView *)aProgress
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
																		  progress:nil
																	   destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
	{
		NSURL *destURL = [IGRAppDelegate videoFolder];
		destURL = [destURL URLByAppendingPathComponent:response.suggestedFilename];
		
		return destURL;
	}
																 completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
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
		
	}];
	
	downloadObject = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   downloadTask, kIGRKeyTask,
										   aTrack.webPath, kIGRKeyWebUrl,
										   aProgress, kIGRKeyProgress, nil];
	
	[self.downloads addObject:downloadObject];
	[aProgress setProgressWithDownloadProgressOfTask:downloadTask animated:NO
	 ];
	
	[downloadTask resume];
}

- (void)updateProgress:(UIProgressView *)aProgress forTrack:(IGREntityExTrack *)aTrack
{
	NSMutableDictionary *downloadObject = [self downloadObjectForTrack:aTrack];
	
	if (downloadObject != nil)
	{
		UIProgressView *oldProgress = downloadObject[kIGRKeyProgress];
		
		if (oldProgress != aProgress)
		{
			NSURLSessionDownloadTask *downloadTask = downloadObject[kIGRKeyTask];
			[aProgress setProgressWithDownloadProgressOfTask:downloadTask animated:NO];
		}
	}
}

- (void)removeAllProgresses
{
	for (NSMutableDictionary *downloadObject in self.downloads)
	{
		NSURLSessionDownloadTask *downloadTask = downloadObject[kIGRKeyTask];
		UIProgressView *oldProgress = downloadObject[kIGRKeyProgress];
		
		if (![oldProgress isEqual:[NSNull null]])
		{
			@try {
				[downloadTask removeObserver:oldProgress forKeyPath:@"state"];
				[downloadTask removeObserver:oldProgress forKeyPath:@"countOfBytesReceived"];
			}
			@catch (NSException * __unused exception) {}

		}
		
		downloadObject[kIGRKeyProgress] = [NSNull null];
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
