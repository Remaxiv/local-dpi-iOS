#import <UIKit/UIKit.h>

@interface RMStartStopButton : UIButton
{
	UIView *buttonSubview;
	NSLayoutConstraint *zeroWidthConstraint;
	NSLayoutConstraint *zeroHeightConstraint;
	NSLayoutConstraint *widthConstraint;
	NSLayoutConstraint *heightConstraint;
	CAShapeLayer *powerSymbol;
	UIBezierPath *powerSymbolPath;
	BOOL isActive;
}

- (void)setActivated:(BOOL)active;
@end

