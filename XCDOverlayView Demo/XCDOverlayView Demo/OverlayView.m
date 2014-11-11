//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import "OverlayView.h"

@interface OverlayView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *copyrightButton;

@end

@implementation OverlayView

+ (instancetype) overlayViewWithTitle:(NSString *)title copyright:(NSString *)copyright;
{
	OverlayView *overlayView = [[[UINib nibWithNibName:@"OverlayView" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
	overlayView.titleLabel.text = title;
	[overlayView.copyrightButton setTitle:copyright forState:UIControlStateNormal];
	return overlayView;
}

- (void) willMoveToSuperview:(UIView *)superview
{
	self.alpha = 0.f;
	[UIView animateWithDuration:0.3f animations:^{
		self.alpha = 1.f;
	}];
}

- (NSURL *) copyrightURL
{
	NSDataDetector *linkDataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	NSString *copyright = [self.copyrightButton titleForState:UIControlStateNormal];
	NSTextCheckingResult *result = [linkDataDetector firstMatchInString:copyright options:(NSMatchingOptions)0 range:NSMakeRange(0, copyright.length)];
	return result.URL;
}

- (IBAction) copyright:(id)sender
{
	NSURL *copyrightURL = self.copyrightURL;
	NSString *message = copyrightURL ? [NSString stringWithFormat:@"Do you want to open %@ in Safari?", copyrightURL] : @"No URL was found in the copyright.";
	NSString *cancelButtonTitle = copyrightURL ? @"Cancel" : @"OK";
	NSString *otherButtonTitle = copyrightURL ? @"Open URL" : nil;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];
	[alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex)
		return;
	
	[[UIApplication sharedApplication] openURL:self.copyrightURL];
}

@end
