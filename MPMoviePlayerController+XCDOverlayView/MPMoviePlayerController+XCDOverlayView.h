//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMoviePlayerController (XCDOverlayView)

/**
 *  The `overlayView` will be automatically synchronized with the movie player playback controls.
 *  It will appear and disappear at the same time and will be resized to always fit between the top and bottom playback control views.
 */
@property (nonatomic, strong) UIView *overlayView_xcd;

@end
