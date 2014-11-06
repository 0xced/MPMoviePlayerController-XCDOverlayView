//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "DemoViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "MovieController.h"

@interface DemoViewController ()
@property (readonly) MovieController *movieController;
@property (strong) NSURLSessionDownloadTask *downloadTask;
@end

@implementation DemoViewController

static void *CountOfBytesReceivedContext = &CountOfBytesReceivedContext;

- (instancetype) initWithCoder:(NSCoder *)decoder
{
	if (!(self = [super initWithCoder:decoder]))
		return nil;
	
	NSURL *movieURL = [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"];
	_movieController = [[MovieController alloc] initWithMovieURL:movieURL];
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	BOOL hasLocalMovie = [self.movieController hasLocalMovie];
	self.progressView.progress = hasLocalMovie ? 1.f : 0.f;
	self.downloadButton.enabled = !hasLocalMovie;
}

#pragma mark - Video Playing

- (IBAction) playVideo:(id)sender
{
	MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:self.movieController.movieURL];
	[self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
	
	[self.movieController getMovieInfo:^(NSDictionary *movieInfo)
	{
		NSLog(@"%@", movieInfo);
	}];
}

#pragma mark - Video Download

- (IBAction) downloadVideo:(id)sender
{
	[sender removeTarget:self action:_cmd forControlEvents:UIControlEventTouchUpInside];
	[sender addTarget:self action:@selector(cancelDownload:) forControlEvents:UIControlEventTouchUpInside];
	[sender setTitle:@"Cancel Download" forState:UIControlStateNormal];
	
	self.downloadTask = [self.movieController startDownload];
	[self.downloadTask addObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived)) options:0 context:CountOfBytesReceivedContext];
}

- (IBAction) cancelDownload:(id)sender
{
	[sender removeTarget:self action:_cmd forControlEvents:UIControlEventTouchUpInside];
	[sender addTarget:self action:@selector(downloadVideo:) forControlEvents:UIControlEventTouchUpInside];
	[sender setTitle:@"Download Video" forState:UIControlStateNormal];
	
	[self.movieController cancelDownload];
	[self.downloadTask removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived)) context:CountOfBytesReceivedContext];
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CountOfBytesReceivedContext)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			NSURLSessionDownloadTask *downloadTask = object;
			self.progressView.progress = (float)downloadTask.countOfBytesReceived / (float)downloadTask.countOfBytesExpectedToReceive;
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
