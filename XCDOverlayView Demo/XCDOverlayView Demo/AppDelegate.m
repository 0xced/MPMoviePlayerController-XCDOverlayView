//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "AppDelegate.h"

#import <MPMoviePlayerController+XCDOverlayView/MPMoviePlayerController+XCDOverlayView.h>

@implementation AppDelegate

@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(overlayViewVisibilityDidChange:) name:XCDOverlayViewDidShowNotification object:nil];
	[defaultCenter addObserver:self selector:@selector(overlayViewVisibilityDidChange:) name:XCDOverlayViewDidHideNotification object:nil];
	
	return YES;
}

- (void) overlayViewVisibilityDidChange:(NSNotification *)notification
{
	NSLog(@"%@ %@", notification.name, notification.object);
}

@end
