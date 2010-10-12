//
//  Circle.m
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/9/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import "Circle.h"


@implementation Circle


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetLineWidth(context, 20.0);
	
	CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
	
	CGContextAddEllipseInRect(context, rect);
	
	CGContextStrokePath(context);

}


- (void)dealloc {
    [super dealloc];
}


@end
