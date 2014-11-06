//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "MovieController.h"

#import <AVFoundation/AVFoundation.h>

@interface MovieController ()
@property (readonly) NSURL *localMovieURL;
@property (readonly) NSURL *remoteMovieURL;
@property (strong) NSURLSessionDownloadTask *downloadTask;
@end

@implementation MovieController

- (instancetype) initWithMovieURL:(NSURL *)movieURL
{
	if (!(self = [super init]))
		return nil;
	
	_remoteMovieURL = movieURL;
	
	return self;
}

- (NSURLSessionDownloadTask *) startDownload
{
	NSData *resumeData = [[NSUserDefaults standardUserDefaults] objectForKey:@"MovieResumeData"];
	void (^completionHandler)(NSURL *, NSURLResponse *, NSError *) = ^void(NSURL *location, NSURLResponse *response, NSError *error) {
		if (!location)
		{
			NSLog(@"Download error: %@", error);
			return;
		}
		
		NSError *moveError;
		BOOL moved = [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.localMovieURL error:&moveError];
		if (!moved)
			NSLog(@"Move error: %@", moveError);
	};
	
	NSURLSession *session = [NSURLSession sharedSession];
	if (resumeData)
		self.downloadTask = [session downloadTaskWithResumeData:resumeData completionHandler:completionHandler];
	else
		self.downloadTask = [session downloadTaskWithURL:self.remoteMovieURL completionHandler:completionHandler];
	
	[self.downloadTask resume];
	return self.downloadTask;
}

- (void) cancelDownload
{
	[self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
		[[NSUserDefaults standardUserDefaults] setObject:resumeData forKey:@"MovieResumeData"];
	}];
}

- (BOOL) hasLocalMovie
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.localMovieURL.path];
}

- (NSURL *) localMovieURL
{
	NSURL *cacheDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
	return [cacheDirectoryURL URLByAppendingPathComponent:self.remoteMovieURL.lastPathComponent];
}

- (NSURL *) movieURL
{
	return [self hasLocalMovie] ? self.localMovieURL : self.remoteMovieURL;
}

static NSDictionary * MovieInfo(AVAsset *asset)
{
	NSMutableDictionary *movieInfo = [NSMutableDictionary new];
	for (NSString *key in @[ AVMetadataCommonKeyTitle, AVMetadataCommonKeyCopyrights ])
	{
		AVMetadataItem *item = [[AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:key keySpace:AVMetadataKeySpaceCommon] firstObject];
		id<NSObject, NSCopying> value = item.value;
		if (value)
			movieInfo[key] = value;
	}
	return movieInfo;
}

- (void) getMovieInfo:(void (^)(NSDictionary *movieInfo))completionHandler
{
	AVAsset *asset = [AVAsset assetWithURL:self.movieURL];
	
	if ([self hasLocalMovie])
	{
		completionHandler(MovieInfo(asset));
	}
	else
	{
		[asset loadValuesAsynchronouslyForKeys:@[ NSStringFromSelector(@selector(commonMetadata)) ] completionHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(MovieInfo(asset));
			});
		}];
	}
}

@end
