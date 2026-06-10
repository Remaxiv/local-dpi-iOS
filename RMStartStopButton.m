#import "RMStartStopButton.h"
#import "UIBezierPath+power.h"

@implementation RMStartStopButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit {
	self->isActive = false;
	self.backgroundColor = [UIColor systemGrayColor];

	self->buttonSubview = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
	buttonSubview.userInteractionEnabled = NO;
	buttonSubview.translatesAutoresizingMaskIntoConstraints = NO;
	buttonSubview.backgroundColor = [UIColor systemBlueColor];
	[self addSubview:buttonSubview];

	self->powerSymbolPath = [UIBezierPath symbolPower];
	self->powerSymbol = [[CAShapeLayer alloc] init];
	self->powerSymbol.strokeColor = nil;
	self->powerSymbol.fillColor = [UIColor whiteColor].CGColor;
	self->powerSymbol.bounds = self->powerSymbolPath.bounds;
	self->powerSymbol.path = self->powerSymbolPath.CGPath;
	[self.layer addSublayer:self->powerSymbol];

	self->widthConstraint = [buttonSubview.widthAnchor constraintEqualToAnchor:self.widthAnchor];
	self->heightConstraint = [buttonSubview.heightAnchor constraintEqualToAnchor:self.heightAnchor];
	self->zeroWidthConstraint = [buttonSubview.widthAnchor constraintEqualToConstant:0];
	self->zeroHeightConstraint = [buttonSubview.heightAnchor constraintEqualToConstant:0];
	[NSLayoutConstraint activateConstraints:@[
		[self.widthAnchor constraintEqualToAnchor:self.heightAnchor],

		[buttonSubview.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
		[buttonSubview.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
		zeroWidthConstraint,
		zeroHeightConstraint,
	]];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.layer.cornerRadius = self.bounds.size.width / 2;
	self->buttonSubview.layer.cornerRadius = self->buttonSubview.bounds.size.width / 2;
	CGRect pathBounds = self->powerSymbolPath.bounds;
	CGFloat currentWidth = pathBounds.size.width;
	CGFloat currentHeight = pathBounds.size.height;
	CGFloat currentSize = (currentWidth + currentHeight) / 2;
	CGFloat desiredWidth = self.bounds.size.width / 2;
	CGFloat desiredHeight = self.bounds.size.height / 2;
	CGFloat desiredSize = (desiredWidth + desiredHeight) / 2;
	CGAffineTransform pathTransform = CGAffineTransformMakeScale((desiredSize / currentSize), (desiredSize / currentSize));
	[self->powerSymbolPath applyTransform:pathTransform];
	self->powerSymbol.path = self->powerSymbolPath.CGPath;
	self->powerSymbol.bounds = self->powerSymbolPath.bounds;
	self->powerSymbol.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));

}

- (void)setActivated:(BOOL)active {
	if (active == self->isActive)
	{
		return;
	}
	self->isActive = active;

	[self layoutIfNeeded];
	[UIView animateWithDuration:0.5 animations:^{
		self->zeroWidthConstraint.active = !active;
		self->zeroHeightConstraint.active = !active;
		self->widthConstraint.active = active;
		self->heightConstraint.active = active;
		[self layoutIfNeeded];
	}];
}
@end


