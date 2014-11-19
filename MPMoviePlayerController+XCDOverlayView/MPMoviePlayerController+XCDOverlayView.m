//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "MPMoviePlayerController+XCDOverlayView.h"

#import <objc/runtime.h>

static const NSString * VideoPlaybackOverlayViewKey = @"VideoPlaybackOverlayView"; // isa MPVideoPlaybackOverlayView
static const NSString * TopPlaybackControlViewKey = @"TopPlaybackControlView"; // isa _UIBackdropView
static const NSString * BottomPlaybackControlViewKey = @"BottomPlaybackControlView"; // isa _UIBackdropView
static NSMapTable * VideoPlaybackOverlayViews(UIView *view);

static void *PlaybackControlViewContext = &PlaybackControlViewContext;

static void *OverlayMiddleViewKey = &OverlayMiddleViewKey;
static void *MPMoviePlayerControllerKey = &MPMoviePlayerControllerKey;

@interface XCDMoviePlayerControllerPlaybackControlViewObserver : NSObject
+ (instancetype) sharedObserver;
@end

@implementation XCDMoviePlayerControllerPlaybackControlViewObserver

+ (instancetype) sharedObserver
{
	static dispatch_once_t once;
	static XCDMoviePlayerControllerPlaybackControlViewObserver *sharedObserver;
	dispatch_once(&once, ^{
		sharedObserver = [self new];
	});
	return sharedObserver;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(UIView *)playbackControlView change:(NSDictionary *)change context:(void *)context
{
	if (context == PlaybackControlViewContext)
	{
		UIView *videoPlaybackOverlayView = playbackControlView.superview;
		NSMapTable *videoPlaybackOverlayViews = VideoPlaybackOverlayViews(videoPlaybackOverlayView);
		UIView *topPlaybackControlView = [videoPlaybackOverlayViews objectForKey:TopPlaybackControlViewKey];
		UIView *bottomPlaybackControlView = [videoPlaybackOverlayViews objectForKey:BottomPlaybackControlViewKey];
		UIView *overlayMiddleView = objc_getAssociatedObject(videoPlaybackOverlayView, OverlayMiddleViewKey);
		
		const CGFloat height = CGRectGetHeight(videoPlaybackOverlayView.bounds) - (CGRectGetHeight(topPlaybackControlView.bounds) + CGRectGetHeight(bottomPlaybackControlView.bounds));
		overlayMiddleView.frame = CGRectMake(CGRectGetMinX(videoPlaybackOverlayView.bounds), CGRectGetMaxY(topPlaybackControlView.bounds), CGRectGetWidth(videoPlaybackOverlayView.bounds), height);
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:playbackControlView change:change context:context];
	}
}

@end


@interface XCDOverlayMiddleView : UIView
@end

@implementation XCDOverlayMiddleView

- (void) willMoveToSuperview:(UIView *)superview
{
	NSMapTable *videoPlaybackOverlayViews = VideoPlaybackOverlayViews(superview ?: self.superview);
	UIView *topPlaybackControlView = [videoPlaybackOverlayViews objectForKey:TopPlaybackControlViewKey];
	UIView *bottomPlaybackControlView = [videoPlaybackOverlayViews objectForKey:BottomPlaybackControlViewKey];
	
	id observer = [XCDMoviePlayerControllerPlaybackControlViewObserver sharedObserver];
	// iOS 8 requires observing `bounds` and iOS 7 requires observing `frame`
	for (NSString *keyPath in @[ @"bounds", @"frame" ])
	{
		for (UIView *playbackControlView in @[ topPlaybackControlView, bottomPlaybackControlView ])
		{
			if (superview)
				[playbackControlView addObserver:observer forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:PlaybackControlViewContext];
			else
				[playbackControlView removeObserver:observer forKeyPath:keyPath context:PlaybackControlViewContext];
		}
	}
}

@end


@implementation MPMoviePlayerController (XCDOverlayView)

