//
//  MyImageView.m
//  PhotoBoothPad
//
//  Created by  Nico Prananta on 8/6/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import "MyImageView.h"
#import "Circle.h"
#import <QuartzCore/QuartzCore.h>

@interface MyImageView()
- (void) startCountDown;
- (void) showNumber;
@end

@implementation MyImageView

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame]) {
		_countDown = 0;
		//
	}
	return self;
}

- (BOOL)canBecomeFirstResponder{
	return YES;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	NSLog(@"Touch");
	UITouch *touch = [touches anyObject];
	CGPoint loc = [touch locationInView:self];
	if (self.delegate && [self.delegate respondsToSelector:@selector(touchEnded)]) {
		Circle *circ = [[Circle alloc] initWithFrame:CGRectMake(loc.x, loc.y, 10, 10)];
		[circ setCenter:loc];
		[circ setBackgroundColor:[UIColor clearColor]];
		[self addSubview:circ];
		float lastSize = 200.0;
		[UIView beginAnimations:@"circle" context:nil];
		[circ setFrame: CGRectMake(loc.x-lastSize/2, loc.y-lastSize/2, lastSize, lastSize)];
		[circ.layer setOpacity:0];
		[UIView setAnimationDuration:2.0];
		[UIView setAnimationDelay:UIViewAnimationCurveEaseOut];
		[UIView commitAnimations];
		[circ release];
		
		UILabel *label = (UILabel *)[self viewWithTag:101];
		[label removeFromSuperview];
		
		UILabel *labelGetReady = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1024, 400)];
		[labelGetReady setCenter:CGPointMake(384, 512)];
		[labelGetReady setMinimumFontSize:1];
		[labelGetReady setAdjustsFontSizeToFitWidth:YES];
		[labelGetReady setText:@"Get Ready"];
		[labelGetReady setTag:102];
		[labelGetReady.layer setTransform:CATransform3DMakeRotation(M_PI*1.5, 0, 0, 1)];
		[labelGetReady setTextAlignment:UITextAlignmentCenter];
		[labelGetReady setTextColor:[UIColor whiteColor]];
		[labelGetReady setBackgroundColor:[UIColor clearColor]];
		[labelGetReady setFont:[UIFont systemFontOfSize:100]];
		
		[self addSubview:labelGetReady];		
		[labelGetReady release];
		[self performSelector:@selector(startCountDown) withObject:nil afterDelay:3.0];
		
	}
}

- (void)dealloc{
	[super dealloc];
}

#pragma mark --
#pragma mark CountDown Animation

- (void) startCountDown {
	UILabel *getReady = (UILabel *)[self viewWithTag:102];
	[getReady removeFromSuperview];
	_countDown = 3;
	[self showNumber];
}

- (void) showNumber{
	if (_countDown != 0) {
		UILabel *numberLabel = (UILabel *)[self viewWithTag:105];
		if (!numberLabel) {
			numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1024, 400)];
			[numberLabel setCenter:CGPointMake(384, 512)];
			[numberLabel setTag:105];
			[numberLabel setTextAlignment:UITextAlignmentCenter];
			[numberLabel setTextColor:[UIColor whiteColor]];
			[numberLabel setBackgroundColor:[UIColor clearColor]];
			[numberLabel setFont:[UIFont systemFontOfSize:200]];
			[numberLabel setMinimumFontSize:1];
			[numberLabel setAdjustsFontSizeToFitWidth:YES];
			[numberLabel setText:[NSString stringWithFormat:@"%d", _countDown]];
			[numberLabel.layer setTransform:CATransform3DMakeRotation(M_PI*1.5, 0, 0, 1)];
			[self addSubview:numberLabel];
			[numberLabel release];
		} else {
			[numberLabel setText:[NSString stringWithFormat:@"%d", _countDown]];
			[self addSubview:numberLabel];
		}
		/*if (_countDown == 1) {
			[self.delegate touchEnded];
		}*/
		_countDown--;
		[self performSelector:@selector(showNumber) withObject:nil afterDelay:1.0];
	} else {
		_countDown = 3;
		UILabel *numberLabel = (UILabel *)[self viewWithTag:105];
		[numberLabel removeFromSuperview];
		UIView *flashView = [[UIView alloc] initWithFrame:[self frame]];
		[flashView setTag:110];
		[flashView setBackgroundColor:[UIColor whiteColor]];
		[flashView setAlpha:0.f];
		[self addSubview:flashView];
		
		[UIView beginAnimations:@"flash" context:nil];
		[UIView setAnimationDuration:.4f];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationStopped)];
		[flashView setAlpha:1.f];
		[flashView setAlpha:0.f];
		[UIView commitAnimations];
	}
}

- (void) animationStopped{
	UIView *flashView = [self viewWithTag:110];
	[flashView removeFromSuperview];
	[flashView release];
	[self.delegate touchEnded];
}

@end
