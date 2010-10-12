//
//  MyActivityIndicator.m
//  ScribeIt
//
//  Created by Nico Prananta on 4/14/10.
//  Copyright 2010 YumeCraft. All rights reserved.
//

#import "MyActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>


@implementation MyActivityIndicator

@synthesize activity;
@synthesize label;
@synthesize bgView;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		//self.activity.center = CGPointMake(50, 45);
		//self.activity.hidesWhenStopped = NO;
		
		self.label = [[UILabel alloc] init];
		self.label.text = @"Loading";
		self.label.textColor = [UIColor whiteColor];
		[self.label sizeToFit];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.center = CGPointMake(50, 75);
		
		self.bgView = [[UIView alloc] 
					   initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		self.bgView.layer.cornerRadius = 10.0;
		self.bgView.backgroundColor = [UIColor blackColor];
		self.bgView.alpha = 0.5;
		
		//self.backgroundColor = [UIColor blackColor];
		
    }
    return self;
}

- (id) initWithText:(NSString *)textLabel{
	if (self = [super initWithFrame:CGRectMake(0, 0, 800, 400)]) {
		self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		
		self.label = [[UILabel alloc] init];
		self.label.font = [UIFont systemFontOfSize:50];
		self.label.text = textLabel;
		self.label.textColor = [UIColor whiteColor];
		[self.label sizeToFit];
		self.label.backgroundColor = [UIColor clearColor];
		
		self.bgView = [[UIView alloc] 
					   initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		self.bgView.layer.cornerRadius = 10.0;
		self.bgView.backgroundColor = [UIColor blackColor];
		self.bgView.alpha = 0.5;
	}
	return self;
}

- (void)startAnimation{
	//CGFloat width = self.label.frame.size.width + 20;
	self.frame = CGRectMake(0, 0, 800, 400);
	self.activity.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 - self.activity.frame.size.height/2);
	self.label.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + self.label.frame.size.height/2 + 12.5);
	self.bgView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	[self addSubview:bgView];
	[self addSubview:self.activity];
	[self addSubview:self.label];
	[self.activity startAnimating];
}

- (void)stopAnimation{
	[self.activity stopAnimating];
}

/*
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
 */


- (void)dealloc {
	[bgView release];
	[activity release];
	[label release];
    [super dealloc];
}


@end
