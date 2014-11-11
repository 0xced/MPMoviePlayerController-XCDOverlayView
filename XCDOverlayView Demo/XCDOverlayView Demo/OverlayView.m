//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "OverlayView.h"

@interface OverlayView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *copyrightLabel;

@end

@implementation OverlayView

+ (instancetype) overlayViewWithTitle:(NSString *)title copyright:(NSString *)copyright;
{
	OverlayView *overlayView = [[[UINib nibWithNibName:@"OverlayView" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
	overlayView.titleLabel.text = title;
	overlayView.copyrightLabel.text = copyright;
	return overlayView;
}

- (void) willMoveToSuperview:(UIView *)superview
{
	self.alpha = 0.f;
	[UIView animateWithDuration:0.3f animations:^{
		self.alpha = 1.f;
	}];
}

@end
