//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "DemoViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MPMoviePlayerController+XCDOverlayView/MPMoviePlayerController+XCDOverlayView.h>

#import "OverlayView.h"

@implementation DemoViewController

- (NSString *) moviePath
{
	NSURL *bundledMovieURL = [[[NSBundle mainBundle] URLsForResourcesWithExtension:@"m4v" subdirectory:nil] firstObject];
	NSString *moviePath = NSProcessInfo.processInfo.environment[@"MOVIE_PATH"];
	if (moviePath && [[NSFileManager defaultManager] fileExistsAtPath:moviePath isDirectory:NULL])
		return moviePath;
	else
		return bundledMovieURL.path ?: moviePath;
}

- (BOOL) isValidMoviePath
{
	NSString *moviePath = self.moviePath;
	return moviePath && [[NSFileManager defaultManager] fileExistsAtPath:moviePath isDirectory:NULL];
}

- (NSURL *) movieURL
{
	if (self.localMovieSwitch.on)
		return [NSURL fileURLWithPath:self.moviePath];
	else
		return [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.localMovieSwitch.on = self.isValidMoviePath;
}

#pragma mark - Actions

- (IBAction) playMovie:(id)sender
{
	NSURL *movieURL = [self movieURL];
	MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
	moviePlayerViewController.moviePlayer.initialPlaybackTime = 4 * 60;
	[moviePlayerViewController.moviePlayer performSelector:@selector(pause) withObject:nil afterDelay:0];
	[self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
	
	__weak MPMoviePlayerViewController *weakMoviePlayerViewController = moviePlayerViewController;
	[self getMovieInfoWithURL:(NSURL *)movieURL completionHandler:^(NSDictionary *movieInfo)
	{
		NSString *title = movieInfo[AVMetadataCommonKeyTitle] ?: @"Title: N/A";
		NSString *copyright = movieInfo[AVMetadataCommonKeyCopyrights] ?: @"Copyright: N/A";
		OverlayView *overlayView = [OverlayView overlayViewWithTitle:title copyright:copyright];
		weakMoviePlayerViewController.moviePlayer.overlayView_xcd = overlayView;
	}];
}

- (IBAction) useLocalMovie:(id)sender
{
	BOOL displayExplanationLabel = self.localMovieSwitch.on && !self.isValidMoviePath;
	self.explanationLabel.hidden = !displayExplanationLabel;
}

#pragma mark - Movie Metadata

static NSDictionary * MovieInfo(AVAsset *asset)
{
	NSMutableDictionary *movieInfo = [NSMutableDictionary new];
	for (NSString *key in @[ AVMetadataCommonKeyTitle, AVMetadataCommonKeyCopyrights ])
	{
		AVMetadataItem *item = [[AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:key keySpace:AVMetadataKeySpaceCommon] firstObject];
		id<NSObject, NSCopying> value = item.value;
		if (value)
			movieInfo[key] = [value description];
	}
	return movieInfo;
}

- (void) getMovieInfoWithURL:(NSURL *)movieURL completionHandler:(void (^)(NSDictionary *movieInfo))completionHandler
{
	AVAsset *asset = [AVAsset assetWithURL:movieURL];
	if ([movieURL isFileURL])
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