static NSArray * PlaybackControlViews(UIView *view)
{
	NSArray *subviews = view.subviews;
	if (subviews.count == 2)
	{
		// Order of subviews is different on iOS 7 and 8
		UIView *viewA = subviews[0];
		UIView *viewB = subviews[1];
		CGFloat minA = CGRectGetMinY(viewA.frame);
		CGFloat minB = CGRectGetMinY(viewB.frame);
		if (minA == minB)
			return nil;
		
		BOOL firstIsTop = minA < minB;
		UIView *topView = firstIsTop ? viewA : viewB;
		UIView *bottomView = firstIsTop ? viewB : viewA;
		
		if (CGRectGetMinY(bottomView.frame) > CGRectGetMaxY(topView.frame))
			return @[ topView, bottomView ];
	}
	return nil;
}

static BOOL PointInside(UIView *videoPlaybackOverlayView, CGPoint point, UIEvent *event, UIView *view)
{
	MPMoviePlayerController *moviePlayerController = objc_getAssociatedObject(videoPlaybackOverlayView, MPMoviePlayerControllerKey);
	BOOL shouldHandleTouch;
	if (moviePlayerController.interactiveOverlayViews_xcd)
		shouldHandleTouch = [moviePlayerController.interactiveOverlayViews_xcd containsObject:view];
	else
		shouldHandleTouch = [view isKindOfClass:[UIControl class]];
	
	if (shouldHandleTouch)
	{
		return [view pointInside:[videoPlaybackOverlayView convertPoint:point toView:view] withEvent:event];
	}
	else
	{
		BOOL pointInside = NO;
		for (UIView *subview in view.subviews)
			pointInside = pointInside || PointInside(videoPlaybackOverlayView, point, event, subview);
		return pointInside;
	}
}

static BOOL (*pointInsideWithEventIMP)(UIView *, SEL, CGPoint, UIEvent *); // original implementation of -[MPVideoPlaybackOverlayView pointInside:withEvent:]
static BOOL PlaybackOverlayViewPointInsideWithEvent(UIView *self, SEL _cmd, CGPoint point, UIEvent *event)
{
	// The MPVideoPlaybackOverlayView class is a liar. It overrides the `pointInside:withEvent:`
	// method and returns YES only when the point is inside the top or bottom playback view.
	// In order to support touches in the overlay, we must therefore extend this method with our own check.
	BOOL originalPointInside = pointInsideWithEventIMP(self, _cmd, point, event);
	UIView *overlayMiddleView = objc_getAssociatedObject(self, OverlayMiddleViewKey);
	BOOL pointInside = overlayMiddleView && PointInside(self, point, event, overlayMiddleView);
	return originalPointInside || pointInside;
}

static NSMapTable * VideoPlaybackOverlayViews(UIView *view)
{
	static void *VideoPlaybackOverlayViewsKey = &VideoPlaybackOverlayViewsKey;
	
	NSMapTable *overlayViews = objc_getAssociatedObject(view, VideoPlaybackOverlayViewsKey);
	if (overlayViews)
		return overlayViews;
	
	NSArray *playbackControlViews = PlaybackControlViews(view);
	if (playbackControlViews)
	{
		static dispatch_once_t once;
		dispatch_once(&once, ^{
			Method pointInsideWithEvent = class_getInstanceMethod([view class], @selector(pointInside:withEvent:));
			pointInsideWithEventIMP = (__typeof(pointInsideWithEventIMP))method_getImplementation(pointInsideWithEvent);
			method_setImplementation(pointInsideWithEvent, (IMP)PlaybackOverlayViewPointInsideWithEvent);
		});
		overlayViews = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:3];
		[overlayViews setObject:view forKey:VideoPlaybackOverlayViewKey];
		[overlayViews setObject:playbackControlViews[0] forKey:TopPlaybackControlViewKey];
		[overlayViews setObject:playbackControlViews[1] forKey:BottomPlaybackControlViewKey];
	}
	else
	{
		for (UIView *subview in view.subviews)
		{
			overlayViews = VideoPlaybackOverlayViews(subview);
			if (overlayViews)
				break;
		}
	}
	
	objc_setAssociatedObject(view, VideoPlaybackOverlayViewsKey, overlayViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return overlayViews;
}

