//
//  MyActivityIndicator.h
//  ScribeIt
//
//  Created by Nico Prananta on 4/14/10.
//  Copyright 2010 YumeCraft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MyActivityIndicator : UIView {
	UIActivityIndicatorView *activity;
	UILabel *label;
	UIView *bgView;
}

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIView *bgView;

- (void)startAnimation;
- (void)stopAnimation;
- (id)initWithText:(NSString *)textLabel;

@end