static void *OverlayViewKey = &OverlayViewKey;

- (UIView *) overlayView_xcd
{
	return objc_getAssociatedObject(self, OverlayViewKey);
}

- (void) setOverlayView_xcd:(UIView *)overlayView
{
	[self.overlayView_xcd removeFromSuperview];
	objc_setAssociatedObject(self, OverlayViewKey, overlayView, OBJC_ASSOCIATION_ASSIGN);
	
	UIView *overlayMiddleView = objc_getAssociatedObject(self, OverlayMiddleViewKey) ?: [XCDOverlayMiddleView new];
	// `overlayMiddleView` must be stored in order to create only one (in case `setOverlayView_xcd:` is called more than once)
	// `OBJC_ASSOCIATION_ASSIGN` is used since `overlayMiddleView` is already retained by the `insertOverlayMiddleView` block
	objc_setAssociatedObject(self, OverlayMiddleViewKey, overlayMiddleView, OBJC_ASSOCIATION_ASSIGN);
	overlayView.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(overlayMiddleView.bounds), CGRectGetHeight(overlayMiddleView.bounds));
	overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[overlayMiddleView addSubview:overlayView];
	
	// Recursive block from http://stackoverflow.com/questions/19884403/recursive-block-and-retain-cycles-in-arc/19905407#19905407
	__block __weak void (^weakInsertOverlayMiddleView)(void);
	void (^insertOverlayMiddleView)(void);
	__weak __typeof(self) weakSelf = self;
	weakInsertOverlayMiddleView = insertOverlayMiddleView = ^void(void)
	{
		__strong __typeof(self) strongSelf = weakSelf;
		if (!strongSelf)
			return;
		
		// Waiting for the view to be in the hierarchy ensures that its subviews are properly positioned and sized
		// Consequently, `VideoPlaybackOverlayViews` will return a non-nil result
		if (strongSelf.view.superview)
		{
			if (overlayMiddleView.superview)
				return;
			
			NSMapTable *videoPlaybackOverlayViews = VideoPlaybackOverlayViews(strongSelf.view);
			if (!videoPlaybackOverlayViews)
			{
				if (strongSelf.controlStyle == MPMovieControlStyleFullscreen)
				{
					NSLog(@"MPMoviePlayerController+XCDOverlayView is not supported on iOS %@", [[UIDevice currentDevice] systemVersion]);
				}
				return;
			}
			
			UIView *videoPlaybackOverlayView = [videoPlaybackOverlayViews objectForKey:VideoPlaybackOverlayViewKey];
			// `overlayMiddleView` must also be associated to `videoPlaybackOverlayView` in order to easily retrieve it later (in XCDMoviePlayerControllerPlaybackControlViewObserver)
			objc_setAssociatedObject(videoPlaybackOverlayView, OverlayMiddleViewKey, overlayMiddleView, OBJC_ASSOCIATION_ASSIGN);
			// The movie player controller needs to be accessed inside the `PointInside` implementation
			objc_setAssociatedObject(videoPlaybackOverlayView, MPMoviePlayerControllerKey, self, OBJC_ASSOCIATION_ASSIGN);
			[videoPlaybackOverlayView addSubview:overlayMiddleView];
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), weakInsertOverlayMiddleView);
		}
	};
	
	insertOverlayMiddleView();
}

static void *InteractiveOverlayViewsKey = &InteractiveOverlayViewsKey;

- (NSSet *) interactiveOverlayViews_xcd
{
	return objc_getAssociatedObject(self, InteractiveOverlayViewsKey);
}

- (void) setInteractiveOverlayViews_xcd:(NSSet *)interactiveOverlayViews_xcd
{
	objc_setAssociatedObject(self, InteractiveOverlayViewsKey, interactiveOverlayViews_xcd, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
